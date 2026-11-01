-- Restrict destructive/financial changes to dealership managers.
DROP POLICY IF EXISTS "members manage sales" ON public.sales;
CREATE POLICY "members read sales" ON public.sales
  FOR SELECT TO authenticated
  USING (private.is_dealership_member(dealership_id));
CREATE POLICY "members insert sales" ON public.sales
  FOR INSERT TO authenticated
  WITH CHECK (
    private.is_dealership_member(dealership_id)
    AND created_by = (SELECT auth.uid())
  );
CREATE POLICY "managers update sales" ON public.sales
  FOR UPDATE TO authenticated
  USING (private.is_dealership_manager(dealership_id))
  WITH CHECK (private.is_dealership_manager(dealership_id));
CREATE POLICY "managers delete sales" ON public.sales
  FOR DELETE TO authenticated
  USING (private.is_dealership_manager(dealership_id));

DROP POLICY IF EXISTS "members manage sale payments" ON public.sale_payments;
CREATE POLICY "members read sale payments" ON public.sale_payments
  FOR SELECT TO authenticated
  USING (private.is_dealership_member(dealership_id));
CREATE POLICY "members insert pending sale payments" ON public.sale_payments
  FOR INSERT TO authenticated
  WITH CHECK (
    private.is_dealership_member(dealership_id)
    AND created_by = (SELECT auth.uid())
    AND status = 'pendiente'
  );
CREATE POLICY "members update sale payment status" ON public.sale_payments
  FOR UPDATE TO authenticated
  USING (private.is_dealership_member(dealership_id))
  WITH CHECK (private.is_dealership_member(dealership_id));
CREATE POLICY "managers delete sale payments" ON public.sale_payments
  FOR DELETE TO authenticated
  USING (private.is_dealership_manager(dealership_id));

-- The UI only updates payment status/date when marking a scheduled payment paid.
-- Prevent changing the amount, sale, tenant, method, reference or notes through REST.
REVOKE UPDATE ON public.sale_payments FROM authenticated;
GRANT UPDATE (status, paid_at, updated_at) ON public.sale_payments TO authenticated;
