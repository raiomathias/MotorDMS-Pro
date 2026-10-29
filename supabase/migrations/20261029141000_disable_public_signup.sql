drop policy if exists "users insert own profile" on public.profiles;
drop policy if exists "users read own profile" on public.profiles;
drop policy if exists "users update own profile" on public.profiles;
drop function if exists public.lookup_login_email(text);
create or replace function private.block_public_auth_signup()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if current_user = 'supabase_auth_admin' then
    raise exception 'El registro público está deshabilitado. Solicita una cuenta al administrador.';
  end if;
  return new;
end;
$$;
revoke all on function private.block_public_auth_signup() from public, anon, authenticated;
drop trigger if exists block_public_auth_signup on auth.users;
create trigger block_public_auth_signup before insert on auth.users for each row execute function private.block_public_auth_signup();
