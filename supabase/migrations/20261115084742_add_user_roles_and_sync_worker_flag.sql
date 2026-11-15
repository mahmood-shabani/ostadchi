create table if not exists public.user_roles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('customer', 'worker')),
  created_at timestamptz not null default now(),
  primary key (user_id, role)
);

alter table public.user_roles enable row level security;

grant select, insert on public.user_roles to authenticated;

drop policy if exists "users can read their own roles" on public.user_roles;
create policy "users can read their own roles"
  on public.user_roles for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "users can add roles to themselves" on public.user_roles;
create policy "users can add roles to themselves"
  on public.user_roles for insert to authenticated
  with check ((select auth.uid()) = user_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
begin
  insert into public.profiles (id, phone)
  values (new.id, new.phone)
  on conflict (id) do update
    set phone = excluded.phone, updated_at = now();

  insert into public.user_roles (user_id, role)
  values (new.id, 'customer')
  on conflict (user_id, role) do nothing;

  return new;
end;
$function$;

create or replace function public.sync_profile_worker_flag()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
begin
  update public.profiles
  set is_worker = exists (
    select 1 from public.user_roles
    where user_id = coalesce(new.user_id, old.user_id)
      and role = 'worker'
  ),
  updated_at = now()
  where id = coalesce(new.user_id, old.user_id);

  return coalesce(new, old);
end;
$function$;

drop trigger if exists user_roles_sync_worker_flag on public.user_roles;
create trigger user_roles_sync_worker_flag
after insert or delete on public.user_roles
for each row execute function public.sync_profile_worker_flag();