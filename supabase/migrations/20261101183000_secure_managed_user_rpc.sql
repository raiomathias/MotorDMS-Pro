-- Reject authenticated callers whose profile/role is missing before privileged account creation.
CREATE OR REPLACE FUNCTION public.create_managed_user(
  p_full_name text,
  p_password text,
  p_role text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_actor_role text;
  v_full_name text := btrim(coalesce(p_full_name, ''));
  v_login text;
  v_email text;
  v_user_id uuid := gen_random_uuid();
  v_dealership_id uuid;
  v_role text := lower(btrim(coalesce(p_role, '')));
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Debes iniciar sesión.' USING ERRCODE = '42501';
  END IF;

  SELECT coalesce(p.system_role, '')
    INTO v_actor_role
    FROM public.profiles p
   WHERE p.user_id = auth.uid();

  IF coalesce(v_actor_role, '') NOT IN ('sysadmin', 'administrador') THEN
    RAISE EXCEPTION 'No tienes permisos para crear cuentas.' USING ERRCODE = '42501';
  END IF;

  IF v_role NOT IN ('administrador', 'vendedor') THEN
    RAISE EXCEPTION 'Solo se pueden crear cuentas de administrador o vendedor.' USING ERRCODE = '22023';
  END IF;

  IF length(v_full_name) < 3
     OR length(v_full_name) > 120
     OR array_length(regexp_split_to_array(v_full_name, '\s+'), 1) < 2 THEN
    RAISE EXCEPTION 'Ingresa nombre y apellido.' USING ERRCODE = '22023';
  END IF;

  IF length(coalesce(p_password, '')) < 12 THEN
    RAISE EXCEPTION 'La contraseña debe tener al menos 12 caracteres.' USING ERRCODE = '22023';
  END IF;

  v_login := trim(both '.' FROM regexp_replace(
    lower(translate(v_full_name, 'áéíóúüñÁÉÍÓÚÜÑ', 'aeiouunAEIOUUN')),
    '[^a-zA-Z0-9]+', '.', 'g'
  ));

  IF v_login = '' THEN
    RAISE EXCEPTION 'No se pudo generar el usuario.' USING ERRCODE = '22023';
  END IF;

  v_email := v_login || '@users.autogest.local';

  IF EXISTS (SELECT 1 FROM public.profiles WHERE lower(login_name) = lower(v_login))
     OR EXISTS (SELECT 1 FROM auth.users WHERE lower(email) = lower(v_email)) THEN
    RAISE EXCEPTION 'Ya existe una cuenta con ese nombre. Añade un segundo nombre o apellido para distinguirla.'
      USING ERRCODE = '23505';
  END IF;

  IF v_actor_role = 'administrador' THEN
    SELECT dm.dealership_id
      INTO v_dealership_id
      FROM public.dealership_members dm
     WHERE dm.user_id = auth.uid()
       AND dm.role IN ('propietario', 'administrador')
     ORDER BY dm.created_at ASC
     LIMIT 1;

    IF v_dealership_id IS NULL THEN
      RAISE EXCEPTION 'Tu cuenta no tiene permisos administrativos en una automotora.'
        USING ERRCODE = '42501';
    END IF;
  ELSE
    SELECT dm.dealership_id
      INTO v_dealership_id
      FROM public.dealership_members dm
     WHERE dm.user_id = auth.uid()
     ORDER BY dm.created_at ASC
     LIMIT 1;
  END IF;

  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, email_change, email_change_token_new, recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    v_user_id,
    'authenticated',
    'authenticated',
    v_email,
    extensions.crypt(p_password, extensions.gen_salt('bf')),
    now(),
    jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
    jsonb_build_object('full_name', v_full_name, 'login_name', v_login),
    now(),
    now(),
    '',
    '',
    '',
    ''
  );

  INSERT INTO auth.identities (
    provider_id, user_id, identity_data, provider, last_sign_in_at,
    created_at, updated_at, id
  ) VALUES (
    v_user_id::text,
    v_user_id,
    jsonb_build_object('sub', v_user_id::text, 'email', v_email, 'email_verified', true),
    'email',
    NULL,
    now(),
    now(),
    gen_random_uuid()
  );

  INSERT INTO public.profiles(user_id, full_name, login_name, system_role)
  VALUES (v_user_id, v_full_name, v_login, v_role);

  IF v_dealership_id IS NOT NULL THEN
    INSERT INTO public.dealership_members(dealership_id, user_id, role)
    VALUES (
      v_dealership_id,
      v_user_id,
      CASE WHEN v_role = 'administrador'
        THEN 'administrador'::public.member_role
        ELSE 'vendedor'::public.member_role
      END
    );
  END IF;

  RETURN v_user_id;
END;
$function$;

REVOKE ALL ON FUNCTION public.create_managed_user(text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_managed_user(text, text, text) TO authenticated;
