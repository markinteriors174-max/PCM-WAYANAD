-- ================================================================
--  ADVANCED WORKFLOWS — SUPABASE SQL SCHEMA
--  PCM WAYANAD
--  Covers Tasks 2 & 3:
--    T2: Client hub extensions (email, GSTIN, payment due, discount)
--    T3: Progress tracker, change orders, GPS logs, payment receipts,
--        dynamic UPI QR (served from client_extensions)
-- ================================================================

-- ── 0. CLEAN SLATE ────────────────────────────────────────────────
DROP TABLE IF EXISTS site_visits         CASCADE;
DROP TABLE IF EXISTS payment_receipts    CASCADE;
DROP TABLE IF EXISTS change_orders       CASCADE;
DROP TABLE IF EXISTS project_stages      CASCADE;
DROP TABLE IF EXISTS client_extensions   CASCADE;


-- ================================================================
--  TABLE 1: client_extensions
--  Extends the existing 'clients' table without altering it.
--  One row per project (keyed by unit_number).
-- ================================================================
CREATE TABLE client_extensions (

  unit_number           TEXT        PRIMARY KEY,  -- matches clients.unitNumber

  -- ── PROFILE METADATA ─────────────────────────────────────────
  email                 TEXT,
  customer_type         TEXT        DEFAULT 'Direct Customer'
                        CHECK (customer_type IN (
                          'Direct Customer', 'Builder', 'Architect', 'Interior Designer', 'Other'
                        )),

  -- ── GST ──────────────────────────────────────────────────────
  gstin_enabled         BOOLEAN     NOT NULL DEFAULT FALSE,
  gstin                 TEXT,       -- 15-char GSTIN, only relevant when gstin_enabled = TRUE

  -- ── FINANCIALS ───────────────────────────────────────────────
  next_payment_due_date DATE,
  discount_amount       NUMERIC(12,2) NOT NULL DEFAULT 0,
  discount_note         TEXT,

  -- ── BANK / UPI (for payment link generator + QR code) ────────
  -- These mirror the values from pdf_layout_config but are
  -- stored here so the client portal can read them via anon RLS.
  upi_id                TEXT,
  bank_name             TEXT,
  account_number        TEXT,
  ifsc_code             TEXT,

  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()

);

COMMENT ON TABLE client_extensions IS
  'Per-project extensions for the PCM Wayanad client hub. '
  'Extends the clients table with profile metadata, GST, financial settings, '
  'and bank/UPI details needed for the dynamic QR code and payment link generator.';

CREATE OR REPLACE FUNCTION _trg_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

CREATE TRIGGER trg_client_extensions_updated_at
  BEFORE UPDATE ON client_extensions
  FOR EACH ROW EXECUTE FUNCTION _trg_set_updated_at();

ALTER TABLE client_extensions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "client_extensions__auth_full"
  ON client_extensions FOR ALL TO authenticated
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY "client_extensions__service_full"
  ON client_extensions FOR ALL TO service_role
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY "client_extensions__anon_read"
  ON client_extensions FOR SELECT TO anon
  USING (TRUE);


-- ================================================================
--  TABLE 2: project_stages
--  Granular stage-wise progress per project.
--  Admin sets completion % on mobile → client web portal updates live.
-- ================================================================
CREATE TABLE project_stages (

  id                    UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  unit_number           TEXT        NOT NULL,

  -- Stage name (ordered by typical project flow)
  stage_name            TEXT        NOT NULL
                        CHECK (stage_name IN (
                          'Framing', 'Boarding', 'Finishing', 'Painting', 'Cleanup'
                        )),

  completion_percent    INT         NOT NULL DEFAULT 0
                        CHECK (completion_percent BETWEEN 0 AND 100),

  updated_by            TEXT        NOT NULL DEFAULT 'admin',
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (unit_number, stage_name)   -- one row per stage per project

);

COMMENT ON TABLE project_stages IS
  'Stage-wise completion percentages per project. '
  'Admin updates from mobile app; client portal renders a live progress bar. '
  'Supabase Realtime enabled — client portal auto-refreshes on any change.';

CREATE INDEX idx_project_stages_unit ON project_stages (unit_number);

CREATE TRIGGER trg_project_stages_updated_at
  BEFORE UPDATE ON project_stages
  FOR EACH ROW EXECUTE FUNCTION _trg_set_updated_at();

ALTER TABLE project_stages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "project_stages__auth_full"
  ON project_stages FOR ALL TO authenticated
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY "project_stages__service_full"
  ON project_stages FOR ALL TO service_role
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY "project_stages__anon_read"
  ON project_stages FOR SELECT TO anon USING (TRUE);

-- Enable Realtime so the client web portal receives live pushes
ALTER PUBLICATION supabase_realtime ADD TABLE project_stages;


-- ================================================================
--  TABLE 3: change_orders
--  Mid-project extra work requests.
--  Admin creates → client approves on web → cost locked into contract.
-- ================================================================
CREATE TABLE change_orders (

  id                    UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  unit_number           TEXT        NOT NULL,

  -- Description & cost
  description           TEXT        NOT NULL,
  extra_amount          NUMERIC(12,2) NOT NULL DEFAULT 0,

  -- PDF stored in Supabase Storage bucket 'contracts'
  -- under path: change_orders/{unit_number}_{timestamp}.pdf
  pdf_url               TEXT,

  -- Workflow status
  status                TEXT        NOT NULL DEFAULT 'pending_approval'
                        CHECK (status IN (
                          'pending_approval', 'approved', 'rejected'
                        )),

  -- Client access (same token pattern as contracts table)
  access_token          UUID        DEFAULT gen_random_uuid() UNIQUE NOT NULL,

  -- Timestamps
  client_approved_at    TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()

);

COMMENT ON TABLE change_orders IS
  'Mid-project extra work requests from admin. '
  'Client approves on web portal → status = approved → extra_amount '
  'is added to the total contract amount in the admin mobile hub.';

CREATE INDEX idx_change_orders_unit   ON change_orders (unit_number);
CREATE INDEX idx_change_orders_token  ON change_orders (access_token);
CREATE INDEX idx_change_orders_status ON change_orders (status);

CREATE TRIGGER trg_change_orders_updated_at
  BEFORE UPDATE ON change_orders
  FOR EACH ROW EXECUTE FUNCTION _trg_set_updated_at();

ALTER TABLE change_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "change_orders__auth_full"
  ON change_orders FOR ALL TO authenticated
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY "change_orders__service_full"
  ON change_orders FOR ALL TO service_role
  USING (TRUE) WITH CHECK (TRUE);

-- Client (anon) can read change orders and approve them
CREATE POLICY "change_orders__anon_read"
  ON change_orders FOR SELECT TO anon USING (TRUE);

CREATE POLICY "change_orders__anon_approve"
  ON change_orders FOR UPDATE TO anon
  USING (status = 'pending_approval')
  WITH CHECK (status IN ('approved', 'rejected'));

-- Enable Realtime so admin gets notified when client approves
ALTER PUBLICATION supabase_realtime ADD TABLE change_orders;


-- ================================================================
--  TABLE 4: payment_receipts
--  Auto-generated when admin logs a payment on mobile.
--  Instantly visible on client web portal.
-- ================================================================
CREATE TABLE payment_receipts (

  id                      UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  unit_number             TEXT        NOT NULL,

  -- Receipt details
  receipt_number          TEXT        NOT NULL,  -- e.g. 'PCM-RCP-2026-001'
  amount_received         NUMERIC(12,2) NOT NULL,
  total_paid_to_date      NUMERIC(12,2) NOT NULL,
  balance_remaining       NUMERIC(12,2) NOT NULL,
  payment_date            DATE        NOT NULL DEFAULT CURRENT_DATE,
  payment_mode            TEXT        DEFAULT 'Cash'
                          CHECK (payment_mode IN ('Cash', 'UPI', 'Bank Transfer', 'Cheque', 'Other')),
  notes                   TEXT,

  -- PDF stored in Supabase Storage bucket 'contracts'
  -- under path: receipts/{unit_number}_{timestamp}.pdf
  receipt_pdf_url         TEXT,

  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()

);

COMMENT ON TABLE payment_receipts IS
  'Auto-generated stamped PDF payment receipts. '
  'Created whenever admin updates the total received amount. '
  'Instantly pushed to client portal Payment Receipts history log via Realtime.';

CREATE INDEX idx_payment_receipts_unit ON payment_receipts (unit_number);
CREATE SEQUENCE IF NOT EXISTS receipt_seq START 1;

ALTER TABLE payment_receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "payment_receipts__auth_full"
  ON payment_receipts FOR ALL TO authenticated
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY "payment_receipts__service_full"
  ON payment_receipts FOR ALL TO service_role
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY "payment_receipts__anon_read"
  ON payment_receipts FOR SELECT TO anon USING (TRUE);

-- Enable Realtime so client portal updates immediately
ALTER PUBLICATION supabase_realtime ADD TABLE payment_receipts;


-- ================================================================
--  TABLE 5: site_visits
--  GPS geotagging log — records timestamp + coordinates
--  whenever admin/supervisor interacts with the client hub.
-- ================================================================
CREATE TABLE site_visits (

  id                    UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  unit_number           TEXT        NOT NULL,

  -- Who performed the action
  admin_user            TEXT        NOT NULL DEFAULT 'admin',

  -- Precise GPS coordinates
  latitude              NUMERIC(10, 7),
  longitude             NUMERIC(10, 7),

  -- What action triggered this log entry
  action_type           TEXT        NOT NULL DEFAULT 'manual_checkin'
                        CHECK (action_type IN (
                          'manual_checkin',
                          'stage_update',
                          'photo_upload',
                          'message_sent',
                          'payment_logged',
                          'change_order_sent'
                        )),

  -- Optional extra info (e.g. stage name updated, photo count)
  action_detail         TEXT,

  visited_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()

);

COMMENT ON TABLE site_visits IS
  'Secure GPS geotagging log. Automatically records a row whenever the admin '
  'updates a project stage, uploads a photo, logs a payment, or manually checks in. '
  'Provides audit trail proof of physical site presence.';

CREATE INDEX idx_site_visits_unit ON site_visits (unit_number);
CREATE INDEX idx_site_visits_time ON site_visits (visited_at DESC);

ALTER TABLE site_visits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "site_visits__auth_full"
  ON site_visits FOR ALL TO authenticated
  USING (TRUE) WITH CHECK (TRUE);

CREATE POLICY "site_visits__service_full"
  ON site_visits FOR ALL TO service_role
  USING (TRUE) WITH CHECK (TRUE);

-- Clients can view their site visit log (transparency)
CREATE POLICY "site_visits__anon_read"
  ON site_visits FOR SELECT TO anon USING (TRUE);


-- ================================================================
--  CONVENIENCE VIEWS
-- ================================================================

-- Full project dashboard view for client portal
CREATE OR REPLACE VIEW client_project_dashboard AS
  SELECT
    ce.unit_number,
    ce.email,
    ce.customer_type,
    ce.gstin_enabled,
    ce.gstin,
    ce.next_payment_due_date,
    ce.discount_amount,
    ce.upi_id,
    ce.bank_name,
    ce.account_number,
    ce.ifsc_code,
    -- Latest contract status
    c.contract_status,
    c.signed_pdf_url,
    c.signed_at   AS contract_signed_at,
    c.access_token AS contract_token,
    -- Latest change order
    co.id         AS latest_change_order_id,
    co.description AS change_order_desc,
    co.extra_amount AS change_order_amount,
    co.status     AS change_order_status,
    co.access_token AS change_order_token
  FROM client_extensions ce
  LEFT JOIN contracts c
    ON c.unit_number = ce.unit_number
    AND c.id = (
      SELECT id FROM contracts
      WHERE unit_number = ce.unit_number
      ORDER BY created_at DESC LIMIT 1
    )
  LEFT JOIN change_orders co
    ON co.unit_number = ce.unit_number
    AND co.status = 'pending_approval'
    ORDER BY co.created_at DESC;


-- ================================================================
--  SEED DATA — Default stage rows for existing projects
--  (Admin can update percentages from the mobile app)
-- ================================================================
-- No seed rows since unit_numbers are project-specific.
-- The mobile app creates rows via upsert on first stage update.


-- ================================================================
--  NEXT STEPS
-- ================================================================
--
--  1. Run this script in Supabase SQL Editor
--
--  2. Enable Realtime for these tables in Dashboard → Database → Replication:
--       ✅ project_stages
--       ✅ change_orders
--       ✅ payment_receipts
--       (contracts already enabled in supabase_contract_workflow.sql)
--
--  3. The 'contracts' Storage bucket (created for Task 1) is reused
--     for change_orders PDFs and payment_receipts PDFs:
--       contracts/change_orders/{unit}_{timestamp}.pdf
--       contracts/receipts/{unit}_{timestamp}.pdf
--
--  4. Populate client_extensions.upi_id, bank_name, account_number,
--     ifsc_code from the same values in pdf_layout_config.
--
-- ================================================================
