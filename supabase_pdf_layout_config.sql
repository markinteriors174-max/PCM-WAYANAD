-- ================================================================
--  PDF LAYOUT CONFIGURATION TABLE
--  PCM WAYANAD — Supabase SQL Schema
--  Source: lib/services/pdf_utils/
--    • quotation_header_builder.dart
--    • quotation_footer_builder.dart
--    • letter_pad_builder.dart
--    • pdf_icons.dart
--  Every DEFAULT value below is the EXACT hardcoded value from
--  the mobile app. Nothing is invented.
-- ================================================================


-- ── 0. CLEAN SLATE (safe to re-run) ─────────────────────────────
DROP VIEW  IF EXISTS active_pdf_layout   CASCADE;
DROP TABLE IF EXISTS pdf_layout_config   CASCADE;


-- ================================================================
--  TABLE: pdf_layout_config
--  One row = one company branding profile.
--  The web app fetches the single row WHERE is_active = TRUE.
-- ================================================================
CREATE TABLE pdf_layout_config (

  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

  -- ── COMPANY BRANDING ──────────────────────────────────────────
  -- letter_pad_builder.dart  → prefs.getString('company_name')    ?? 'PCM WAYANAD'
  -- letter_pad_builder.dart  → prefs.getString('company_tagline') ?? 'Premium Ceiling Master'
  -- quotation_header_builder.dart → "MSME Reg No: UDYAM-KL-14-0031878"
  -- quotation_footer_builder.dart → 'Proprietor, PCM Wayanad'
  -- quotation_footer_builder.dart → 'Madhusudhan'
  -- letter_pad_builder.dart  → 'For Premium Ceiling Master,'
  -- letter_pad_builder.dart  → 'OFFICIAL PCM CORRESPONDENCE'
  company_name                  TEXT        NOT NULL DEFAULT 'PCM WAYANAD',
  tagline                       TEXT        NOT NULL DEFAULT 'Premium Ceiling Master',
  msme_reg_number               TEXT        NOT NULL DEFAULT 'UDYAM-KL-14-0031878',
  proprietor_name               TEXT        NOT NULL DEFAULT 'Madhusudhan',
  proprietor_title              TEXT        NOT NULL DEFAULT 'Proprietor, PCM Wayanad',
  company_display_label         TEXT        NOT NULL DEFAULT 'For Premium Ceiling Master,',
  footer_correspondence_label   TEXT        NOT NULL DEFAULT 'OFFICIAL PCM CORRESPONDENCE',

  -- ── CONTACT INFORMATION ───────────────────────────────────────
  -- pdf_icons.dart → ownerPhone = '93 83 40 61 85'
  -- quotation_footer_builder.dart → 'Mob: 93 83 40 61 85'  /  'tel:9383406185'
  -- quotation_footer_builder.dart → 'Email: MARKINTERIOR174@GMAIL.COM'
  owner_phone                   TEXT        NOT NULL DEFAULT '9383406185',
  owner_phone_display           TEXT        NOT NULL DEFAULT '93 83 40 61 85',
  owner_email                   TEXT        NOT NULL DEFAULT 'MARKINTERIOR174@GMAIL.COM',

  -- ── BANK & PAYMENT DETAILS ────────────────────────────────────
  -- quotation_footer_builder.dart → buildRepeatingFooter( bankName, accountName,
  --                                   accountNumber, ifsc, upiId )
  -- (currently passed at runtime — store here so web app reads from DB)
  bank_name                     TEXT,
  account_name                  TEXT,
  account_number                TEXT,
  ifsc_code                     TEXT,
  upi_id                        TEXT,

  -- ── WEB / QR CODE URLs ───────────────────────────────────────
  -- quotation_header_builder.dart →
  --   'https://pcmwayanad.com/quotation/$unitNumber'
  --   'https://pcmwayanad.com/dispatch/$unitNumber'
  website_base_url              TEXT        NOT NULL DEFAULT 'https://pcmwayanad.com',
  quotation_url_template        TEXT        NOT NULL DEFAULT 'https://pcmwayanad.com/quotation/{unit_number}',
  dispatch_url_template         TEXT        NOT NULL DEFAULT 'https://pcmwayanad.com/dispatch/{unit_number}',
  upi_pay_url_template          TEXT        NOT NULL DEFAULT 'upi://pay?pa={upi_id}&pn={company_name}&cu=INR',

  -- ── ASSET STORAGE PATHS / URLs ────────────────────────────────
  -- letter_pad_builder.dart → rootBundle.load('assets/images/logo.png')
  -- letter_pad_builder.dart → rootBundle.load('assets/images/emblem_of_india.png')
  -- letter_pad_builder.dart → prefs.getString('signature_path')
  -- letter_pad_builder.dart → prefs.getString('seal_path')
  -- Upload files to Supabase Storage and paste the public URLs here.
  logo_url                      TEXT,   -- Supabase Storage URL for logo.png
  emblem_url                    TEXT,   -- Supabase Storage URL for emblem_of_india.png
  signature_url                 TEXT,   -- Supabase Storage URL for owner signature image
  seal_url                      TEXT,   -- Supabase Storage URL for company seal image

  -- ── HEADER LAYOUT — SIZES (in PDF points) ─────────────────────
  -- Source: quotation_header_builder.dart → buildModernHeader()
  header_qr_size                NUMERIC(6,2) NOT NULL DEFAULT 45.0,   -- const double qrSize = 45.0
  header_logo_height            NUMERIC(6,2) NOT NULL DEFAULT 40.0,   -- pw.Image(logo, height: 40)
  header_emblem_height          NUMERIC(6,2) NOT NULL DEFAULT 25.0,   -- pw.Image(emblem, height: 25)
  header_company_name_font_size NUMERIC(6,2) NOT NULL DEFAULT 22.0,   -- fontSize: 22
  header_tagline_font_size      NUMERIC(6,2) NOT NULL DEFAULT 10.0,   -- fontSize: 10
  header_phone_font_size        NUMERIC(6,2) NOT NULL DEFAULT 9.0,    -- fontSize: 9
  header_msme_font_size         NUMERIC(6,2) NOT NULL DEFAULT 8.5,    -- fontSize: 8.5
  header_qr_label_font_size     NUMERIC(6,2) NOT NULL DEFAULT 5.0,    -- fontSize: 5
  header_divider_thickness      NUMERIC(6,2) NOT NULL DEFAULT 1.0,    -- pw.Divider thickness: 1

  -- ── CLIENT INFO CARD — SIZES ──────────────────────────────────
  -- Source: quotation_header_builder.dart → buildClientCard()
  client_card_quotation_font_size  NUMERIC(6,2) NOT NULL DEFAULT 9.0,   -- fontSize: 9  (QUOTATION: label)
  client_card_date_font_size       NUMERIC(6,2) NOT NULL DEFAULT 8.0,   -- fontSize: 8  (DATE: label)
  client_card_name_font_size       NUMERIC(6,2) NOT NULL DEFAULT 10.0,  -- fontSize: 10 (CLIENT: name)
  client_card_detail_font_size     NUMERIC(6,2) NOT NULL DEFAULT 8.5,   -- fontSize: 8.5 (location/phone)
  client_card_area_label_font_size NUMERIC(6,2) NOT NULL DEFAULT 8.0,   -- fontSize: 8  (TOTAL AREA label)
  client_card_area_value_font_size NUMERIC(6,2) NOT NULL DEFAULT 10.0,  -- fontSize: 10 (sqft value)
  client_card_border_width         NUMERIC(6,2) NOT NULL DEFAULT 1.5,   -- Border.all width: 1.5
  client_card_padding_v            NUMERIC(6,2) NOT NULL DEFAULT 8.0,   -- EdgeInsets vertical: 8
  client_card_padding_h            NUMERIC(6,2) NOT NULL DEFAULT 10.0,  -- EdgeInsets horizontal: 10

  -- ── FOOTER REPEATING — SIZES ──────────────────────────────────
  -- Source: quotation_footer_builder.dart → buildRepeatingFooter()
  footer_signature_width        NUMERIC(6,2) NOT NULL DEFAULT 70.0,   -- pw.Image width: 70
  footer_signature_height       NUMERIC(6,2) NOT NULL DEFAULT 35.0,   -- pw.Image height: 35
  footer_prepared_by_font_size  NUMERIC(6,2) NOT NULL DEFAULT 7.5,    -- fontSize: 7.5 ('Prepared By:')
  footer_company_font_size      NUMERIC(6,2) NOT NULL DEFAULT 9.5,    -- fontSize: 9.5 (company name)
  footer_proprietor_font_size   NUMERIC(6,2) NOT NULL DEFAULT 7.5,    -- fontSize: 7.5 (proprietor title)
  footer_contact_font_size      NUMERIC(6,2) NOT NULL DEFAULT 8.0,    -- fontSize: 8   (phone/email row)
  footer_bank_label_font_size   NUMERIC(6,2) NOT NULL DEFAULT 7.0,    -- fontSize: 7   ('BANK DETAILS')
  footer_bank_detail_font_size  NUMERIC(6,2) NOT NULL DEFAULT 7.0,    -- fontSize: 7   (bank/ifsc line)
  footer_bank_acct_font_size    NUMERIC(6,2) NOT NULL DEFAULT 7.5,    -- fontSize: 7.5 (A/C No & UPI)
  footer_divider_thickness      NUMERIC(6,2) NOT NULL DEFAULT 0.5,    -- pw.Divider thickness: 0.5

  -- ── FOOTER FINAL SIGNATURES — SIZES ──────────────────────────
  -- Source: quotation_footer_builder.dart → buildFinalSignatures()
  footer_client_sig_width       NUMERIC(6,2) NOT NULL DEFAULT 85.0,   -- clientSignatureImage width: 85
  footer_client_sig_height      NUMERIC(6,2) NOT NULL DEFAULT 40.0,   -- clientSignatureImage height: 40
  footer_client_sig_box_width   NUMERIC(6,2) NOT NULL DEFAULT 110.0,  -- dashed box width: 110
  footer_client_sig_box_height  NUMERIC(6,2) NOT NULL DEFAULT 40.0,   -- dashed box height: 40
  footer_auth_sig_width         NUMERIC(6,2) NOT NULL DEFAULT 70.0,   -- authorized sig width: 70
  footer_auth_sig_height        NUMERIC(6,2) NOT NULL DEFAULT 35.0,   -- authorized sig height: 35
  footer_seal_width             NUMERIC(6,2) NOT NULL DEFAULT 55.0,   -- seal image width: 55
  footer_seal_height            NUMERIC(6,2) NOT NULL DEFAULT 55.0,   -- seal image height: 55
  footer_auth_name_font_size    NUMERIC(6,2) NOT NULL DEFAULT 9.0,    -- fontSize: 9   ('Madhusudhan')
  footer_sig_label_font_size    NUMERIC(6,2) NOT NULL DEFAULT 7.5,    -- fontSize: 7.5 (sig labels)

  -- ── LETTER PAD — SIZES ───────────────────────────────────────
  -- Source: letter_pad_builder.dart → generate()
  letterpad_title_font_size          NUMERIC(6,2) NOT NULL DEFAULT 16.0,  -- fontSize: 16
  letterpad_recipient_font_size      NUMERIC(6,2) NOT NULL DEFAULT 12.0,  -- fontSize: 12
  letterpad_body_font_size           NUMERIC(6,2) NOT NULL DEFAULT 11.0,  -- fontSize: 11
  letterpad_body_line_height         NUMERIC(6,2) NOT NULL DEFAULT 1.5,   -- height: 1.5
  letterpad_closing_font_size        NUMERIC(6,2) NOT NULL DEFAULT 10.0,  -- fontSize: 10
  letterpad_sig_width                NUMERIC(6,2) NOT NULL DEFAULT 90.0,  -- pw.Image width: 90
  letterpad_sig_height               NUMERIC(6,2) NOT NULL DEFAULT 45.0,  -- pw.Image height: 45
  letterpad_seal_width               NUMERIC(6,2) NOT NULL DEFAULT 90.0,  -- pw.Image width: 90
  letterpad_seal_height              NUMERIC(6,2) NOT NULL DEFAULT 90.0,  -- pw.Image height: 90
  letterpad_footer_divider_thickness NUMERIC(6,2) NOT NULL DEFAULT 2.0,   -- Divider thickness: 2
  letterpad_footer_font_size         NUMERIC(6,2) NOT NULL DEFAULT 8.0,   -- fontSize: 8 (footer row)

  -- ── PAGE LAYOUT ───────────────────────────────────────────────
  -- letter_pad_builder.dart → pw.Page(pageFormat: PdfPageFormat.a4, margin: EdgeInsets.all(40))
  page_format                   TEXT        NOT NULL DEFAULT 'A4',
  page_margin_top               NUMERIC(6,2) NOT NULL DEFAULT 40.0,
  page_margin_bottom            NUMERIC(6,2) NOT NULL DEFAULT 40.0,
  page_margin_left              NUMERIC(6,2) NOT NULL DEFAULT 40.0,
  page_margin_right             NUMERIC(6,2) NOT NULL DEFAULT 40.0,

  -- ── COLOUR TOKENS ─────────────────────────────────────────────
  -- (dart:pdf PdfColors references from header & footer builders)
  color_primary                 TEXT        NOT NULL DEFAULT 'brown900',   -- company name, borders, QR
  color_secondary               TEXT        NOT NULL DEFAULT 'brown700',   -- tagline text
  color_upi_qr                  TEXT        NOT NULL DEFAULT 'green900',   -- UPI QR code colour
  color_project_qr              TEXT        NOT NULL DEFAULT 'brown900',   -- Project / Dispatch QR colour
  color_client_card_bg          TEXT        NOT NULL DEFAULT 'orange50',   -- client card background
  color_client_card_border      TEXT        NOT NULL DEFAULT 'brown900',   -- client card border
  color_divider                 TEXT        NOT NULL DEFAULT 'brown200',   -- thin section dividers
  color_total_area_badge_bg     TEXT        NOT NULL DEFAULT 'yellow100',  -- TOTAL AREA badge fill
  color_total_area_text         TEXT        NOT NULL DEFAULT 'blue900',    -- sqft value text colour
  color_link                    TEXT        NOT NULL DEFAULT 'blue800',    -- phone / email hyperlinks
  color_grey_label              TEXT        NOT NULL DEFAULT 'grey700',    -- 'Prepared By:' / labels
  color_revision_border         TEXT        NOT NULL DEFAULT 'brown500',   -- revision note border

  -- ── METADATA ─────────────────────────────────────────────────
  is_active                     BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at                    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                    TIMESTAMPTZ NOT NULL DEFAULT NOW()

);

COMMENT ON TABLE pdf_layout_config IS
  'Single-row configuration table that mirrors every hardcoded branding, '
  'contact, asset, size, and colour value previously embedded in the '
  'PCM Wayanad Flutter mobile app PDF builders. '
  'The web app fetches the active row (is_active = TRUE) to render '
  'identical PDF headers and footers.';


-- ── 1. AUTO-UPDATE updated_at TRIGGER ────────────────────────────
CREATE OR REPLACE FUNCTION _trg_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_pdf_layout_config_updated_at
  BEFORE UPDATE ON pdf_layout_config
  FOR EACH ROW EXECUTE FUNCTION _trg_set_updated_at();


-- ================================================================
--  SEED ROW
--  Exact values extracted from the Flutter source code.
--  Fill in bank details and upload assets to Supabase Storage,
--  then UPDATE this row with the returned public URLs.
-- ================================================================
INSERT INTO pdf_layout_config (

  -- branding
  company_name, tagline, msme_reg_number,
  proprietor_name, proprietor_title,
  company_display_label, footer_correspondence_label,

  -- contact
  owner_phone, owner_phone_display, owner_email,

  -- bank (NULL until filled in the Supabase dashboard)
  bank_name, account_name, account_number, ifsc_code, upi_id,

  -- urls
  website_base_url, quotation_url_template, dispatch_url_template, upi_pay_url_template,

  -- assets (NULL until uploaded to Supabase Storage)
  logo_url, emblem_url, signature_url, seal_url,

  -- header layout
  header_qr_size, header_logo_height, header_emblem_height,
  header_company_name_font_size, header_tagline_font_size,
  header_phone_font_size, header_msme_font_size,
  header_qr_label_font_size, header_divider_thickness,

  -- client card
  client_card_quotation_font_size, client_card_date_font_size,
  client_card_name_font_size, client_card_detail_font_size,
  client_card_area_label_font_size, client_card_area_value_font_size,
  client_card_border_width, client_card_padding_v, client_card_padding_h,

  -- repeating footer
  footer_signature_width, footer_signature_height,
  footer_prepared_by_font_size, footer_company_font_size,
  footer_proprietor_font_size, footer_contact_font_size,
  footer_bank_label_font_size, footer_bank_detail_font_size,
  footer_bank_acct_font_size, footer_divider_thickness,

  -- final signatures
  footer_client_sig_width, footer_client_sig_height,
  footer_client_sig_box_width, footer_client_sig_box_height,
  footer_auth_sig_width, footer_auth_sig_height,
  footer_seal_width, footer_seal_height,
  footer_auth_name_font_size, footer_sig_label_font_size,

  -- letter pad
  letterpad_title_font_size, letterpad_recipient_font_size,
  letterpad_body_font_size, letterpad_body_line_height,
  letterpad_closing_font_size,
  letterpad_sig_width, letterpad_sig_height,
  letterpad_seal_width, letterpad_seal_height,
  letterpad_footer_divider_thickness, letterpad_footer_font_size,

  -- page
  page_format,
  page_margin_top, page_margin_bottom, page_margin_left, page_margin_right,

  -- colours
  color_primary, color_secondary,
  color_upi_qr, color_project_qr,
  color_client_card_bg, color_client_card_border, color_divider,
  color_total_area_badge_bg, color_total_area_text,
  color_link, color_grey_label, color_revision_border,

  is_active

) VALUES (

  -- branding
  'PCM WAYANAD',
  'Premium Ceiling Master',
  'UDYAM-KL-14-0031878',
  'Madhusudhan',
  'Proprietor, PCM Wayanad',
  'For Premium Ceiling Master,',
  'OFFICIAL PCM CORRESPONDENCE',

  -- contact
  '9383406185',
  '93 83 40 61 85',
  'MARKINTERIOR174@GMAIL.COM',

  -- bank (fill later)
  NULL, NULL, NULL, NULL, NULL,

  -- urls
  'https://pcmwayanad.com',
  'https://pcmwayanad.com/quotation/{unit_number}',
  'https://pcmwayanad.com/dispatch/{unit_number}',
  'upi://pay?pa={upi_id}&pn={company_name}&cu=INR',

  -- assets (fill after uploading to Supabase Storage)
  NULL, NULL, NULL, NULL,

  -- header layout (exact values from quotation_header_builder.dart)
  45.0,   -- header_qr_size           → const double qrSize = 45.0
  40.0,   -- header_logo_height       → pw.Image(logo, height: 40)
  25.0,   -- header_emblem_height     → pw.Image(emblem, height: 25)
  22.0,   -- header_company_name_font_size → fontSize: 22
  10.0,   -- header_tagline_font_size → fontSize: 10
  9.0,    -- header_phone_font_size   → fontSize: 9
  8.5,    -- header_msme_font_size    → fontSize: 8.5
  5.0,    -- header_qr_label_font_size → fontSize: 5
  1.0,    -- header_divider_thickness → Divider thickness: 1

  -- client card (exact values from buildClientCard)
  9.0,    -- client_card_quotation_font_size
  8.0,    -- client_card_date_font_size
  10.0,   -- client_card_name_font_size
  8.5,    -- client_card_detail_font_size
  8.0,    -- client_card_area_label_font_size
  10.0,   -- client_card_area_value_font_size
  1.5,    -- client_card_border_width
  8.0,    -- client_card_padding_v
  10.0,   -- client_card_padding_h

  -- repeating footer (exact values from buildRepeatingFooter)
  70.0,   -- footer_signature_width
  35.0,   -- footer_signature_height
  7.5,    -- footer_prepared_by_font_size
  9.5,    -- footer_company_font_size
  7.5,    -- footer_proprietor_font_size
  8.0,    -- footer_contact_font_size
  7.0,    -- footer_bank_label_font_size
  7.0,    -- footer_bank_detail_font_size
  7.5,    -- footer_bank_acct_font_size
  0.5,    -- footer_divider_thickness

  -- final signatures (exact values from buildFinalSignatures)
  85.0,   -- footer_client_sig_width
  40.0,   -- footer_client_sig_height
  110.0,  -- footer_client_sig_box_width   (dashed 'Awaiting Signature' box)
  40.0,   -- footer_client_sig_box_height
  70.0,   -- footer_auth_sig_width
  35.0,   -- footer_auth_sig_height
  55.0,   -- footer_seal_width
  55.0,   -- footer_seal_height
  9.0,    -- footer_auth_name_font_size    ('Madhusudhan')
  7.5,    -- footer_sig_label_font_size

  -- letter pad (exact values from letter_pad_builder.dart)
  16.0,   -- letterpad_title_font_size
  12.0,   -- letterpad_recipient_font_size
  11.0,   -- letterpad_body_font_size
  1.5,    -- letterpad_body_line_height
  10.0,   -- letterpad_closing_font_size
  90.0,   -- letterpad_sig_width
  45.0,   -- letterpad_sig_height
  90.0,   -- letterpad_seal_width
  90.0,   -- letterpad_seal_height
  2.0,    -- letterpad_footer_divider_thickness
  8.0,    -- letterpad_footer_font_size

  -- page
  'A4',
  40.0, 40.0, 40.0, 40.0,   -- all margins = 40pt  (EdgeInsets.all(40))

  -- colours
  'brown900',   -- color_primary
  'brown700',   -- color_secondary
  'green900',   -- color_upi_qr
  'brown900',   -- color_project_qr
  'orange50',   -- color_client_card_bg
  'brown900',   -- color_client_card_border
  'brown200',   -- color_divider
  'yellow100',  -- color_total_area_badge_bg
  'blue900',    -- color_total_area_text
  'blue800',    -- color_link
  'grey700',    -- color_grey_label
  'brown500',   -- color_revision_border

  TRUE          -- is_active
);


-- ================================================================
--  ROW-LEVEL SECURITY (RLS)
--  • Anonymous / authenticated users (web app) → SELECT only.
--  • service_role                              → full access.
-- ================================================================
ALTER TABLE pdf_layout_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pdf_layout_config__anon_read"
  ON pdf_layout_config FOR SELECT
  TO anon, authenticated
  USING (is_active = TRUE);

CREATE POLICY "pdf_layout_config__service_write"
  ON pdf_layout_config FOR ALL
  TO service_role
  USING (TRUE)
  WITH CHECK (TRUE);


-- ================================================================
--  CONVENIENCE VIEW
--  Web app usage:
--    const { data } = await supabase.from('active_pdf_layout').select('*').single();
-- ================================================================
CREATE OR REPLACE VIEW active_pdf_layout AS
  SELECT * FROM pdf_layout_config
  WHERE is_active = TRUE
  LIMIT 1;


-- ================================================================
--  NEXT STEPS (after running this script in Supabase SQL Editor)
-- ================================================================
--
--  1. UPLOAD ASSETS to Supabase Storage (bucket: 'pdf-assets')
--       logo.png             → copy public URL → UPDATE logo_url
--       emblem_of_india.png  → copy public URL → UPDATE emblem_url
--       owner_signature.png  → copy public URL → UPDATE signature_url
--       company_seal.png     → copy public URL → UPDATE seal_url
--
--  2. FILL IN BANK DETAILS:
--       UPDATE pdf_layout_config SET
--         bank_name      = 'Your Bank Name',
--         account_name   = 'PCM WAYANAD',
--         account_number = 'XXXXXXXXXXXX',
--         ifsc_code      = 'XXXXXXXXX',
--         upi_id         = 'yourhandle@bank'
--       WHERE is_active = TRUE;
--
--  3. FETCH IN WEB APP:
--       const { data } = await supabase
--         .from('active_pdf_layout')
--         .select('*')
--         .single();
--     Then use each column to render the PDF header and footer
--     with the exact same layout as the mobile app.
--
-- ================================================================
