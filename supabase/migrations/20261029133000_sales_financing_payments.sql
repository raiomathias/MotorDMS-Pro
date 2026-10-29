-- MotorDMS Pro · Ventas, financiamiento y calendario de pagos
-- Aplicado al proyecto Supabase ctillqsactkhwgxhfnoq el 2026-10-29.
alter table public.sales
  add column if not exists platform text,
  add column if not exists seller_name text,
  add column if not exists commission_amount numeric(14,2) not null default 0 check (commission_amount >= 0),
  add column if not exists platform_fee numeric(14,2) not null default 0 check (platform_fee >= 0),
  add column if not exists transfer_cost numeric(14,2) not null default 0 check (transfer_cost >= 0),
  add column if not exists paperwork_cost numeric(14,2) not null default 0 check (paperwork_cost >= 0),
  add column if not exists warranty_cost numeric(14,2) not null default 0 check (warranty_cost >= 0),
  add column if not exists other_costs numeric(14,2) not null default 0 check (other_costs >= 0),
  add column if not exists acquisition_cost_snapshot numeric(14,2) not null default 0 check (acquisition_cost_snapshot >= 0),
  add column if not exists trade_in_value numeric(14,2) not null default 0 check (trade_in_value >= 0),
  add column if not exists payment_method text,
  add column if not exists down_payment numeric(14,2) not null default 0 check (down_payment >= 0),
  add column if not exists financed_amount numeric(14,2) not null default 0 check (financed_amount >= 0),
  add column if not exists annual_interest_rate numeric(7,4) not null default 0 check (annual_interest_rate >= 0 and annual_interest_rate <= 100),
  add column if not exists installment_count integer not null default 0 check (installment_count >= 0 and installment_count <= 600),
  add column if not exists installment_amount numeric(14,2) not null default 0 check (installment_amount >= 0),
  add column if not exists total_interest numeric(14,2) not null default 0 check (total_interest >= 0),
  add column if not exists financing_provider text,
  add column if not exists gross_profit numeric(14,2) not null default 0,
  add column if not exists profit_margin numeric(8,4) not null default 0,
  add column if not exists platform_reference text,
  add column if not exists payment_notes text,
  add column if not exists customer_name text,
  add column if not exists customer_rut text,
  add column if not exists customer_phone text;

create table if not exists public.sale_payments (
  id uuid primary key default gen_random_uuid(),
  dealership_id uuid not null references public.dealerships(id) on delete cascade,
  sale_id uuid not null references public.sales(id) on delete cascade,
  payment_type text not null default 'cuota' check (payment_type in ('pie','cuota','abono','saldo_final','devolucion','otro')),
  payment_method text not null default 'transferencia',
  amount numeric(14,2) not null check (amount > 0),
  due_date date,
  paid_at timestamptz,
  status text not null default 'pendiente' check (status in ('pendiente','pagado','vencido','anulado')),
  reference text,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists sale_payments_dealership_sale_idx on public.sale_payments(dealership_id,sale_id,due_date);
alter table public.sale_payments enable row level security;
drop policy if exists "members manage sale payments" on public.sale_payments;
create policy "members manage sale payments" on public.sale_payments
  for all to authenticated
  using (private.is_dealership_member(dealership_id))
  with check (private.is_dealership_member(dealership_id));
grant select, insert, update, delete on public.sale_payments to authenticated;
