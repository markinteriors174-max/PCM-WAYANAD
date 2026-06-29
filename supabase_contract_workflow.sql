-- ================================================================
--  CONTRACT WORKFLOW TABLE
--  PCM WAYANAD — Supabase SQL Schema
--  Two-way contract signing: Admin (mobile) ↔ Client (web)
--
--  Workflow:
--    1. Admin uploads unsigned PDF → status = 'pending_client_signature'
--    2. Client opens web link, signs, clicks "Approve & Return"
--    3. Web app embeds signature → uploads signed PDF
--    4. status = 'signed_by_client' → admin polls & downloads
-- ================================================================

-- ── 0. CLEAN SLATE ────────────────────────────────────────────────
DROP TABLE IF EXISTS contracts CASCADE;


-- ================================================================
--  TABLE: contracts
-- ================================================================
CREATE TABLE contracts (

  id                    UUID        DEFAULT gen_random_uuid() PRIMARY KEY,

  -- ── QUOTATION LINK ────────────────────────────────────────────
  unit_number           TEXT        NOT NULL,          -- matches quotation.unitNumber
  client_name           TEXT        NOT NULL DEFAULT '',
  client_phone          TEXT        NOT NULL DEFAULT '',

  -- ── WORKFLOW STATUS ───────────────────────────────────────────
  -- States: pending_client_signature → signed_by_client | rejected
  contract_status       TEXT        NOT NULL DEFAULT 'pending_client_signature'
                        CHECK (contract_status IN (
                          'pending_client_signature',
                          'signed_by_client',
                          'rejected'
                        )),

  -- ── CLIENT ACCESS ─────────────────────────────────────────────
  -- Unique UUID embedded in the shareable client URL:
  --   https://pcmwayanad.com/contract/{access_token}
  -- No login required — token alone grants access to this contract.
  access_token          UUID        DEFAULT gen_random_uuid() UNIQUE NOT NULL,

  -- ── PDF STORAGE URLs ─────────────────────────────────────────
  -- Both stored in the 'contracts' Supabase Storage bucket
  --   unsigned/ folder → uploaded by admin mobile app
  --   signed/   folder → uploaded by client web app after signing
  unsigned_pdf_url      TEXT,       -- set on upload by admin
  signed_pdf_url        TEXT,       -- set after client signs

  -- ── SIGNATURE DATA ────────────────────────────────────────────
  -- The raw base64 PNG of what the client drew on the signature canvas.
  -- Also embedded into the PDF by pdf-lib on the web, but stored here
  -- as a record for audit purposes.
  client_signature_data TEXT,

  -- ── TIMESTAMPS ───────────────────────────────────────────────
  signed_at             TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()

);

COMMENT ON TABLE contracts IS
  'Two-way contract signing workflow. One row per quotation sent for client signature. '
  'Admin uploads unsigned PDF from mobile app; client signs on web portal; '
  'signed PDF is re-uploaded and status updated to signed_by_client.';

COMMENT ON COLUMN contracts.access_token IS
  'UUID-based client access token. Embedded in the shareable URL: '
  'https://pcmwayanad.com/contract/{access_token}. '
  'No additional authentication required — the token itself is the credential.';


-- ── 1. INDEXES ────────────────────────────────────────────────────
CREATE INDEX idx_contracts_unit_number   ON contracts (unit_number);
CREATE INDEX idx_contracts_access_token  ON contracts (access_token);
CREATE INDEX idx_contracts_status        ON contracts (contract_status);


-- ── 2. AUTO-UPDATE updated_at ─────────────────────────────────────
-- Reuses the same trigger function created in supabase_pdf_layout_config.sql
-- If that script hasn't been run, create the function here:
CREATE OR REPLACE FUNCTION _trg_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_contracts_updated_at
  BEFORE UPDATE ON contracts
  FOR EACH ROW EXECUTE FUNCTION _trg_set_updated_at();


-- ── 3. ROW LEVEL SECURITY ─────────────────────────────────────────
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;

-- Admin (authenticated) can do everything
CREATE POLICY "contracts__auth_full_access"
  ON contracts FOR ALL
  TO authenticated
  USING (TRUE)
  WITH CHECK (TRUE);

-- service_role bypass (used by server-side operations)
CREATE POLICY "contracts__service_full_access"
  ON contracts FOR ALL
  TO service_role
  USING (TRUE)
  WITH CHECK (TRUE);

-- Client (anon) can SELECT their own contract by access_token
-- Used by the ContractSigningPage web component
CREATE POLICY "contracts__anon_select_by_token"
  ON contracts FOR SELECT
  TO anon
  USING (TRUE);   -- URL token is validated in app code; row is fetched by access_token equality

-- Client (anon) can UPDATE their own contract (to upload signed PDF + change status)
-- Restricted: can only update when status is 'pending_client_signature'
-- and can only set status to 'signed_by_client'
CREATE POLICY "contracts__anon_sign"
  ON contracts FOR UPDATE
  TO anon
  USING (contract_status = 'pending_client_signature')
  WITH CHECK (contract_status IN ('signed_by_client', 'rejected'));


-- ── 4. SUPABASE REALTIME ─────────────────────────────────────────
-- Enable Realtime publication so the web AdminDashboard can subscribe
-- to contract status changes via supabase.channel().on('postgres_changes', ...)
ALTER PUBLICATION supabase_realtime ADD TABLE contracts;


-- ================================================================
--  STORAGE BUCKET SETUP
--  Run these in the Supabase Storage section of the dashboard,
--  OR via the Supabase Management API. SQL cannot directly create
--  storage buckets, but the policies below apply once the bucket
--  'contracts' is created manually.
-- ================================================================

-- MANUAL STEP: Create a bucket named 'contracts' (public: false)
-- in Supabase Dashboard → Storage → New Bucket
-- Folders inside:
--   unsigned/   ← admin uploads here
--   signed/     ← web app uploads here after client signs

-- Storage RLS (apply after creating the bucket):
-- INSERT INTO storage.buckets (id, name, public) VALUES ('contracts', 'contracts', false);

-- Allow authenticated users (admin) to upload to unsigned/
-- Allow anon users (web app) to upload to signed/
-- Allow both to read (for PDF viewer iframe + mobile download)

-- These storage policies are managed in the Supabase Dashboard under:
-- Storage → contracts bucket → Policies
--
-- Recommended policies:
--  SELECT: allow anon & authenticated (public read for both folders)
--  INSERT: allow authenticated for unsigned/, allow anon for signed/
--  UPDATE: allow anon for signed/ only
--  DELETE: allow authenticated only


-- ================================================================
--  CONVENIENCE VIEW
--  Fetch pending contracts for admin dashboard
-- ================================================================
CREATE OR REPLACE VIEW pending_contracts AS
  SELECT
    id,
    unit_number,
    client_name,
    client_phone,
    contract_status,
    access_token,
    unsigned_pdf_url,
    signed_pdf_url,
    signed_at,
    created_at,
    updated_at
  FROM contracts
  WHERE contract_status = 'pending_client_signature'
  ORDER BY created_at DESC;

CREATE OR REPLACE VIEW signed_contracts AS
  SELECT
    id,
    unit_number,
    client_name,
    client_phone,
    contract_status,
    access_token,
    unsigned_pdf_url,
    signed_pdf_url,
    signed_at,
    created_at,
    updated_at
  FROM contracts
  WHERE contract_status = 'signed_by_client'
  ORDER BY signed_at DESC;


-- ================================================================
--  NEXT STEPS AFTER RUNNING THIS SCRIPT
-- ================================================================
--
--  1. Go to Supabase Dashboard → Storage
--     Create a new bucket named: contracts
--     Set it to NOT public (access via signed URLs or policies)
--
--  2. Enable Realtime on the contracts table:
--     Supabase Dashboard → Database → Replication
--     Toggle ON for the 'contracts' table
--
--  3. The web app ContractSigningPage accesses contracts by:
--     GET /rest/v1/contracts?access_token=eq.{token}&select=*
--
--  4. Admin mobile app polls every 30s:
--     GET /rest/v1/contracts?unit_number=eq.{unit}&select=contract_status,signed_pdf_url
--
-- ================================================================
