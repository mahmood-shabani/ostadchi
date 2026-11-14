-- Ostadchi initial marketplace schema.
-- Run only after the Supabase project is active and its SMS provider is configured.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text,
  full_name text,
  selected_city text,
  roles text[] not null default array['customer']::text[]
    check (roles <@ array['customer', 'worker']::text[] and cardinality(roles) >= 1),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.service_categories (
  id text primary key,
  title text not null,
  icon_key text not null default 'work',
  parent_id text references public.service_categories(id),
  is_active boolean not null default true,
  sort_order integer not null default 0
);

insert into public.service_categories (id, title, icon_key, sort_order) values
  ('motorcycle', 'تعمیرات موتور', 'two_wheeler', 1),
  ('electrical', 'برق‌کاری', 'electrical_services', 2),
  ('plumbing', 'لوله‌کشی', 'plumbing', 3),
  ('welding', 'جوشکاری', 'handyman', 4),
  ('construction', 'ساختمان', 'home_repair_service', 5),
  ('painting', 'نقاشی', 'format_paint', 6),
  ('cooling', 'سرمایش و گرمایش', 'ac_unit', 7),
  ('other', 'سایر خدمات', 'more_horiz', 8)
on conflict (id) do nothing;

insert into public.service_categories (id, title, icon_key, parent_id, sort_order) values
  ('motorcycle_engine', 'تعمیر موتور و سیلندر', 'build', 'motorcycle', 11),
  ('motorcycle_electrical', 'برق و انژکتور موتورسیکلت', 'bolt', 'motorcycle', 12),
  ('motorcycle_service', 'سرویس و تنظیم موتور', 'settings', 'motorcycle', 13),
  ('electrical_building', 'برق ساختمان', 'electrical_services', 'electrical', 21),
  ('electrical_industrial', 'برق صنعتی', 'factory', 'electrical', 22),
  ('plumbing_water', 'لوله‌کشی آب و فاضلاب', 'water', 'plumbing', 31),
  ('plumbing_heating', 'تأسیسات و پکیج', 'heat', 'plumbing', 32),
  ('welding_structure', 'جوشکاری سازه فلزی', 'construction', 'welding', 41),
  ('construction_tile', 'کاشی و سرامیک', 'grid', 'construction', 51),
  ('construction_masonry', 'بنایی و سیمان‌کاری', 'wall', 'construction', 52)
on conflict (id) do nothing;

create table if not exists public.worker_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  display_name text not null,
  headline text not null default '',
  bio text not null default '',
  city text not null,
  category_id text not null references public.service_categories(id),
  years_experience integer not null default 0 check (years_experience >= 0),
  is_verified boolean not null default false,
  is_available boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.worker_services (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references public.worker_profiles(user_id) on delete cascade,
  category_id text not null references public.service_categories(id),
  description text not null default '',
  price_min numeric(12,2),
  price_max numeric(12,2),
  price_unit text not null default 'توافقی',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (price_min is null or price_min >= 0),
  check (price_max is null or price_max >= 0),
  check (price_min is null or price_max is null or price_max >= price_min)
);

create table if not exists public.portfolio_items (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references public.worker_profiles(user_id) on delete cascade,
  title text not null,
  description text not null default '',
  image_path text,
  created_at timestamptz not null default now()
);

create table if not exists public.work_requests (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  worker_id uuid references public.worker_profiles(user_id) on delete set null,
  title text not null,
  description text not null,
  city text not null,
  category_id text not null references public.service_categories(id),
  budget_min numeric(12,2),
  budget_max numeric(12,2),
  status text not null default 'open'
    check (status in ('open', 'assigned', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (budget_min is null or budget_min >= 0),
  check (budget_max is null or budget_max >= 0),
  check (budget_min is null or budget_max is null or budget_max >= budget_min)
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique references public.work_requests(id) on delete cascade,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  worker_id uuid not null references public.worker_profiles(user_id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  comment text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.contracts (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique references public.work_requests(id) on delete cascade,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  worker_id uuid not null references public.worker_profiles(user_id) on delete cascade,
  terms text not null,
  agreed_price numeric(12,2),
  status text not null default 'draft'
    check (status in ('draft', 'accepted', 'rejected', 'completed', 'cancelled')),
  customer_accepted_at timestamptz,
  worker_accepted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (agreed_price is null or agreed_price >= 0)
);

create table if not exists public.worker_verification_requests (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references public.worker_profiles(user_id) on delete cascade,
  city text not null,
  address_description text not null,
  preferred_time text,
  status text not null default 'pending'
    check (status in ('pending', 'scheduled', 'approved', 'rejected', 'cancelled')),
  reviewer_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace view public.worker_directory
with (security_invoker = true)
as
select
  wp.user_id,
  wp.display_name,
  wp.headline,
  wp.bio,
  wp.city,
  wp.category_id,
  wp.years_experience,
  wp.is_verified,
  wp.is_available,
  wp.created_at,
  coalesce(round(avg(r.rating)::numeric, 1), 0) as rating,
  count(r.id)::integer as review_count
from public.worker_profiles wp
left join public.reviews r on r.worker_id = wp.user_id
group by wp.user_id, wp.created_at;

create index if not exists idx_worker_profiles_city_category
  on public.worker_profiles(city, category_id) where is_available = true;
create index if not exists idx_work_requests_customer_created
  on public.work_requests(customer_id, created_at desc);
create index if not exists idx_work_requests_worker_status
  on public.work_requests(worker_id, status);
create index if not exists idx_worker_services_worker_category
  on public.worker_services(worker_id, category_id);
create index if not exists idx_verification_worker_created
  on public.worker_verification_requests(worker_id, created_at desc);
create index if not exists idx_portfolio_worker_created
  on public.portfolio_items(worker_id, created_at desc);
create index if not exists idx_reviews_worker
  on public.reviews(worker_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.service_categories enable row level security;
alter table public.worker_profiles enable row level security;
alter table public.worker_services enable row level security;
alter table public.portfolio_items enable row level security;
alter table public.work_requests enable row level security;
alter table public.reviews enable row level security;
alter table public.contracts enable row level security;
alter table public.worker_verification_requests enable row level security;

grant select on public.service_categories to anon, authenticated;
grant select on public.worker_profiles to anon, authenticated;
grant select on public.worker_directory to anon, authenticated;
grant select on public.worker_services to anon, authenticated;
grant select, insert, update, delete on public.worker_services to authenticated;
grant select on public.portfolio_items to anon, authenticated;
grant select on public.reviews to anon, authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.worker_profiles to authenticated;
grant select, insert, update, delete on public.portfolio_items to authenticated;
grant select, insert on public.work_requests to authenticated;
grant select, insert on public.reviews to authenticated;
grant select, insert on public.contracts to authenticated;
grant select, insert on public.worker_verification_requests to authenticated;

create policy "active service categories are public"
on public.service_categories for select to anon, authenticated
using (is_active = true);

create policy "worker profiles are public"
on public.worker_profiles for select to anon, authenticated
using (true);

create policy "workers manage their own profile"
on public.worker_profiles for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "workers update their own profile"
on public.worker_profiles for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "worker services are public"
on public.worker_services for select to anon, authenticated
using (true);

create policy "workers manage own services"
on public.worker_services for all to authenticated
using ((select auth.uid()) = worker_id)
with check ((select auth.uid()) = worker_id);

create policy "portfolio is public"
on public.portfolio_items for select to anon, authenticated
using (true);

create policy "workers manage own portfolio"
on public.portfolio_items for all to authenticated
using ((select auth.uid()) = worker_id)
with check ((select auth.uid()) = worker_id);

create policy "users read own profile"
on public.profiles for select to authenticated
using ((select auth.uid()) = id);

create policy "users create own profile"
on public.profiles for insert to authenticated
with check ((select auth.uid()) = id);

create policy "users update own profile"
on public.profiles for update to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create policy "customers and assigned workers read requests"
on public.work_requests for select to authenticated
using (
  (select auth.uid()) = customer_id
  or (select auth.uid()) = worker_id
);

create policy "customers create own requests"
on public.work_requests for insert to authenticated
with check ((select auth.uid()) = customer_id);

create policy "reviews are public"
on public.reviews for select to anon, authenticated
using (true);

create policy "customer reviews own completed request"
on public.reviews for insert to authenticated
with check (
  (select auth.uid()) = customer_id
  and exists (
    select 1 from public.work_requests wr
    where wr.id = request_id
      and wr.customer_id = (select auth.uid())
      and wr.worker_id = reviews.worker_id
      and wr.status = 'completed'
  )
);

create policy "contract parties read contracts"
on public.contracts for select to authenticated
using (
  (select auth.uid()) = customer_id
  or (select auth.uid()) = worker_id
);

create policy "customer creates contract for own request"
on public.contracts for insert to authenticated
with check (
  (select auth.uid()) = customer_id
  and exists (
    select 1 from public.work_requests wr
    where wr.id = request_id
      and wr.customer_id = (select auth.uid())
      and wr.worker_id = contracts.worker_id
  )
);

create policy "workers read own verification requests"
on public.worker_verification_requests for select to authenticated
using ((select auth.uid()) = worker_id);

create policy "workers create own verification requests"
on public.worker_verification_requests for insert to authenticated
with check ((select auth.uid()) = worker_id);


-- Public portfolio images; uploads are restricted to the authenticated owner's folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'portfolio',
  'portfolio',
  true,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

create policy "portfolio images are publicly readable"
on storage.objects for select to anon, authenticated
using (bucket_id = 'portfolio');

create policy "workers upload to their own portfolio folder"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'portfolio'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "workers update their own portfolio images"
on storage.objects for update to authenticated
using (
  bucket_id = 'portfolio'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'portfolio'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "workers delete their own portfolio images"
on storage.objects for delete to authenticated
using (
  bucket_id = 'portfolio'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

-- Payments/wallet are intentionally excluded from this first schema phase.
