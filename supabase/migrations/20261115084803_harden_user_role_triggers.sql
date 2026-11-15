create or replace function public.sync_profile_worker_flag()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
declare
  affected_user_id uuid;
begin
  if tg_op = 'DELETE' then
    affected_user_id := old.user_id;
  else
    affected_user_id := new.user_id;
  end if;

  update public.profiles
  set is_worker = exists (
    select 1 from public.user_roles
    where user_id = affected_user_id
      and role = 'worker'
  ),
  updated_at = now()
  where id = affected_user_id;

  return null;
end;
$function$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.sync_profile_worker_flag() from public, anon, authenticated;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;