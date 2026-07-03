-- ============================================================
-- JOHNNY APPLESEED — S4 SOCIAL SCHEMA
-- Run ONCE in Supabase SQL Editor, after schema.sql.
-- Tables sit idle until phases S4a-S4d wire them client-side.
-- Same security model: RLS is the entire wall.
-- ============================================================

-- ── FOLLOWS (S4b) ────────────────────────────────────────────
create table if not exists public.follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  followed_id uuid not null references auth.users(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (follower_id, followed_id),
  check (follower_id <> followed_id)
);

alter table public.follows enable row level security;

create policy "follows_select_public"
  on public.follows for select using (true);

create policy "follows_insert_own"
  on public.follows for insert
  with check (auth.uid() = follower_id);

create policy "follows_delete_own"
  on public.follows for delete
  using (auth.uid() = follower_id);

-- ── INSPIRES (S4b) — the like, made real ────────────────────
create table if not exists public.inspires (
  user_id    uuid not null references auth.users(id) on delete cascade,
  plant_id   uuid not null references public.plants(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, plant_id)
);

alter table public.inspires enable row level security;

create policy "inspires_select_public"
  on public.inspires for select using (true);

create policy "inspires_insert_own"
  on public.inspires for insert
  with check (auth.uid() = user_id);

create policy "inspires_delete_own"
  on public.inspires for delete
  using (auth.uid() = user_id);

-- ── COMMENTS (S4c — ships ONLY with report/block) ───────────
create table if not exists public.comments (
  id         uuid primary key default gen_random_uuid(),
  plant_id   uuid not null references public.plants(id) on delete cascade,
  user_id    uuid not null default auth.uid()
             references auth.users(id) on delete cascade,
  body       varchar(280) not null check (length(trim(body)) > 0),
  created_at timestamptz not null default now()
);

alter table public.comments enable row level security;

create policy "comments_select_public"
  on public.comments for select using (true);

create policy "comments_insert_own"
  on public.comments for insert
  with check (auth.uid() = user_id);

-- Commenter can delete own; plant owner can moderate their post's thread.
create policy "comments_delete_own_or_plant_owner"
  on public.comments for delete
  using (
    auth.uid() = user_id
    or auth.uid() = (select user_id from public.plants where id = plant_id)
  );

-- Comment spam cap: 100 / user / rolling 24h
create or replace function public.enforce_comment_daily_cap()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if (select count(*) from public.comments
      where user_id = new.user_id
        and created_at > now() - interval '24 hours') >= 100 then
    raise exception 'Daily comment limit reached. Try again tomorrow.';
  end if;
  return new;
end $$;

drop trigger if exists comments_daily_cap on public.comments;
create trigger comments_daily_cap
  before insert on public.comments
  for each row execute function public.enforce_comment_daily_cap();

-- ── REPORTS (S4c) — write-only for clients, dashboard is the
--    mod queue. NO select policy on purpose: reporters and
--    reported users must never read this table. ──────────────
create table if not exists public.reports (
  id          uuid primary key default gen_random_uuid(),
  reporter_id uuid not null default auth.uid()
              references auth.users(id) on delete cascade,
  target_type varchar(12) not null
              check (target_type in ('plant','comment','profile')),
  target_id   uuid not null,
  reason      varchar(280),
  created_at  timestamptz not null default now()
);

alter table public.reports enable row level security;

create policy "reports_insert_own"
  on public.reports for insert
  with check (auth.uid() = reporter_id);

-- ── BLOCKS (S4c) — hide-from-me list ────────────────────────
create table if not exists public.blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

alter table public.blocks enable row level security;

create policy "blocks_select_own"
  on public.blocks for select using (auth.uid() = blocker_id);

create policy "blocks_insert_own"
  on public.blocks for insert with check (auth.uid() = blocker_id);

create policy "blocks_delete_own"
  on public.blocks for delete using (auth.uid() = blocker_id);

-- ── NOTIFICATIONS (S4d) — trigger-written, owner-read ───────
create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  actor_id   uuid not null references auth.users(id) on delete cascade,
  type       varchar(12) not null
             check (type in ('inspire','comment','follow')),
  plant_id   uuid references public.plants(id) on delete cascade,
  read       boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

create policy "notifications_select_own"
  on public.notifications for select using (auth.uid() = user_id);

create policy "notifications_update_own"
  on public.notifications for update
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- No client INSERT policy: fan-out happens via triggers below.

create or replace function public.notify_on_inspire()
returns trigger language plpgsql security definer set search_path = public
as $$
declare
  owner uuid;
begin
  select user_id into owner from public.plants where id = new.plant_id;
  if owner is not null and owner <> new.user_id then
    insert into public.notifications (user_id, actor_id, type, plant_id)
    values (owner, new.user_id, 'inspire', new.plant_id);
  end if;
  return new;
end $$;

drop trigger if exists inspires_notify on public.inspires;
create trigger inspires_notify
  after insert on public.inspires
  for each row execute function public.notify_on_inspire();

create or replace function public.notify_on_comment()
returns trigger language plpgsql security definer set search_path = public
as $$
declare
  owner uuid;
begin
  select user_id into owner from public.plants where id = new.plant_id;
  if owner is not null and owner <> new.user_id then
    insert into public.notifications (user_id, actor_id, type, plant_id)
    values (owner, new.user_id, 'comment', new.plant_id);
  end if;
  return new;
end $$;

drop trigger if exists comments_notify on public.comments;
create trigger comments_notify
  after insert on public.comments
  for each row execute function public.notify_on_comment();

create or replace function public.notify_on_follow()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.notifications (user_id, actor_id, type)
  values (new.followed_id, new.follower_id, 'follow');
  return new;
end $$;

drop trigger if exists follows_notify on public.follows;
create trigger follows_notify
  after insert on public.follows
  for each row execute function public.notify_on_follow();

-- ── INDEXES ──────────────────────────────────────────────────
create index if not exists notifications_inbox_idx
  on public.notifications (user_id, read, created_at desc);
create index if not exists comments_plant_idx
  on public.comments (plant_id, created_at desc);
create index if not exists inspires_plant_idx
  on public.inspires (plant_id);
create index if not exists follows_followed_idx
  on public.follows (followed_id);
