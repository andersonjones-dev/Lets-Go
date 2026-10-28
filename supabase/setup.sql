-- Let's Go: database setup.
-- Run this in Supabase → SQL Editor → New query → paste everything → Run.
-- It's safe to run again after an update: it keeps your existing trips.
-- It creates three tables and the rules that keep each trip private to its members.

create table if not exists public.trips (
  id text primary key,
  secret text not null,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.members (
  trip_id text not null references public.trips(id) on delete cascade,
  uid uuid not null,
  joined_at timestamptz not null default now(),
  primary key (trip_id, uid)
);

create table if not exists public.docs (
  path text primary key,
  parent text not null,
  trip_id text not null references public.trips(id) on delete cascade,
  data jsonb not null,
  updated_at timestamptz not null default now()
);
create index if not exists docs_parent_idx on public.docs (parent);
create index if not exists docs_trip_idx on public.docs (trip_id);

alter table public.trips enable row level security;
alter table public.members enable row level security;
alter table public.docs enable row level security;

-- Let signed-in phones use these tables (the rules below still limit them to their own trips).
-- Needed if "Automatically expose new tables" was switched off when the project was created.
grant usage on schema public to authenticated;
grant select, delete on public.trips to authenticated;
grant select on public.members to authenticated;
grant select, insert, update, delete on public.docs to authenticated;

-- Is the signed-in phone a member of this trip?
create or replace function public.is_member(p_trip text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.members where trip_id = p_trip and uid = auth.uid());
$$;

drop policy if exists "members read trips" on public.trips;
drop policy if exists "members delete trips" on public.trips;
drop policy if exists "see own membership" on public.members;
drop policy if exists "members read docs" on public.docs;
drop policy if exists "members add docs" on public.docs;
drop policy if exists "members change docs" on public.docs;
drop policy if exists "members remove docs" on public.docs;

create policy "members read trips" on public.trips for select to authenticated using (public.is_member(id));
create policy "see own membership" on public.members for select to authenticated using (uid = auth.uid());
create policy "members read docs" on public.docs for select to authenticated using (public.is_member(trip_id));
create policy "members add docs" on public.docs for insert to authenticated with check (public.is_member(trip_id));
create policy "members change docs" on public.docs for update to authenticated using (public.is_member(trip_id)) with check (public.is_member(trip_id));
create policy "members remove docs" on public.docs for delete to authenticated using (public.is_member(trip_id));

-- Create a trip, or join one with its invite secret.
create or replace function public.enter_trip(p_trip text, p_secret text)
returns boolean language plpgsql security definer set search_path = public as $$
declare s text;
begin
  if auth.uid() is null or length(coalesce(p_secret, '')) < 12 or length(p_trip) > 64 then
    return false;
  end if;
  insert into public.trips (id, secret, created_by) values (p_trip, p_secret, auth.uid())
    on conflict (id) do nothing;
  select secret into s from public.trips where id = p_trip;
  if s is distinct from p_secret then
    return false;
  end if;
  insert into public.members (trip_id, uid) values (p_trip, auth.uid()) on conflict do nothing;
  return true;
end;
$$;

-- Remove a trip from this phone only. Everyone else keeps it.
-- When the last member leaves, the trip and everything in it is deleted.
create or replace function public.leave_trip(p_trip text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then return false; end if;
  delete from public.members where trip_id = p_trip and uid = auth.uid();
  if not exists (select 1 from public.members where trip_id = p_trip) then
    delete from public.trips where id = p_trip;
  end if;
  return true;
end;
$$;

revoke all on function public.enter_trip(text, text) from public, anon;
grant execute on function public.enter_trip(text, text) to authenticated;
revoke all on function public.leave_trip(text) from public, anon;
grant execute on function public.leave_trip(text) to authenticated;
revoke all on function public.is_member(text) from public, anon;
grant execute on function public.is_member(text) to authenticated;

-- A tiny check-in used by the keep-alive job (.github/workflows/keep-alive.yml),
-- so the free project never pauses from inactivity. It reads no trip data.
create or replace function public.ping()
returns text language sql stable as $$ select 'ok'::text $$;
grant execute on function public.ping() to anon, authenticated;

-- Live updates for the docs table
do $$ begin
  alter publication supabase_realtime add table public.docs;
exception when duplicate_object then null;
end $$;
