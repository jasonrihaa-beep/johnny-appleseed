-- ============================================================
-- JOHNNY APPLESEED — S2 SCHEMA v1
-- Run once in Supabase SQL Editor. Versioned in repo as source
-- of truth. Idempotent-ish: uses IF NOT EXISTS where possible.
-- Security model: static PWA, anon key is PUBLIC by design.
-- RLS + triggers below are the ENTIRE security layer.
-- ============================================================

-- ── PROFILES ─────────────────────────────────────────────────
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name varchar(40) not null default 'Planter',
  avatar_color char(7)     not null default '#4A7C59',
  created_at   timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_public"
  on public.profiles for select using (true);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id) with check (auth.uid() = id);

-- No client INSERT policy: rows are created by trigger below.

-- Auto-create a profile on signup (incl. anonymous signups).
-- SECURITY DEFINER so it can insert despite RLS.
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  palette text[] := array['#4A7C59','#D97B1A','#6D28D9','#335736','#B8620A'];
begin
  insert into public.profiles (id, avatar_color)
  values (new.id, palette[1 + floor(random() * 5)::int]);
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── PLANTS ───────────────────────────────────────────────────
create table if not exists public.plants (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid()
               references auth.users(id) on delete cascade,
  plant_name   varchar(80)  not null check (length(trim(plant_name)) > 0),
  sci          varchar(120),
  tags         text[] not null default '{}'
               check (tags <@ array['edible','wildlife','pollinator']::text[])
               check (cardinality(tags) <= 3),
  lat          double precision not null check (lat between -90 and 90),
  lng          double precision not null check (lng between -180 and 180),
  neighborhood varchar(80),
  score        smallint check (score between 0 and 100),
  note         varchar(255),
  photo_url    varchar(500),          -- storage bucket lands in S2.5
  -- Physical access: can the public actually reach/harvest this plant?
  -- 'public'  = park strip, community garden, open spot (where permitted)
  -- 'ask'     = front yard / visible — knock first
  -- 'private' = my yard; data shared, access not
  -- SAFE DEFAULT is 'private': mislabeling a private yard as open
  -- access invites trespass. UI celebrates 'public', never assumes it.
  access       varchar(12) not null default 'private'
               check (access in ('public','ask','private')),
  planted_at   timestamptz not null default now()
);

alter table public.plants enable row level security;

create policy "plants_select_public"
  on public.plants for select using (true);

create policy "plants_insert_own"
  on public.plants for insert
  with check (auth.uid() = user_id);

create policy "plants_update_own"
  on public.plants for update
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "plants_delete_own"
  on public.plants for delete
  using (auth.uid() = user_id);

-- ── PRIVACY GUARANTEE: coordinate truncation AT THE DATABASE ──
-- ~3 decimals ≈ 110 m. Client truncates too, but this trigger is
-- the guarantee: no row can ever store full-precision GPS,
-- regardless of client bugs. Public-read table demands this.
create or replace function public.truncate_coords()
returns trigger language plpgsql
as $$
begin
  new.lat := round(new.lat::numeric, 3);
  new.lng := round(new.lng::numeric, 3);
  return new;
end $$;

drop trigger if exists plants_truncate_coords on public.plants;
create trigger plants_truncate_coords
  before insert or update on public.plants
  for each row execute function public.truncate_coords();

-- ── SPAM CAP: 50 plants / user / rolling 24h ──────────────────
-- A public-write social table WILL get abused eventually.
-- 12 lines of insurance for an existential UX risk.
create or replace function public.enforce_plant_daily_cap()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if (select count(*) from public.plants
      where user_id = new.user_id
        and planted_at > now() - interval '24 hours') >= 50 then
    raise exception 'Daily planting limit reached (50). Try again tomorrow.';
  end if;
  return new;
end $$;

drop trigger if exists plants_daily_cap on public.plants;
create trigger plants_daily_cap
  before insert on public.plants
  for each row execute function public.enforce_plant_daily_cap();

-- ── INDEXES ──────────────────────────────────────────────────
create index if not exists plants_planted_at_idx on public.plants (planted_at desc);
create index if not exists plants_lat_lng_idx    on public.plants (lat, lng);
create index if not exists plants_tags_idx       on public.plants using gin (tags);
-- "Open harvest" is a headline map filter — partial index keeps it fast
create index if not exists plants_public_access_idx
  on public.plants (access) where access = 'public';

-- If schema.sql was ALREADY run before this column existed, run only:
--   alter table public.plants
--     add column access varchar(12) not null default 'private'
--     check (access in ('public','ask','private'));
--   (plus the partial index statement above)

-- ── NOTES / DEFERRED ─────────────────────────────────────────
-- Feed "nearby" = bounding-box on (lat,lng) index + client sort.
--   PostGIS is the upgrade path if scale demands it. Not now.
-- Storage bucket + photo upload policies: S2.5, separate pass.
-- Display-name profanity filtering: deferred, documented gap.
-- usda_symbol from the Session-0 sketch dropped: client has
--   scientific names (sci), not USDA symbols.

-- v0.13.0 MIGRATION (applied in dashboard)
alter table public.plants
  add column if not exists kind varchar(12) not null default 'planted'
  check (kind in ('planted','discovered'));
