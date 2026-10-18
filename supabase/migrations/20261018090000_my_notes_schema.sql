create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default 'Note maker' check (char_length(display_name) between 1 and 80),
  avatar_url text,
  leaderboard_public boolean not null default false,
  preferences jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.folders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 40),
  color text not null default '#EAE1F6',
  icon text not null default 'folder',
  created_at timestamptz not null default now(),
  unique (id, user_id)
);

create unique index if not exists folders_user_name_ci_idx
  on public.folders (user_id, lower(name));

create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  folder_id uuid references public.folders (id) on delete set null,
  title text not null default '',
  content text not null default '',
  color text not null default '#F3EAF7',
  tags text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists notes_user_updated_idx
  on public.notes (user_id, updated_at desc);
create index if not exists notes_user_created_idx
  on public.notes (user_id, created_at desc);
create index if not exists notes_folder_idx
  on public.notes (user_id, folder_id, updated_at desc);

create table if not exists public.writing_activity (
  user_id uuid not null references auth.users (id) on delete cascade,
  activity_date date not null,
  qualifying_notes integer not null default 0 check (qualifying_notes >= 0),
  primary key (user_id, activity_date)
);

create table if not exists public.ranking_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  event_key text not null,
  points integer not null check (points > 0),
  occurred_at timestamptz not null default now(),
  unique (user_id, event_key)
);

create index if not exists ranking_events_user_time_idx
  on public.ranking_events (user_id, occurred_at desc);

create or replace function public.create_my_notes_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text;
begin
  v_name := coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
    split_part(new.email, '@', 1),
    'Note maker'
  );

  insert into public.profiles (id, display_name)
  values (new.id, left(v_name, 80))
  on conflict (id) do nothing;

  insert into public.folders (user_id, name, color, icon)
  values
    (new.id, 'Study', '#E8E2F4', 'school'),
    (new.id, 'Personal', '#F5E3E8', 'favorite'),
    (new.id, 'Work', '#DDEEE7', 'work'),
    (new.id, 'Ideas', '#F7E9D8', 'lightbulb'),
    (new.id, 'Others', '#F5EFCF', 'more_horiz')
  on conflict do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_my_notes on auth.users;
create trigger on_auth_user_created_my_notes
after insert on auth.users
for each row execute function public.create_my_notes_profile();

insert into public.profiles (id, display_name)
select
  u.id,
  left(coalesce(
    nullif(trim(u.raw_user_meta_data ->> 'display_name'), ''),
    nullif(trim(u.raw_user_meta_data ->> 'name'), ''),
    split_part(u.email, '@', 1),
    'Note maker'
  ), 80)
from auth.users as u
on conflict (id) do nothing;

insert into public.folders (user_id, name, color, icon)
select p.id, defaults.name, defaults.color, defaults.icon
from public.profiles as p
cross join (values
  ('Study', '#E8E2F4', 'school'),
  ('Personal', '#F5E3E8', 'favorite'),
  ('Work', '#DDEEE7', 'work'),
  ('Ideas', '#F7E9D8', 'lightbulb'),
  ('Others', '#F5EFCF', 'more_horiz')
) as defaults(name, color, icon)
on conflict do nothing;

create or replace function public.prepare_note_write()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' then
    new.updated_at := now();
    if new.user_id <> old.user_id then
      raise exception 'A note cannot be transferred to another account';
    end if;
  end if;

  if new.folder_id is not null and not exists (
    select 1 from public.folders f
    where f.id = new.folder_id and f.user_id = new.user_id
  ) then
    raise exception 'Folder does not belong to this account';
  end if;

  return new;
end;
$$;

drop trigger if exists prepare_note_write on public.notes;
create trigger prepare_note_write
before insert or update on public.notes
for each row execute function public.prepare_note_write();

create or replace function public.record_note_activity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_words integer;
  v_today date;
  v_daily_count integer;
begin
  v_words := case
    when trim(coalesce(new.title, '') || ' ' || coalesce(new.content, '')) = '' then 0
    else cardinality(regexp_split_to_array(
      trim(regexp_replace(coalesce(new.title, '') || ' ' || coalesce(new.content, ''), '\s+', ' ', 'g')),
      ' '
    ))
  end;

  if v_words < 5 then
    return new;
  end if;

  v_today := (now() at time zone 'UTC')::date;
  perform pg_advisory_xact_lock(hashtextextended(new.user_id::text, 0));

  select count(*)::integer into v_daily_count
  from public.ranking_events e
  where e.user_id = new.user_id
    and e.event_key like 'note:%'
    and e.occurred_at >= (v_today::timestamp at time zone 'UTC')
    and e.occurred_at < ((v_today + 1)::timestamp at time zone 'UTC');

  if v_daily_count < 3 then
    insert into public.ranking_events (user_id, event_key, points)
    values (new.user_id, 'note:' || new.id::text, 10)
    on conflict (user_id, event_key) do nothing;

    if found then
      insert into public.writing_activity (user_id, activity_date, qualifying_notes)
      values (new.user_id, v_today, 1)
      on conflict (user_id, activity_date) do update
      set qualifying_notes = public.writing_activity.qualifying_notes + 1;
    end if;
  end if;

  insert into public.ranking_events (user_id, event_key, points)
  values (new.user_id, 'daily:' || v_today::text, 2)
  on conflict (user_id, event_key) do nothing;

  return new;
end;
$$;

drop trigger if exists record_note_activity on public.notes;
create trigger record_note_activity
after insert or update of title, content on public.notes
for each row execute function public.record_note_activity();

create or replace function public.get_leaderboard(p_period text, p_limit integer default 100)
returns table (
  user_id uuid,
  display_name text,
  avatar_url text,
  score bigint,
  position integer,
  is_current_user boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_start timestamptz;
  v_end timestamptz;
  v_utc timestamp;
  v_limit integer := greatest(1, least(coalesce(p_limit, 100), 100));
begin
  if auth.uid() is null then
    raise exception 'Authentication is required';
  end if;

  v_utc := now() at time zone 'UTC';
  case lower(p_period)
    when 'daily' then
      v_start := date_trunc('day', v_utc) at time zone 'UTC';
      v_end := (date_trunc('day', v_utc) + interval '1 day') at time zone 'UTC';
    when 'weekly' then
      v_start := date_trunc('week', v_utc) at time zone 'UTC';
      v_end := (date_trunc('week', v_utc) + interval '1 week') at time zone 'UTC';
    when 'monthly' then
      v_start := date_trunc('month', v_utc) at time zone 'UTC';
      v_end := (date_trunc('month', v_utc) + interval '1 month') at time zone 'UTC';
    when 'yearly' then
      v_start := date_trunc('year', v_utc) at time zone 'UTC';
      v_end := (date_trunc('year', v_utc) + interval '1 year') at time zone 'UTC';
    when 'all_time' then
      v_start := null;
      v_end := null;
    else
      raise exception 'Unsupported ranking period';
  end case;

  return query
  with totals as (
    select e.user_id, sum(e.points)::bigint as total_points
    from public.ranking_events e
    where (v_start is null or e.occurred_at >= v_start)
      and (v_end is null or e.occurred_at < v_end)
    group by e.user_id
  ), ranked as (
    select
      t.user_id,
      p.display_name,
      p.avatar_url,
      t.total_points,
      row_number() over (order by t.total_points desc, p.display_name asc)::integer as rank_number
    from totals t
    join public.profiles p on p.id = t.user_id
    where p.leaderboard_public
  )
  select
    r.user_id,
    r.display_name,
    r.avatar_url,
    r.total_points,
    r.rank_number,
    r.user_id = auth.uid()
  from ranked r
  where r.rank_number <= v_limit or r.user_id = auth.uid()
  order by r.rank_number;
end;
$$;

alter table public.profiles enable row level security;
alter table public.folders enable row level security;
alter table public.notes enable row level security;
alter table public.writing_activity enable row level security;
alter table public.ranking_events enable row level security;

create policy "Profiles are private to their owner"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()));
create policy "Users update their own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy "Users read their folders"
  on public.folders for select to authenticated
  using (user_id = (select auth.uid()));
create policy "Users create their folders"
  on public.folders for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "Users update their folders"
  on public.folders for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "Users delete their folders"
  on public.folders for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "Users read their notes"
  on public.notes for select to authenticated
  using (user_id = (select auth.uid()));
create policy "Users create their notes"
  on public.notes for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "Users update their notes"
  on public.notes for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "Users delete their notes"
  on public.notes for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "Users read their own writing activity"
  on public.writing_activity for select to authenticated
  using (user_id = (select auth.uid()));

revoke all on public.ranking_events from anon, authenticated;
revoke insert, update, delete on public.writing_activity from anon, authenticated;
revoke all on function public.create_my_notes_profile() from public, anon, authenticated;
revoke all on function public.prepare_note_write() from public, anon, authenticated;
revoke all on function public.record_note_activity() from public, anon, authenticated;
revoke all on function public.get_leaderboard(text, integer) from public, anon;
grant execute on function public.get_leaderboard(text, integer) to authenticated;

 grant select, insert, update, delete on public.folders, public.notes to authenticated;
grant select, update on public.profiles to authenticated;
grant select on public.writing_activity to authenticated;
