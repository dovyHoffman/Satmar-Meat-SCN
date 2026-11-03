// Scanovator -> Satmar sync. Runs on Supabase (Edge Function). The Scanovator key lives ONLY here,
// as a secret. Never put it in the web page.
//
// Each run:
//  (The website calls this in small steps so each call stays within Supabase's limits:
//   mode "orders" with an offset = 100 customers at a time, then mode "photos" = a few pictures at a time.)
//  1. asks Scanovator "orders/search" for the phone numbers of the active customers (100 per request),
//     newest orders first, and stops reading a group as soon as the orders are older than 4 weeks,
//  2. matches each order to a customer and saves driver / delivered time / receipt / photo links,
//  3. copies photos that are not yet in our private storage (a limited number per run, so it never
//     runs out of time; the next run continues where this one stopped).
//
// Secrets (Supabase > Edge Functions > Secrets):
//   SCANOVATOR_TOKEN, SCANOVATOR_STORE_ID, SCANOVATOR_STORE_CODE, SYNC_SECRET (any long random text, for scheduled runs)
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by Supabase automatically.
//
// Who may call it: the signed-in OWNER (Sync now button) or a scheduler sending  x-sync-secret: <SYNC_SECRET>.
// Deploy with "Verify JWT" turned OFF (the function checks the owner itself).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const API = "https://api.scanovator.com/v2/orders/search";
const DAYS_BACK = 28;
const CHUNK = 100;               // customers (phone numbers) per call
const PHOTOS_PER_CALL = 3;

const STORE_ID = Number(String(Deno.env.get("SCANOVATOR_STORE_ID") ?? "").trim());
const STORE_CODE = String(Deno.env.get("SCANOVATOR_STORE_CODE") ?? "").trim();
const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
const cors = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, content-type, x-sync-secret, apikey, x-client-info",
};
const digits = (v: unknown) => String(v ?? "").replace(/\D/g, "").slice(-10);
const wait = (ms: number) => new Promise((r) => setTimeout(r, ms));
const https = (u: string) => (/^https?:\/\//i.test(u) ? u : "https://" + u.replace(/^\/+/, ""));

// "2025-12-01 10:02:11" is New York wall-clock time (Scanovator). Convert to a real timestamp.
function nyIso(s: string): string | null {
  const m = String(s || "").match(/^(\d{4})-(\d\d)-(\d\d)[ T](\d\d):(\d\d):(\d\d)/);
  if (!m) return null;
  const asUtc = Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]);
  const part = new Intl.DateTimeFormat("en-US", { timeZone: "America/New_York", timeZoneName: "shortOffset" })
    .formatToParts(new Date(asUtc + 5 * 3600e3)).find((x) => x.type === "timeZoneName")?.value || "GMT-5";
  const o = Number((part.match(/GMT([+-]\d+)/) || [0, "-5"])[1]);
  const d = new Date(asUtc - o * 3600e3);
  return isNaN(+d) ? null : d.toISOString();
}
const label = (iso: string | null) => {
  if (!iso) return "";
  const p = new Intl.DateTimeFormat("en-US", { timeZone: "America/New_York", month: "numeric", day: "numeric" }).format(new Date(iso));
  return p; // e.g. "10/27"
};

async function who(req: Request): Promise<{ ok: boolean; owner: boolean; customers: boolean }> {
  const secret = Deno.env.get("SYNC_SECRET");
  if (secret && req.headers.get("x-sync-secret") === secret) return { ok: true, owner: true, customers: true };
  const jwt = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  if (!jwt) return { ok: false, owner: false, customers: false };
  const { data } = await sb.auth.getUser(jwt);
  if (!data?.user) return { ok: false, owner: false, customers: false };
  const { data: p } = await sb.from("profiles").select("role,active,pages").eq("id", data.user.id).single();
  if (!p || !p.active) return { ok: false, owner: false, customers: false };
  return { ok: true, owner: p.role === "owner", customers: p.role === "owner" || (p.pages || []).includes("customers") };
}

async function search(phones: string[], page: number) {
  let lastErr = "";
  for (let attempt = 0; attempt < 4; attempt++) {
    try {
      const r = await fetch(API, {
        method: "POST",
        headers: {
          Authorization: "Bearer " + Deno.env.get("SCANOVATOR_TOKEN"),
          "Content-Type": "application/json",
          Accept: "application/json",
          Connection: "close",
        },
        body: JSON.stringify({
          store_id: STORE_ID,
          store_code: STORE_CODE,
          phone: phones.map((p) => "+1" + p), page, limit: 200,
        }),
      });
      if (r.status === 429 || r.status >= 500) { lastErr = "Scanovator " + r.status; await wait(3000 * (attempt + 1)); continue; }
      const j = await r.json().catch(() => ({}));
      if (!r.ok) throw new Error(`Scanovator ${r.status}: ${j?.message || ""} ${JSON.stringify(j?.errors || {}).slice(0, 300)}`);
      return j;
    } catch (e) {
      const msg = String((e as Error).message || e);
      if (/^Scanovator 4\d\d/.test(msg)) throw e;   // a real refusal: do not retry
      lastErr = msg;                                  // network hiccup (e.g. connection reset): try again
      await wait(2000 * (attempt + 1));
    }
  }
  throw new Error("Could not reach Scanovator after 4 tries (" + lastErr.slice(0, 160) + "). Try again in a minute.");
}

let photoInfo = "";   // what Scanovator answered for the last picture (shown to the owner when copying fails)
async function savePhoto(orderId: string, idx: number, url: string, ms = 7000): Promise<string | null> {
  const full = https(url);
  for (const useToken of [true, false]) {
    const ctl = new AbortController();
    const timer = setTimeout(() => ctl.abort(), ms);
    try {
      const r = await fetch(full, { signal: ctl.signal, headers: useToken ? { Authorization: "Bearer " + Deno.env.get("SCANOVATOR_TOKEN") } : {} });
      const type = r.headers.get("content-type") || "";
      photoInfo = `${useToken ? "with key" : "without key"}: HTTP ${r.status} ${type.slice(0, 40)}`;
      if (!r.ok || !type.startsWith("image/")) { await r.body?.cancel(); continue; }
      const path = `${orderId}/${idx}.${type.includes("png") ? "png" : "jpg"}`;
      const { error } = await sb.storage.from("pods").upload(path, await r.arrayBuffer(), { contentType: type, upsert: true });
      if (!error) return path;
      photoInfo = "could not store the picture: " + error.message;
    } catch (e) {
      photoInfo = `${useToken ? "with key" : "without key"}: ` + (((e as Error).name === "AbortError") ? `no answer in ${Math.round(ms / 1000)} seconds` : String((e as Error).message || e).slice(0, 80));
    } finally { clearTimeout(timer); }
  }
  return null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const json = (o: unknown, s = 200) => new Response(JSON.stringify(o), { status: s, headers: { ...cors, "content-type": "application/json" } });
  try {
    const me = await who(req);
    if (!me.ok) return json({ error: "not allowed" }, 403);
    const body = await req.json().catch(() => ({}));

    // ---- mode "photo": copy ONE picture when somebody opens it (any signed-in person with the Customers page) ----
    if (body.mode === "photo") {
      if (!me.customers) return json({ ok: false, error: "not allowed" }, 403);
      const idx = Number(body.idx) || 0;
      const { data: d } = await sb.from("deliveries").select("order_id,photo_urls,photo_paths").eq("order_id", String(body.order_id || "")).maybeSingle();
      if (!d || !(d.photo_urls || [])[idx]) return json({ ok: false, error: "no such picture" }, 404);
      const paths: string[] = [...(d.photo_paths || [])];
      if (paths[idx] && paths[idx] !== "-") return json({ ok: true, path: paths[idx] });
      const p = await savePhoto(d.order_id, idx, d.photo_urls[idx], 25000);
      if (p) { paths[idx] = p; await sb.from("deliveries").update({ photo_paths: paths }).eq("order_id", d.order_id); }
      return json({ ok: true, path: p || "", info: p ? "" : photoInfo });
    }
    if (!me.owner) return json({ error: "not allowed" }, 403);
    for (const k of ["SCANOVATOR_TOKEN", "SCANOVATOR_STORE_ID", "SCANOVATOR_STORE_CODE"])
      if (!Deno.env.get(k)) return json({ ok: false, error: `Secret ${k} is not set in Supabase.` }, 500);
    if (!Number.isInteger(STORE_ID))
      return json({ ok: false, error: "SCANOVATOR_STORE_ID must be a whole number (digits only). Fix it in Supabase > Edge Functions > Secrets." }, 500);
    if (!STORE_CODE) return json({ ok: false, error: "SCANOVATOR_STORE_CODE is empty." }, 500);

    const mode = body.mode === "photos" ? "photos" : "orders";

    if (mode === "photos") {
      const { data: recent } = await sb.from("deliveries").select("order_id,photo_urls,photo_paths").order("synced_at", { ascending: false }).limit(400);
      const todo: any[] = (recent || []).filter((d: any) => (d.photo_urls || []).some((_: string, n: number) => !(d.photo_paths || [])[n]));
      let copied = 0, tried = 0;
      for (const d of todo) {
        if (tried >= PHOTOS_PER_CALL) break;
        const paths: string[] = [...(d.photo_paths || [])];
        for (let n = 0; n < d.photo_urls.length && tried < PHOTOS_PER_CALL; n++) {
          if (paths[n]) continue;
          tried++;
          const p = await savePhoto(d.order_id, n, d.photo_urls[n]);
          paths[n] = p || "-";            // "-" = could not copy (kept so we do not retry forever)
          if (p) copied++;
        }
        await sb.from("deliveries").update({ photo_paths: paths }).eq("order_id", d.order_id);
      }
      return json({ ok: true, mode, copied, tried, waiting: Math.max(0, todo.length - (tried ? 1 : 0)), info: copied ? "" : photoInfo });
    }

    // ---- mode "orders": one group of 100 customers ----
    const offset = Math.max(0, Number(body.offset) || 0);
    const cust: any[] = [];
    for (let f = 0; ; f += 1000) {
      const { data, error } = await sb.from("customers").select("id,agency_ref,phone,street,apt,name").eq("active", true).order("id").range(f, f + 999);
      if (error) throw error;
      cust.push(...data!);
      if (data!.length < 1000) break;
    }
    const idKey = (v: unknown) => String(v ?? "").toLowerCase().replace(/[^a-z0-9]/g, "");
    const byId = new Map<string, any>();
    const ambiguous = new Set<string>();
    // two customers with the same ID text (e.g. bare numbers in different agencies) are never guessed: they are skipped
    for (const c of cust) { const k = idKey(c.agency_ref); if (!k) continue; if (byId.has(k)) ambiguous.add(k); else byId.set(k, c); }
    for (const k of ambiguous) byId.delete(k);
    const byPhone = new Map<string, any[]>();
    for (const c of cust) {
      const k = digits(c.phone);
      if (/^[2-9]\d\d[2-9]\d{6}$/.test(k)) { if (!byPhone.has(k)) byPhone.set(k, []); byPhone.get(k)!.push(c); }
    }
    const phones = [...byPhone.keys()].sort();
    const chunk = phones.slice(offset, offset + CHUNK);
    const since = Date.now() - DAYS_BACK * 864e5;
    let seen = 0, saved = 0, viaId = 0, viaPhone = 0, noMatch = 0, viaName = 0;
    const loose = body.loose === true;   // owner ticked "also match by name + phone"
    const words = (t: unknown) => String(t ?? "").toLowerCase().split(/[^a-z\u0590-\u05ff]+/).filter(Boolean).sort().join(" ");
    const last10 = (v: unknown) => digits(v).slice(-10);
    // strict: the phone AND every word of the name must agree, and exactly ONE customer may fit
    const byNamePhone = (o: any): any => {
      const ow = words(`${o.fname || ""} ${o.lname || ""}`); if (!ow) return null;
      const hits = new Map<string, any>();
      for (const ph of [o.phone, o.cell1, o.cell2]) { const k = last10(ph); for (const c of byPhone.get(k) || []) if (words(c.name) === ow) hits.set(c.id, c); }
      return hits.size === 1 ? [...hits.values()][0] : null;
    };
    const examples: string[] = [];
    // diagnostics: where on an order does Scanovator keep our customer ID?
    const idPaths: Record<string, number> = {}; let samplePaths: string[] = []; let diagN = 0;
    const flat = (v: any, path: string, out: [string, string][], d = 0) => {
      if (v === null || v === undefined) return;
      if (typeof v === "object") { if (d >= 3) return; const ent = Array.isArray(v) ? v.slice(0, 3).map((x, i) => [String(i), x]) : Object.entries(v); for (const [k, x] of ent as any[]) flat(x, path ? path + "." + k : String(k), out, d + 1); return; }
      const t = String(v); if (t !== "") out.push([path, t]);
    };
    if (chunk.length) {
      for (let page = 1; page <= 6; page++) {
        const j = await search(chunk, page);
        const rows: any[] = [];
        let oldest = Infinity;
        const unmatched: string[] = [];
        for (const o of j.data || []) {
          seen++;
          const created = new Date(o.createdAtIso).getTime();
          if (created < oldest) oldest = created;
          if (created < since) continue;
          // match ONLY by the customer ID Scanovator keeps on the order (customer code). The phone is used just to find the orders.
          let c: any = null;
          for (const f of [o.customercode, o.online_order_id]) { const hit = byId.get(idKey(f)); if (hit && idKey(f)) { c = hit; viaId++; break; } }
                    if (!c && loose) { const h = byNamePhone(o); if (h) { c = h; viaName++; } }
          if (!c && diagN < 40) { diagN++; const fl: [string, string][] = []; flat(o, "", fl);
            const PII = /^(fname|lname|phone|cell1|cell2|address|street_address|unit|city|state|zip)$/;
            for (const [pa, va] of fl) {
              const k = idKey(va); if (k && byId.has(k)) idPaths[pa] = (idPaths[pa] || 0) + 1;
              for (const tk of va.match(/[A-Za-z]{1,4}[\s-]*\d{2,6}/g) || []) { const k2 = idKey(tk); if (k2 && byId.has(k2)) idPaths[pa + " (inside text)"] = (idPaths[pa + " (inside text)"] || 0) + 1; }
            }
            if (samplePaths.length < 60 && diagN <= 2) for (const [pa, va] of fl) samplePaths.push(PII.test(pa) ? pa + "=(hidden)" : pa + "=" + va.slice(0, 18)); }
          if (!c) { noMatch++; unmatched.push(String(o.order_id)); if (examples.length < 3) examples.push(String(o.customercode || o.online_order_id || "(none)").slice(0, 20)); continue; }  // only match by customer ID
          const delivered = nyIso(o.actually_delivered);
          rows.push({
            order_id: String(o.order_id), customer_id: c.id,
            week_label: label(delivered || o.createdAtIso),
            driver: String(o.driver_name || o.driver_string || ""),
            delivered_at: delivered, route_started: nyIso(o.route_started),
            receipt_url: o.receipt_url ? https(o.receipt_url) : "",
            photo_urls: (o.photos || []).map(String).filter(Boolean).map(https), synced_at: new Date().toISOString(),
          });
        }
        // an order that does not match by ID must not stay attached to anybody (older syncs matched by phone)
        if (unmatched.length) { const { error: e3 } = await sb.from("deliveries").update({ customer_id: null }).in("order_id", unmatched); if (e3) throw e3; }
        if (rows.length) {
          const { data: have } = await sb.from("deliveries").select("order_id,photo_paths").in("order_id", rows.map((r) => r.order_id));
          const hv = new Map((have || []).map((h: any) => [h.order_id, h.photo_paths as string[]]));
          for (const r of rows) r.photo_paths = (hv.get(r.order_id) || []).slice(0, r.photo_urls.length);
          const { error: e2 } = await sb.from("deliveries").upsert(rows, { onConflict: "order_id" });
          if (e2) throw e2;
          saved += rows.length;
        }
        if (!j.pagination?.has_more || oldest < since) break;
        await wait(500);
      }
    }
    const next = offset + CHUNK < phones.length ? offset + CHUNK : null;
    return json({ ok: true, mode, offset, next, total: phones.length, orders_seen: seen, deliveries_saved: saved, via_id: viaId, via_phone: viaPhone, via_name: viaName, no_match: noMatch, phone_match_codes: examples, id_paths: idPaths, sample_paths: samplePaths });
  } catch (e) {
    return json({ ok: false, error: String((e as Error).message || e) }, 500);
  }
});
