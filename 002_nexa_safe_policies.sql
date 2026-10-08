-- NEXA safe permissions patch (002).
-- This migration changes policies only. It does not drop tables or delete user data.
-- Review and run once in Supabase SQL Editor after the existing 001 migration.

begin;

-- Profiles: users can read public profiles and profiles they own.
drop policy if exists "profiles owner" on public.profiles;
drop policy if exists "profiles_read_visible" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "profiles_delete_own" on public.profiles;

create policy "profiles_read_visible" on public.profiles
for select to authenticated
using (
  auth.uid() = id
  or is_private = false
  or exists (
    select 1 from public.follows f
    where f.follower_id = auth.uid()
      and f.following_id = profiles.id
      and f.status = 'accepted'
  )
);

create policy "profiles_insert_own" on public.profiles
for insert to authenticated with check (auth.uid() = id);

create policy "profiles_update_own" on public.profiles
for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

create policy "profiles_delete_own" on public.profiles
for delete to authenticated using (auth.uid() = id);

-- Interactions: users can read counts/like state, create and remove only their own interactions.
drop policy if exists "interactions_read_authenticated" on public.interactions;
drop policy if exists "interactions_insert_own" on public.interactions;
drop policy if exists "interactions_delete_own" on public.interactions;
drop policy if exists "interactions_update_own" on public.interactions;

create policy "interactions_read_authenticated" on public.interactions
for select to authenticated using (true);
create policy "interactions_insert_own" on public.interactions
for insert to authenticated with check (auth.uid() = user_id);
create policy "interactions_delete_own" on public.interactions
for delete to authenticated using (auth.uid() = user_id);
create policy "interactions_update_own" on public.interactions
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Follows: both sides can inspect a relationship; only the follower controls it.
drop policy if exists "follows_read_related" on public.follows;
drop policy if exists "follows_insert_own" on public.follows;
drop policy if exists "follows_delete_own" on public.follows;
drop policy if exists "follows_update_own" on public.follows;

create policy "follows_read_related" on public.follows
for select to authenticated using (auth.uid() = follower_id or auth.uid() = following_id);
create policy "follows_insert_own" on public.follows
for insert to authenticated with check (auth.uid() = follower_id and follower_id <> following_id);
create policy "follows_delete_own" on public.follows
for delete to authenticated using (auth.uid() = follower_id);
create policy "follows_update_own" on public.follows
for update to authenticated using (auth.uid() = follower_id) with check (auth.uid() = follower_id);

-- Recommendation feedback is private to the signed-in user.
drop policy if exists "recommendation_events_owner" on public.recommendation_events;
create policy "recommendation_events_owner" on public.recommendation_events
for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Reports can be created by the reporter; users cannot browse or modify reports.
drop policy if exists "reports_insert_own" on public.reports;
drop policy if exists "reports_no_read" on public.reports;
create policy "reports_insert_own" on public.reports
for insert to authenticated with check (auth.uid() = reporter_id);

commit;
