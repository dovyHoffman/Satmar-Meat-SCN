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

async function who(req: Request): Promise<{ ok: boolean; owner: boolean; customers: boolean; billing?: boolean; id?: string }> {
  const secret = Deno.env.get("SYNC_SECRET");
  if (secret && req.headers.get("x-sync-secret") === secret) return { ok: true, owner: true, customers: true, billing: true };
  const jwt = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  if (!jwt) return { ok: false, owner: false, customers: false };
  const { data } = await sb.auth.getUser(jwt);
  if (!data?.user) return { ok: false, owner: false, customers: false };
  const { data: p } = await sb.from("profiles").select("role,active,pages").eq("id", data.user.id).single();
  if (!p || !p.active) return { ok: false, owner: false, customers: false };
  return { ok: true, id: data.user.id, owner: p.role === "owner", customers: p.role === "owner" || (p.pages || []).includes("customers"), billing: p.role === "owner" || (p.pages || []).includes("billing") };
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
    // ---- mode "probe": owner only, read only. Sends the given extra search fields to Scanovator to learn what it accepts (e.g. a date filter without phones). Returns counts and field names only. ----
    if (body.mode === "probe") {
      const r = await fetch(API, { method: "POST", headers: { Authorization: "Bearer " + Deno.env.get("SCANOVATOR_TOKEN"), "Content-Type": "application/json", Accept: "application/json" }, body: JSON.stringify({ store_id: STORE_ID, store_code: STORE_CODE, page: 1, limit: 5, ...(body.q || {}) }) });
      const j = await r.json().catch(() => ({}));
      const d = Array.isArray(j.data) ? j.data : [];
      return json({ ok: true, status: r.status, message: String(j.message || "").slice(0, 200), errors: JSON.stringify(j.errors || {}).slice(0, 400), n: d.length, pagination: j.pagination || null, created: d.map((o: any) => o.createdAtIso), delivered: d.map((o: any) => o.actually_delivered), keys: d[0] ? Object.keys(d[0]).join(",") : "" });
    }
    // ---- mode "lookup": owner only. Shows the raw Scanovator orders (all simple fields) for a few phone numbers. Read only. ----
    if (body.mode === "lookup") {
      const ph = body.raw ? (Array.isArray(body.phones) ? body.phones : []).map((x: unknown) => String(x)).slice(0, 5) : (Array.isArray(body.phones) ? body.phones : []).map((x: unknown) => digits(x)).filter((x: string) => x.length === 10).slice(0, 5);
      if (!ph.length) return json({ ok: false, error: "no phones" });
      const j = await search(ph, 1);
      const orders = (j.data || []).slice(0, 12).map((o: any) => { const r: Record<string, string> = {}; for (const [k, v] of Object.entries(o)) { if (v === null || v === undefined || typeof v === "object") continue; const t = String(v); if (t !== "") r[k] = t.slice(0, 60); } return r; });
      return json({ ok: true, count: (j.data || []).length, orders });
    }
    // ---- mode "smtptest": owner only. Checks whether this server can reach the mail server (no password used). ----
    if (body.mode === "smtptest") {
      if (!me.owner) return json({ ok: false, error: "Only the owner." });
      const out: Record<string, string> = {};
      for (const port of [587, 465, 25]) {
        try {
          const c = await Promise.race([Deno.connect({ hostname: "smtp.office365.com", port }), wait(6000).then(() => { throw new Error("timeout"); })]) as Deno.Conn;
          const buf = new Uint8Array(200); const n = await Promise.race([c.read(buf), wait(5000).then(() => null)]);
          out["port " + port] = "open" + (n ? ": " + new TextDecoder().decode(buf.subarray(0, n as number)).trim().slice(0, 60) : "");
          c.close();
        } catch (e) { out["port " + port] = "blocked: " + String((e as Error).message || e).slice(0, 80); }
      }
      out.secrets = ["SMTP_USER", "SMTP_PASS", "RESEND_API_KEY"].map((k) => k + "=" + (Deno.env.get(k) ? "set" : "missing")).join(", ");
      return json({ ok: true, result: out });
    }

    // ---- mode "sendinvoice": owner or billing. Emails an invoice (PDF attached) and records it. ----
    if (body.mode === "sendinvoice") {
      if (!me.billing) return json({ ok: false, error: "Only the admin or billing can send invoices." });
      const okMail = (e: string) => /^[^@\s,;]+@[^@\s,;]+\.[^@\s,;]+$/.test(e);
      const clean = (a: unknown) => (Array.isArray(a) ? a : []).map((x) => String(x).trim()).filter(Boolean);
      const to = clean(body.to), cc = clean(body.cc);
      if (!to.length) return json({ ok: false, error: "Add at least one email address to send to." });
      const bad = to.concat(cc).filter((e) => !okMail(e));
      if (bad.length) return json({ ok: false, error: "These do not look like email addresses: " + bad.join(", ") });
      if (to.length + cc.length > 20) return json({ ok: false, error: "Too many addresses." });
      const subject = String(body.subject || "Invoice").slice(0, 200), html = String(body.html || "").slice(0, 400000), text = String(body.text || "").slice(0, 20000);
      const xl = String(body.xlsx_b64 || ""), xlName = String(body.xlsx_name || "Billing.xlsx").replace(/[^A-Za-z0-9._ -]/g, "_").slice(0, 80);
      const pdf = String(body.pdf_b64 || ""), fname = String(body.filename || "Invoice.pdf").replace(/[^A-Za-z0-9._ -]/g, "_").slice(0, 80);
      if (pdf.length > 6_000_000) return json({ ok: false, error: "The attachment is too large." });
      const fromAddr = Deno.env.get("SMTP_USER") || Deno.env.get("INVOICE_FROM") || "";
      const fromName = String(body.from_name || "Satmar Meat").replace(/[<>"\r\n]/g, "").slice(0, 60);
      let sent = false, err = "";
      try {
        if (Deno.env.get("RESEND_API_KEY")) {
          const r = await fetch("https://api.resend.com/emails", {
            method: "POST", headers: { Authorization: "Bearer " + Deno.env.get("RESEND_API_KEY"), "content-type": "application/json" },
            body: JSON.stringify({ from: fromName + " <" + (Deno.env.get("INVOICE_FROM") || fromAddr) + ">", to, cc, subject, html, text, attachments: [...(pdf ? [{ filename: fname, content: pdf }] : []), ...(xl ? [{ filename: xlName, content: xl }] : [])] }),
          });
          if (!r.ok) throw new Error("Mail service said: " + (await r.text()).slice(0, 200));
          sent = true;
        } else {
          if (!Deno.env.get("SMTP_USER") || !Deno.env.get("SMTP_PASS")) return json({ ok: false, error: "Email sending is not switched on yet: the mailbox password has not been added in Supabase (Edge Functions → Secrets: SMTP_USER and SMTP_PASS)." });
          const nm = (await import("npm:nodemailer@6.9.14")).default;
          const tr = nm.createTransport({ host: Deno.env.get("SMTP_HOST") || "smtp.office365.com", port: Number(Deno.env.get("SMTP_PORT") || 587), secure: false, requireTLS: true, auth: { user: Deno.env.get("SMTP_USER"), pass: Deno.env.get("SMTP_PASS") }, connectionTimeout: 15000, socketTimeout: 30000 });
          await tr.sendMail({ from: '"' + fromName + '" <' + fromAddr + '>', to: to.join(", "), cc: cc.join(", ") || undefined, subject, html, text, attachments: [...(pdf ? [{ filename: fname, content: pdf, encoding: "base64" }] : []), ...(xl ? [{ filename: xlName, content: xl, encoding: "base64" }] : [])] });
          sent = true;
        }
      } catch (e) { err = String((e as Error).message || e).slice(0, 300); }
      await sb.from("invoice_emails").insert({ company: String(body.company || ""), week: String(body.week || ""), inv_no: String(body.inv_no || ""), amount: Number(body.amount) || null, to_list: to, cc_list: cc, subject, ok: sent, error: err || null, sent_by: me.id ?? null });
      return sent ? json({ ok: true }) : json({ ok: false, error: "Not sent: " + err });
    }

    if (body.mode === "removeuser") {
      // Owner removes a person completely: their login and their access row. Customer data is not touched.
      const uid = String(body.id || "");
      if (!/^[0-9a-f-]{36}$/i.test(uid)) return json({ ok: false, error: "No person selected." });
      if (uid === me.id) return json({ ok: false, error: "You cannot remove yourself." });
      const { error: de } = await sb.auth.admin.deleteUser(uid);
      if (de && !/not found/i.test(de.message || "")) return json({ ok: false, error: de.message || "Could not remove." });
      await sb.from("profiles").delete().eq("id", uid);
      return json({ ok: true });
    }
    if (body.mode === "invite") {
      const email = String(body.email || "").trim().toLowerCase();
      const name = String(body.name || "").trim();
      const role = ["owner", "secretary", "billing", "demo"].includes(body.role) ? body.role : "secretary";
      if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return json({ ok: false, error: "That email does not look right." });
      const pages = role === "secretary" ? ["customers", "changes", "delivery", "menu"] : role === "billing" ? ["billing"] : [];
      const { data, error } = await sb.auth.admin.inviteUserByEmail(email, {
        data: { name: name || email.split("@")[0] },
        redirectTo: String(body.redirect || "https://dovyhoffman.github.io/Satmar-Meat-SCN/"),
      });
      if (error) return json({ ok: false, error: error.message });
      const id = data?.user?.id;
      if (id) {
        const { error: pe } = await sb.from("profiles").upsert({ id, email, name: name || email.split("@")[0], role, pages, active: true }, { onConflict: "id" });
        if (pe) return json({ ok: true, warning: "Invitation sent, but the access settings were not saved (" + pe.message + "). Set them in the table above." });
      }
      return json({ ok: true });
    }
    for (const k of ["SCANOVATOR_TOKEN", "SCANOVATOR_STORE_ID", "SCANOVATOR_STORE_CODE"])
      if (!Deno.env.get(k)) return json({ ok: false, error: `Secret ${k} is not set in Supabase.` }, 500);
    if (!Number.isInteger(STORE_ID))
      return json({ ok: false, error: "SCANOVATOR_STORE_ID must be a whole number (digits only). Fix it in Supabase > Edge Functions > Secrets." }, 500);
    if (!STORE_CODE) return json({ ok: false, error: "SCANOVATOR_STORE_CODE is empty." }, 500);

    if (body.mode === "create") {
      // Creates orders in Scanovator through its API (owner only). Used first for one clearly marked test order.
      const list = (Array.isArray(body.orders) ? body.orders : []).slice(0, 25);
      const results: unknown[] = [];
      for (const o of list) {
        try {
          const r = await fetch("https://api.scanovator.com/v2/orders/create", {
            method: "POST",
            headers: { Authorization: "Bearer " + Deno.env.get("SCANOVATOR_TOKEN"), "Content-Type": "application/json", Accept: "application/json" },
            body: JSON.stringify({ store_id: STORE_ID, store_code: STORE_CODE, ...o }),
          });
          const t = await r.text();
          results.push({ order_id: o.order_id, status: r.status, body: t.slice(0, 600) });
        } catch (e) {
          results.push({ order_id: o.order_id, error: String((e as Error).message || e) });
        }
      }
      return json({ ok: true, results });
    }

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
      const { data, error } = await sb.from("customers").select("id,agency_ref,phone,cell,street,apt,name,food,hh,area,middleton,base").eq("active", true).order("id").range(f, f + 999);
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

    // ---- mode "byorder": for every order in the uploaded Scanovator export (order_map), ask Scanovator for THAT order number: delivery time, driver, receipt, pictures ----
    if (body.mode === "byorder") {
      const BATCH = 30;
      const { data: allMap, error: me } = await sb.from("order_map").select("order_id,app_id,letters").order("order_id").range(offset, offset + BATCH - 1);
      if (me) throw me;
      const map = allMap || [];
      const { count: total } = await sb.from("order_map").select("order_id", { count: "exact", head: true });
      const ids = map.map((m: any) => String(m.order_id));
      const have = new Map<string, any>();
      if (ids.length) { const { data: ex } = await sb.from("deliveries").select("order_id,photo_paths,snap,delivered_at,customer_id").in("order_id", ids); (ex || []).forEach((x: any) => have.set(String(x.order_id), x)); }
      let saved = 0, undelivered = 0, nocust = 0, failed = 0, skippedDone = 0;
      const rows: any[] = [];
      const one = async (m: any) => {
        const oid = String(m.order_id);
        const h = have.get(oid);
        if (h && h.delivered_at && h.customer_id) { skippedDone++; return; }
        for (let t = 0; t < 3; t++) {
          try {
            const r = await fetch(API, { method: "POST", headers: { Authorization: "Bearer " + Deno.env.get("SCANOVATOR_TOKEN"), "Content-Type": "application/json", Accept: "application/json" }, body: JSON.stringify({ store_id: STORE_ID, store_code: STORE_CODE, order_id: oid, page: 1, limit: 5 }) });
            if (r.status === 429 || r.status >= 500) { await wait(1500 * (t + 1)); continue; }
            const j = await r.json().catch(() => ({}));
            const o = (j.data || []).find((x: any) => String(x.order_id) === oid) || (j.data || [])[0];
            if (!o) { failed++; return; }
            const c = byId.get(idKey(m.app_id));
            if (!c) { nocust++; return; }
            const delivered = nyIso(o.actually_delivered);
            if (!delivered) { undelivered++; return; }
            const letters = m.letters ? String(m.letters).split(/[^A-Za-z0-9]+/).filter(Boolean).map((x: string) => x.toUpperCase()).join(" ") : "";
            const urls = (o.photos || []).map(String).filter(Boolean).map(https);
            const row: any = {
              order_id: oid, customer_id: c.id, week_label: label(delivered),
              driver: String(o.driver_name || o.driver_string || ""), delivered_at: delivered, route_started: nyIso(o.route_started),
              receipt_url: o.receipt_url ? https(o.receipt_url) : "", photo_urls: urls, synced_at: new Date().toISOString(),
              photo_paths: ((h && h.photo_paths) || []).slice(0, urls.length),
              snap: h && h.snap ? h.snap : { food: c.food, hh: c.hh, area: c.area, mid: c.middleton, base: c.base, boxes: letters ? letters.split(" ").length : (Number(o.total_boxes) || 0), ...(letters ? { letters } : {}) },
            };
            rows.push(row);
            return;
          } catch { await wait(1000 * (t + 1)); }
        }
        failed++;
      };
      for (let i = 0; i < map.length; i += 6) await Promise.all(map.slice(i, i + 6).map(one));
      if (rows.length) { const { error: e2 } = await sb.from("deliveries").upsert(rows, { onConflict: "order_id" }); if (e2) throw e2; saved = rows.length; }
      const next = offset + BATCH < (total || 0) ? offset + BATCH : null;
      return json({ ok: true, mode: "byorder", offset, next, total, saved, undelivered, nocust, failed, skipped_done: skippedDone });
    }
    const byPhone = new Map<string, any[]>();
    for (const c of cust) {
      // the main phone AND the second (cell) number: an order may carry either one
      for (const k of new Set([digits(c.phone), digits(c.cell)])) {
        if (/^[2-9]\d\d[2-9]\d{6}$/.test(k)) { if (!byPhone.has(k)) byPhone.set(k, []); byPhone.get(k)!.push(c); }
      }
    }
    const phones = [...byPhone.keys()].sort();
    const chunk = phones.slice(offset, offset + CHUNK);
    const daysBack = Math.min(DAYS_BACK, Math.max(1, Number(body.days) || DAYS_BACK));   // quick runs ask for only the last few days
    const delivered0 = (o: any) => { const d = nyIso(o.actually_delivered); return !!d && new Date(d).getTime() > Date.now() - 6 * 864e5; };
    const since = Date.now() - daysBack * 864e5;
    let seen = 0, saved = 0, viaId = 0, viaPhone = 0, noMatch = 0, viaName = 0;
    const loose = body.loose === true;
    const word = body.word === true;
    const dbg = { try: 0, hit: 0, many: 0, none: 0, wk: "" };
    const wkStart = (() => {   // last Saturday 00:00 New York (the delivery week starts Saturday)
      const parts = new Intl.DateTimeFormat("en-US", { timeZone: "America/New_York", weekday: "short", year: "numeric", month: "2-digit", day: "2-digit" }).formatToParts(new Date());
      const g = (t: string) => parts.find((x) => x.type === t)!.value;
      const back = ({ Sat: 0, Sun: 1, Mon: 2, Tue: 3, Wed: 4, Thu: 5, Fri: 6 } as Record<string, number>)[g("weekday")];
      const d = new Date(Date.UTC(Number(g("year")), Number(g("month")) - 1, Number(g("day")) - back, 12));
      return new Date(nyIso(`${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}-${String(d.getUTCDate()).padStart(2, "0")} 00:00:00`)!).getTime();
    })();
    const thisWeek = (o: any) => { const d = nyIso(o.actually_delivered); return !!d && new Date(d).getTime() >= wkStart; };
    dbg.wk = new Date(wkStart).toISOString();
    const haveWeek = new Set<string>();   // customers that already have a delivery this week
    const owner = new Map<string, string>();   // order -> customer it is already attached to this week (so a second run keeps the same link)
    if (word) { for (let f = 0; ; f += 1000) { const { data } = await sb.from("deliveries").select("customer_id,order_id").gte("delivered_at", new Date(wkStart).toISOString()).not("customer_id", "is", null).range(f, f + 999); (data || []).forEach((x: any) => { haveWeek.add(x.customer_id); owner.set(String(x.order_id), x.customer_id); }); if ((data || []).length < 1000) break; } }   // owner ticked "also match by name + phone"
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
    const found: any[] = [];
    // diagnostics (numbers only): skipped orders that were delivered in the last 6 days, and why they did not match
    const diag: Record<string, number> = { delivered_skipped: 0, name_unique: 0, name_several: 0, phone_only: 0, nothing: 0, no_code: 0 };
    const nameMap = new Map<string, any[]>();
    for (const c of cust) { const w = words(c.name); if (w) { if (!nameMap.has(w)) nameMap.set(w, []); nameMap.get(w)!.push(c); } }
    let withCode = 0, withOnline = 0, deliveredN = 0; const codeEx = new Set<string>(); let deliveredSample: string[] = [];
    // diagnostics: where on an order does Scanovator keep our customer ID?
    const caseKeys: string[] = [];
    const idPaths: Record<string, number> = {}; let samplePaths: string[] = []; let diagN = 0;
    const flat = (v: any, path: string, out: [string, string][], d = 0) => {
      if (v === null || v === undefined) return;
      if (typeof v === "object") { if (d >= 3) return; const ent = Array.isArray(v) ? v.slice(0, 3).map((x, i) => [String(i), x]) : Object.entries(v); for (const [k, x] of ent as any[]) flat(x, path ? path + "." + k : String(k), out, d + 1); return; }
      const t = String(v); if (t !== "") out.push([path, t]);
    };
    if (chunk.length) {
      for (let page = 1; page <= 6; page++) {
        const j = await search(chunk, page);
        if (body.find) {   // read-only search: which order holds this text (e.g. a photo file name)?
          for (const o of j.data || []) if (JSON.stringify(o).includes(String(body.find))) { const r: Record<string, string> = {}; for (const [k, v] of Object.entries(o)) { if (v === null || v === undefined || typeof v === "object") continue; const t = String(v); if (t !== "") r[k] = t.slice(0, 60); } found.push(r); }
          if (!j.pagination?.has_more || page >= 3) break; await wait(300); continue;
        }
        const rows: any[] = [];
        let oldest = Infinity;
        const unmatched: string[] = [];
        const om = new Map<string, any>();   // order number -> Application ID + box letters (uploaded from the Scanovator export)
        { const ids = (j.data || []).map((o: any) => String(o.order_id)); if (ids.length) { const r: any = await sb.from("order_map").select("order_id,app_id,letters").in("order_id", ids); if (!r.error) (r.data || []).forEach((x: any) => om.set(String(x.order_id), x)); } }
        for (const o of j.data || []) {
          seen++;
          const created = new Date(o.createdAtIso).getTime();
          if (created < oldest) oldest = created;
          if (created < since) continue;
          if (String(o.customercode ?? "").trim()) { withCode++; if (codeEx.size < 6) codeEx.add(String(o.customercode).slice(0, 24)); }
          if (String(o.online_order_id ?? "").trim()) { withOnline++; if (codeEx.size < 6) codeEx.add("online:" + String(o.online_order_id).slice(0, 24)); }
          if (String(o.actually_delivered ?? "").trim()) { deliveredN++; if (!deliveredSample.length) { const fl2: [string, string][] = []; flat(o, "", fl2); deliveredSample = fl2.map(([pa, va]) => /^(fname|lname|phone|cell1|cell2|address|street_address|unit|city|state|zip)$/.test(pa) ? pa + "=(hidden)" : pa + "=" + va.slice(0, 18)).slice(0, 40); } }
          // match ONLY by the customer ID Scanovator keeps on the order (customer code). The phone is used just to find the orders.
          let c: any = null;
          const mp = om.get(String(o.order_id));
          if (mp && idKey(mp.app_id)) { const hit = byId.get(idKey(mp.app_id)); if (hit) { c = hit; viaId++; } }
          if (!c) for (const f of [o.customercode, o.online_order_id]) { const hit = byId.get(idKey(f)); if (hit && idKey(f)) { c = hit; viaId++; break; } }
                    if (!c && loose) { const h = byNamePhone(o); if (h) { c = h; viaName++; } }
          // phone + at least one shared name word, ONE customer only, and ONLY for deliveries of this week to customers that have no delivery yet this week
          if (!c && word && thisWeek(o)) {
            dbg.try++;
            const ow = new Set(words(`${o.fname || ""} ${o.lname || ""}`).split(" ").filter((w) => w.length > 1));
            const hits = new Map<string, any>();
            for (const ph of [o.phone, o.cell1, o.cell2]) for (const cc of byPhone.get(last10(ph)) || []) {
              if (haveWeek.has(cc.id) && owner.get(String(o.order_id)) !== cc.id) continue;
              if (words(cc.name).split(" ").some((w) => w.length > 1 && ow.has(w))) hits.set(cc.id, cc);
            }
            if (hits.size === 1) { c = [...hits.values()][0]; viaName++; dbg.hit++; } else if (hits.size > 1) dbg.many++; else dbg.none++;
          }
          if (!c && diagN < 40) { diagN++; const fl: [string, string][] = []; flat(o, "", fl);
            const PII = /^(fname|lname|phone|cell1|cell2|address|street_address|unit|city|state|zip)$/;
            for (const [pa, va] of fl) {
              const k = idKey(va); if (k && byId.has(k)) idPaths[pa] = (idPaths[pa] || 0) + 1;
              for (const tk of va.match(/[A-Za-z]{1,4}[\s-]*\d{2,6}/g) || []) { const k2 = idKey(tk); if (k2 && byId.has(k2)) idPaths[pa + " (inside text)"] = (idPaths[pa + " (inside text)"] || 0) + 1; }
            }
            if (samplePaths.length < 60 && diagN <= 2) for (const [pa, va] of fl) samplePaths.push(PII.test(pa) ? pa + "=(hidden)" : pa + "=" + va.slice(0, 18)); }
          if (!c && delivered0(o)) {
            diag.delivered_skipped++;
            if (!String(o.customercode ?? "").trim() && !String(o.online_order_id ?? "").trim()) diag.no_code++;
            const ow = words(`${o.fname || ""} ${o.lname || ""}`); const nm = ow ? (nameMap.get(ow) || []) : [];
            if (nm.length === 1) diag.name_unique++; else if (nm.length > 1) diag.name_several++;
            else if ([o.phone, o.cell1, o.cell2].some((p: any) => byPhone.has(last10(p)))) diag.phone_only++; else diag.nothing++;
          }
          if (!c) { noMatch++; unmatched.push(String(o.order_id)); if (examples.length < 3) examples.push(String(o.customercode || o.online_order_id || "(none)").slice(0, 20)); continue; }  // only match by customer ID
          const delivered = nyIso(o.actually_delivered);
          // "Case description" (Scanovator column AI) holds the box letters of this delivery, e.g. "B" or "A,S"
          let caseRaw: any = null, caseKey = "";
          for (const [k, v] of Object.entries(o)) { if (/case/i.test(k) && v !== null && v !== undefined && typeof v !== "object" && String(v).trim()) { caseRaw = v; caseKey = k; break; } }
          if (caseKey && caseKeys.length < 3 && !caseKeys.includes(caseKey + "=" + String(caseRaw).slice(0, 12))) caseKeys.push(caseKey + "=" + String(caseRaw).slice(0, 12));
          const letters0 = caseRaw ? String(caseRaw).split(/[^A-Za-z0-9]+/).filter(Boolean).map((x) => x.toUpperCase()).join(" ") : "";
          const letters = mp && mp.letters ? String(mp.letters).split(/[^A-Za-z0-9]+/).filter(Boolean).map((x) => x.toUpperCase()).join(" ") : letters0;
          rows.push({
            order_id: String(o.order_id), customer_id: c.id,
            week_label: label(delivered || o.createdAtIso),
            driver: String(o.driver_name || o.driver_string || ""),
            delivered_at: delivered, route_started: nyIso(o.route_started),
            receipt_url: o.receipt_url ? https(o.receipt_url) : "",
            photo_urls: (o.photos || []).map(String).filter(Boolean).map(https), synced_at: new Date().toISOString(),
            snap: { food: c.food, hh: c.hh, area: c.area, mid: c.middleton, base: c.base, boxes: letters ? letters.split(" ").length : (Number(o.total_boxes) || 0), ...(letters ? { letters } : {}) },   // what the customer had when it was delivered
          });
        }
        // an order that does not match by ID must not stay attached to anybody (older syncs matched by phone)
        if (unmatched.length) { const { error: e3 } = await sb.from("deliveries").update({ customer_id: null }).in("order_id", unmatched); if (e3) throw e3; }
        if (rows.length) {
          const ids = rows.map((r) => r.order_id);
          let snapOk = true;
          let hr: any = await sb.from("deliveries").select("order_id,photo_paths,snap").in("order_id", ids);
          if (hr.error) { snapOk = false; hr = await sb.from("deliveries").select("order_id,photo_paths").in("order_id", ids); }
          const hv = new Map((hr.data || []).map((h: any) => [h.order_id, h]));
          for (const r of rows) {
            const h: any = hv.get(r.order_id);
            r.photo_paths = ((h && h.photo_paths) || []).slice(0, r.photo_urls.length);
            if (snapOk) { if (h && h.snap) r.snap = { ...h.snap, boxes: r.snap.boxes, ...(r.snap.letters ? { letters: r.snap.letters } : {}) }; } else delete r.snap;   // first food/household snapshot stays; the box count is refreshed   // keep the first snapshot; no column yet = skip it
          }
          const { error: e2 } = await sb.from("deliveries").upsert(rows, { onConflict: "order_id" });
          if (e2) throw e2;
          saved += rows.length;
        }
        if (!j.pagination?.has_more || oldest < since) break;
        await wait(500);
      }
    }
    const next = offset + CHUNK < phones.length ? offset + CHUNK : null;
    return json({ ok: true, mode, offset, next, total: phones.length, orders_seen: seen, deliveries_saved: saved, via_id: viaId, via_phone: viaPhone, via_name: viaName, with_code: withCode, with_online: withOnline, delivered_n: deliveredN, code_examples: [...codeEx], delivered_sample: deliveredSample, in_window: 0, no_match: noMatch, diag, found, dbg, have_week: haveWeek.size, phone_match_codes: examples, case_keys: caseKeys, id_paths: idPaths, sample_paths: samplePaths });
  } catch (e) {
    return json({ ok: false, error: String((e as Error).message || e) }, 500);
  }
});
