-- New roles: Admin and Manager (their access comes from the pages ticked in Settings; only the owner is unlimited).
alter type role_t add value if not exists 'admin';
alter type role_t add value if not exists 'manager';
