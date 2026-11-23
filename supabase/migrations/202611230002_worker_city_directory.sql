alter table public.worker_profiles
  add column if not exists category_id uuid references public.categories(id),
  add column if not exists is_available boolean not null default true;

drop policy if exists "active cities are public" on public.cities;
create policy "active cities are public"
on public.cities for select to anon, authenticated using (is_active = true);

drop policy if exists "active categories are public" on public.categories;
create policy "active categories are public"
on public.categories for select to anon, authenticated using (is_active = true);

drop policy if exists "workers manage their own city links" on public.worker_cities;
create policy "workers manage their own city links"
on public.worker_cities for all to authenticated
using (exists (select 1 from public.worker_profiles wp where wp.id = worker_cities.worker_id and wp.user_id = (select auth.uid())))
with check (exists (select 1 from public.worker_profiles wp where wp.id = worker_cities.worker_id and wp.user_id = (select auth.uid())));

create or replace view public.worker_directory
with (security_invoker = false)
as
select
  wp.user_id,
  p.display_name,
  wp.profession as headline,
  wp.bio,
  c.name as city,
  wp.category_id,
  wp.experience_years as years_experience,
  (wp.identity_verified or wp.documents_verified or wp.field_verified) as is_verified,
  wp.is_available,
  p.avatar_url,
  wp.created_at,
  coalesce(round(avg(r.rating)::numeric, 1), 0) as rating,
  count(r.id)::integer as review_count
from public.worker_profiles wp
join public.profiles p on p.id = wp.user_id
join public.worker_cities wc on wc.worker_id = wp.id
join public.cities c on c.id = wc.city_id
left join public.reviews r on r.worker_id = wp.id
group by
  wp.id, wp.user_id, p.display_name, p.avatar_url, wp.profession, wp.bio,
  c.name, wp.category_id, wp.experience_years, wp.identity_verified,
  wp.documents_verified, wp.field_verified, wp.is_available, wp.created_at;

grant select on public.worker_directory to anon, authenticated;
grant select on public.cities to anon, authenticated;
grant select on public.categories to anon, authenticated;
