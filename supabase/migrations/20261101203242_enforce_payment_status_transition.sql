-- Make payment status updates one-way for regular dealership members.
-- The client UI only marks a pending payment as paid.
DROP POLICY IF EXISTS "members update sale payment status" ON public.sale_payments;
CREATE POLICY "members mark pending payments paid" ON public.sale_payments
  FOR UPDATE TO authenticated
  USING (
    private.is_dealership_member(dealership_id)
    AND status = 'pendiente'
  )
  WITH CHECK (
    private.is_dealership_member(dealership_id)
    AND status = 'pagado'
    AND paid_at IS NOT NULL
  );
