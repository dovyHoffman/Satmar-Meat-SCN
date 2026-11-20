-- Monsey and Monroe become two separate areas (old value monsey_monroe stays for existing customers).
alter type area_t add value if not exists 'monsey';
alter type area_t add value if not exists 'monroe';
