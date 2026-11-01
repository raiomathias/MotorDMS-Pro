-- MotorDMS Pro security hardening (2026-11-01)
-- Keep the publishable API key usable while removing privileges that bypass RLS.

-- Anonymous clients have no intended public data access in this application.
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM anon;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM anon;

-- TRUNCATE, REFERENCES and TRIGGER are not protected by row-level security.
-- Authenticated users retain ordinary DML, still subject to the existing RLS policies.
REVOKE TRUNCATE, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA public FROM authenticated;

-- Remove the default PUBLIC/anon execute surface. Re-grant only the RPCs used by
-- the client application. Trigger functions do not need client EXECUTE grants.
REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_managed_user(text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_dealership_for_current_user(text, text, text, text, text, text, text) TO authenticated;

-- Prevent future public-schema objects from silently inheriting anonymous access.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL PRIVILEGES ON TABLES FROM anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL PRIVILEGES ON SEQUENCES FROM anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon;

-- Scope administrator profile visibility to the same dealership. Sysadmin remains
-- global; users can always read their own profile.
DROP POLICY IF EXISTS profiles_select_authorized ON public.profiles;
CREATE POLICY profiles_select_authorized ON public.profiles
FOR SELECT TO authenticated
USING (
  user_id = (SELECT auth.uid())
  OR (SELECT private.current_system_role()) = 'sysadmin'
  OR (
    (SELECT private.current_system_role()) = 'administrador'
    AND EXISTS (
      SELECT 1
      FROM public.dealership_members actor
      JOIN public.dealership_members target
        ON target.dealership_id = actor.dealership_id
      WHERE actor.user_id = (SELECT auth.uid())
        AND actor.role IN ('propietario', 'administrador')
        AND target.user_id = profiles.user_id
    )
  )
);

DROP POLICY IF EXISTS profiles_update_authorized ON public.profiles;
CREATE POLICY profiles_update_authorized ON public.profiles
FOR UPDATE TO authenticated
USING (
  user_id = (SELECT auth.uid())
  OR (SELECT private.current_system_role()) = 'sysadmin'
  OR (
    (SELECT private.current_system_role()) = 'administrador'
    AND EXISTS (
      SELECT 1
      FROM public.dealership_members actor
      JOIN public.dealership_members target
        ON target.dealership_id = actor.dealership_id
      WHERE actor.user_id = (SELECT auth.uid())
        AND actor.role IN ('propietario', 'administrador')
        AND target.user_id = profiles.user_id
    )
  )
)
WITH CHECK (
  user_id = (SELECT auth.uid())
  OR (SELECT private.current_system_role()) = 'sysadmin'
  OR (
    (SELECT private.current_system_role()) = 'administrador'
    AND EXISTS (
      SELECT 1
      FROM public.dealership_members actor
      JOIN public.dealership_members target
        ON target.dealership_id = actor.dealership_id
      WHERE actor.user_id = (SELECT auth.uid())
        AND actor.role IN ('propietario', 'administrador')
        AND target.user_id = profiles.user_id
    )
  )
);

-- Composite foreign keys make tenant ownership part of referential integrity.
-- Existing rows were checked before applying: zero cross-dealership references.
CREATE UNIQUE INDEX IF NOT EXISTS vehicles_id_dealership_uidx
  ON public.vehicles(id, dealership_id);
CREATE UNIQUE INDEX IF NOT EXISTS customers_id_dealership_uidx
  ON public.customers(id, dealership_id);
CREATE UNIQUE INDEX IF NOT EXISTS sales_id_dealership_uidx
  ON public.sales(id, dealership_id);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sales_vehicle_same_dealership_fk') THEN
    ALTER TABLE public.sales
      ADD CONSTRAINT sales_vehicle_same_dealership_fk
      FOREIGN KEY (vehicle_id, dealership_id)
      REFERENCES public.vehicles(id, dealership_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sales_customer_same_dealership_fk') THEN
    ALTER TABLE public.sales
      ADD CONSTRAINT sales_customer_same_dealership_fk
      FOREIGN KEY (customer_id, dealership_id)
      REFERENCES public.customers(id, dealership_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sale_payments_sale_same_dealership_fk') THEN
    ALTER TABLE public.sale_payments
      ADD CONSTRAINT sale_payments_sale_same_dealership_fk
      FOREIGN KEY (sale_id, dealership_id)
      REFERENCES public.sales(id, dealership_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'vehicle_expenses_vehicle_same_dealership_fk') THEN
    ALTER TABLE public.vehicle_expenses
      ADD CONSTRAINT vehicle_expenses_vehicle_same_dealership_fk
      FOREIGN KEY (vehicle_id, dealership_id)
      REFERENCES public.vehicles(id, dealership_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'leads_customer_same_dealership_fk') THEN
    ALTER TABLE public.leads
      ADD CONSTRAINT leads_customer_same_dealership_fk
      FOREIGN KEY (customer_id, dealership_id)
      REFERENCES public.customers(id, dealership_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'leads_vehicle_same_dealership_fk') THEN
    ALTER TABLE public.leads
      ADD CONSTRAINT leads_vehicle_same_dealership_fk
      FOREIGN KEY (interested_vehicle_id, dealership_id)
      REFERENCES public.vehicles(id, dealership_id);
  END IF;
END $$;
