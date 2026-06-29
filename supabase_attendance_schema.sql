-- Create the quotations table if it does not exist (synced from Flutter app)
CREATE TABLE IF NOT EXISTS quotations (
    id SERIAL PRIMARY KEY,
    "unitNumber" TEXT UNIQUE NOT NULL,
    "clientName" TEXT,
    "clientPhone" TEXT,
    "clientLocation" TEXT,
    "locationFolder" TEXT,
    date TEXT,
    "totalAmount" REAL,
    "paidAmount" REAL,
    "balanceAmount" REAL,
    latitude REAL,
    longitude REAL,
    "manualAmount" REAL DEFAULT 0,
    "manualWeight" REAL DEFAULT 0,
    "advancePayment" REAL DEFAULT 0,
    "includeWastage" INTEGER DEFAULT 0,
    "originalAmount" REAL,
    "revisionNote" TEXT,
    "globalMaterialCost" REAL DEFAULT 0,
    "globalMargin" REAL DEFAULT 0,
    discount REAL DEFAULT 0,
    "projectStatus" TEXT DEFAULT 'Planning',
    items JSONB,
    materials JSONB,
    rentals JSONB,
    payments JSONB
);

-- Create the clients table
CREATE TABLE IF NOT EXISTS clients (
    id SERIAL PRIMARY KEY,
    client_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    site_location TEXT NOT NULL,
    "unitNumber" TEXT,
    client_selfie TEXT NOT NULL,
    latitude REAL,
    longitude REAL,
    total_contract_amount REAL DEFAULT 0,
    advance_received REAL DEFAULT 0,
    balance_amount REAL DEFAULT 0,
    status TEXT DEFAULT 'Pending',
    assigned_workers TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Create the attendance table
CREATE TABLE IF NOT EXISTS attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_name TEXT NOT NULL,
    worker_phone TEXT NOT NULL,
    site_id TEXT NOT NULL,
    punch_in TIMESTAMPTZ NOT NULL DEFAULT now(),
    punch_out TIMESTAMPTZ,
    work_days NUMERIC(3, 2) DEFAULT 0.0,
    wages REAL DEFAULT 0.0,
    CONSTRAINT fk_attendance_site FOREIGN KEY (site_id) REFERENCES quotations ("unitNumber") ON DELETE CASCADE
);

-- Index for querying active check-ins efficiently
CREATE INDEX IF NOT EXISTS idx_active_checkins ON attendance (worker_phone, site_id) WHERE (punch_out IS NULL);

-- Create function to calculate attendance days based on hours
CREATE OR REPLACE FUNCTION calculate_attendance_days(punch_in TIMESTAMPTZ, punch_out TIMESTAMPTZ)
RETURNS NUMERIC AS $$
DECLARE
    shift_hours NUMERIC;
BEGIN
    IF punch_out IS NULL THEN
        RETURN 0.0;
    END IF;
    
    -- Calculate duration in hours
    shift_hours := EXTRACT(EPOCH FROM (punch_out - punch_in)) / 3600.0;
    
    -- Apply shift calculation rules:
    -- Short shift (< 5 Hours) = 0.5 Work Day
    -- Standard shift (5 to 11 Hours) = 1.0 Work Day
    -- Overtime / Extended shift (11+ Hours) = 1.5 Work Days
    IF shift_hours < 5.0 THEN
        RETURN 0.5;
    ELSIF shift_hours >= 11.0 THEN
        RETURN 1.5;
    ELSE
        RETURN 1.0;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create trigger function that runs BEFORE INSERT OR UPDATE
CREATE OR REPLACE FUNCTION trg_attendance_work_days()
RETURNS TRIGGER AS $$
DECLARE
    calculated_days NUMERIC;
BEGIN
    IF NEW.punch_out IS NOT NULL THEN
        calculated_days := calculate_attendance_days(NEW.punch_in, NEW.punch_out);
        NEW.work_days := calculated_days;
        NEW.wages := calculated_days * 900.0; -- Standard rate of ₹900 per day
    ELSE
        NEW.work_days := 0.0;
        NEW.wages := 0.0;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to attendance table
DROP TRIGGER IF EXISTS trg_calculate_work_days ON attendance;
CREATE TRIGGER trg_calculate_work_days
BEFORE INSERT OR UPDATE ON attendance
FOR EACH ROW
EXECUTE FUNCTION trg_attendance_work_days();

-- ==============================================================================
-- SECURITY AND PERMISSIONS (Row Level Security & Role Grants)
-- ==============================================================================

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Grant table permissions to anon and authenticated roles
GRANT ALL ON TABLE quotations TO anon, authenticated;
GRANT ALL ON TABLE clients TO anon, authenticated;
GRANT ALL ON TABLE attendance TO anon, authenticated;

-- Grant sequence permissions (for SERIAL primary keys)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE quotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- Create Permissive Policies for the anon role (since the app uses anon key heavily)
-- Note: For a production app, you might want to restrict this further.

-- Policies for quotations
DROP POLICY IF EXISTS "Allow public access to quotations" ON quotations;
CREATE POLICY "Allow public access to quotations" ON quotations FOR ALL USING (true) WITH CHECK (true);

-- Policies for clients
DROP POLICY IF EXISTS "Allow public access to clients" ON clients;
CREATE POLICY "Allow public access to clients" ON clients FOR ALL USING (true) WITH CHECK (true);

-- Policies for attendance
DROP POLICY IF EXISTS "Allow public access to attendance" ON attendance;
CREATE POLICY "Allow public access to attendance" ON attendance FOR ALL USING (true) WITH CHECK (true);

-- Create the chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
    id SERIAL PRIMARY KEY,
    site_id TEXT NOT NULL,
    sender TEXT NOT NULL, -- 'admin' or 'client'
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Grant permissions to anon and authenticated roles
GRANT ALL ON TABLE chat_messages TO anon, authenticated;

-- Enable Row Level Security (RLS)
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Policies for chat_messages
DROP POLICY IF EXISTS "Allow public access to chat_messages" ON chat_messages;
CREATE POLICY "Allow public access to chat_messages" ON chat_messages FOR ALL USING (true) WITH CHECK (true);

-- Create the project_messages table
CREATE TABLE IF NOT EXISTS project_messages (
    id SERIAL PRIMARY KEY,
    project_id TEXT NOT NULL,
    sender TEXT NOT NULL, -- 'admin' or 'client'
    message_text TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Grant permissions to anon and authenticated roles
GRANT ALL ON TABLE project_messages TO anon, authenticated;

-- Enable Row Level Security (RLS)
ALTER TABLE project_messages ENABLE ROW LEVEL SECURITY;

-- Policies for project_messages
DROP POLICY IF EXISTS "Allow public access to project_messages" ON project_messages;
CREATE POLICY "Allow public access to project_messages" ON project_messages FOR ALL USING (true) WITH CHECK (true);

-- Migration: Add missing columns to existing tables in Supabase database
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS "projectStatus" TEXT DEFAULT 'Planning';
ALTER TABLE clients ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'Pending';
ALTER TABLE clients ADD COLUMN IF NOT EXISTS assigned_workers TEXT DEFAULT '';
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS current_active_room TEXT;
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS room_costs JSONB DEFAULT '{}'::jsonb;
ALTER TABLE quotations ADD COLUMN IF NOT EXISTS total_updated_budget NUMERIC DEFAULT 0;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS login_pin TEXT;

-- Create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
    id SERIAL PRIMARY KEY,
    site_id TEXT REFERENCES quotations ("unitNumber") ON DELETE CASCADE,
    sender TEXT NOT NULL, -- 'client' or 'admin'
    message TEXT,
    message_content TEXT, -- For media URLs
    message_type TEXT DEFAULT 'text', -- 'text', 'image', 'audio'
    status TEXT DEFAULT 'sent',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Grant permissions for chat_messages
GRANT ALL ON TABLE chat_messages TO anon, authenticated;

-- Enable RLS and select/insert policies
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public access to chat_messages" ON chat_messages;
CREATE POLICY "Allow public access to chat_messages" ON chat_messages FOR ALL USING (true) WITH CHECK (true);

-- Migration: Add status column to existing chat_messages table
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'sent';

-- Enable Realtime for chat_messages (PostgreSQL publication)
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- Force PostgREST schema cache to reload
NOTIFY pgrst, 'reload schema';



