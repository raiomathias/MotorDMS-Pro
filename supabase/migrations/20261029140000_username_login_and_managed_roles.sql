alter table public.profiles
  add column if not exists login_name text,
  add column if not exists system_role text not null default 'vendedor';
alter table public.profiles drop constraint if exists profiles_system_role_check;
alter table public.profiles add constraint profiles_system_role_check check (system_role in ('sysadmin','administrador','vendedor'));
create unique index if not exists profiles_login_name_unique on public.profiles (lower(login_name)) where login_name is not null;
create or replace function private.current_system_role()
returns text language sql stable security definer set search_path = ''
as $$ select p.system_role from public.profiles p where p.user_id = auth.uid() $$;
revoke all on function private.current_system_role() from public, anon;
grant execute on function private.current_system_role() to authenticated;
drop policy if exists profiles_select_own on public.profiles;
drop policy if exists profiles_select_self on public.profiles;
drop policy if exists profiles_read_own on public.profiles;
drop policy if exists profiles_select_authorized on public.profiles;
create policy profiles_select_authorized on public.profiles for select to authenticated
using (user_id = (select auth.uid()) or (select private.current_system_role()) in ('sysadmin','administrador'));
drop policy if exists profiles_insert_own on public.profiles;
drop policy if exists profiles_insert_self on public.profiles;
drop policy if exists profiles_update_own on public.profiles;
drop policy if exists profiles_update_self on public.profiles;
drop policy if exists profiles_update_authorized on public.profiles;
create policy profiles_update_authorized on public.profiles for update to authenticated
using (user_id = (select auth.uid()) or (select private.current_system_role()) in ('sysadmin','administrador'))
with check (user_id = (select auth.uid()) or (select private.current_system_role()) in ('sysadmin','administrador'));
revoke insert, update on public.profiles from authenticated;
grant select on public.profiles to authenticated;
grant update (full_name) on public.profiles to authenticated;
create or replace function public.create_managed_user(p_full_name text,p_password text,p_role text)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare
  v_actor_role text;
  v_full_name text := btrim(coalesce(p_full_name,''));
  v_login text;
  v_email text;
  v_user_id uuid := gen_random_uuid();
  v_dealership_id uuid;
  v_role text := lower(btrim(coalesce(p_role,'')));
begin
  if auth.uid() is null then raise exception 'Debes iniciar sesión.'; end if;
  select p.system_role into v_actor_role from public.profiles p where p.user_id = auth.uid();
  if v_actor_role not in ('sysadmin','administrador') then raise exception 'No tienes permisos para crear cuentas.'; end if;
  if v_role not in ('administrador','vendedor') then raise exception 'Solo sysadmin puede asignar permisos sysadmin.'; end if;
  if length(v_full_name)<3 or length(v_full_name)>120 or array_length(regexp_split_to_array(v_full_name, '\s+'),1)<2 then raise exception 'Ingresa nombre y apellido.'; end if;
  if length(coalesce(p_password,''))<8 then raise exception 'La contraseña debe tener al menos 8 caracteres.'; end if;
  v_login := trim(both '.' from regexp_replace(lower(translate(v_full_name,'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN')),'[^a-zA-Z0-9]+','.','g'));
  if v_login='' then raise exception 'No se pudo generar el usuario.'; end if;
  v_email := v_login || '@users.autogest.local';
  if exists(select 1 from public.profiles where lower(login_name)=lower(v_login)) or exists(select 1 from auth.users where lower(email)=lower(v_email)) then raise exception 'Ya existe una cuenta con ese nombre. Añade un segundo nombre o apellido para distinguirla.'; end if;
  select dm.dealership_id into v_dealership_id from public.dealership_members dm where dm.user_id=auth.uid() order by dm.created_at asc limit 1;
  if v_dealership_id is null then raise exception 'Tu cuenta no está asociada a una automotora.'; end if;
  insert into auth.users(instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at,confirmation_token,email_change,email_change_token_new,recovery_token)
  values('00000000-0000-0000-0000-000000000000',v_user_id,'authenticated','authenticated',v_email,extensions.crypt(p_password,extensions.gen_salt('bf')),now(),jsonb_build_object('provider','email','providers',jsonb_build_array('email')),jsonb_build_object('full_name',v_full_name,'login_name',v_login),now(),now(),'','','','');
  insert into auth.identities(provider_id,user_id,identity_data,provider,last_sign_in_at,created_at,updated_at,id)
  values(v_user_id::text,v_user_id,jsonb_build_object('sub',v_user_id::text,'email',v_email,'email_verified',true),'email',null,now(),now(),gen_random_uuid());
  insert into public.profiles(user_id,full_name,login_name,system_role) values(v_user_id,v_full_name,v_login,v_role);
  insert into public.dealership_members(dealership_id,user_id,role) values(v_dealership_id,v_user_id,case when v_role='administrador' then 'administrador'::public.member_role else 'vendedor'::public.member_role end);
  return v_user_id;
end;
$$;
revoke all on function public.create_managed_user(text,text,text) from public, anon;
grant execute on function public.create_managed_user(text,text,text) to authenticated;
