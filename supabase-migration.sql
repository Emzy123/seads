-- ============================================================
-- SEADS — Full Supabase PostgreSQL + PostGIS Schema
-- Run in: Supabase Dashboard → SQL Editor
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ─── Users ───────────────────────────────────────────────────
-- id = firebase_uid (TEXT, set by the app on register)
CREATE TABLE IF NOT EXISTS users (
  id          TEXT        PRIMARY KEY,          -- Firebase UID
  email       TEXT        NOT NULL UNIQUE,
  name        TEXT        NOT NULL DEFAULT '',
  phone       TEXT        NOT NULL DEFAULT '',
  role        TEXT        NOT NULL DEFAULT 'patient'
                CHECK (role IN ('patient', 'paramedic', 'dispatcher')),
  fcm_token   TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_role ON users (role);

-- ─── Ambulances ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ambulances (
  id            TEXT        PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
  name          TEXT        NOT NULL,
  status        TEXT        NOT NULL DEFAULT 'available'
                  CHECK (status IN ('available', 'on_mission', 'maintenance', 'offline')),
  location      GEOGRAPHY(POINT, 4326),          -- PostGIS point (lng, lat)
  paramedic_id  TEXT        REFERENCES users(id) ON DELETE SET NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ambulances_status       ON ambulances (status);
CREATE INDEX IF NOT EXISTS idx_ambulances_paramedic    ON ambulances (paramedic_id);
CREATE INDEX IF NOT EXISTS idx_ambulances_location     ON ambulances USING GIST (location);

-- ─── Incidents ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS incidents (
  id                    TEXT        PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
  patient_id            TEXT        NOT NULL REFERENCES users(id),
  status                TEXT        NOT NULL DEFAULT 'pending'
                          CHECK (status IN ('pending','dispatched','en_route','on_scene','resolved','cancelled')),
  location              GEOGRAPHY(POINT, 4326),
  emergency_type        TEXT        NOT NULL,
  description           TEXT,
  assigned_ambulance_id TEXT        REFERENCES ambulances(id) ON DELETE SET NULL,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_incidents_patient    ON incidents (patient_id);
CREATE INDEX IF NOT EXISTS idx_incidents_ambulance  ON incidents (assigned_ambulance_id);
CREATE INDEX IF NOT EXISTS idx_incidents_status     ON incidents (status);
CREATE INDEX IF NOT EXISTS idx_incidents_location   ON incidents USING GIST (location);

-- ─── Emergency Contacts ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS emergency_contacts (
  id            TEXT        PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
  user_id       TEXT        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT        NOT NULL,
  phone         TEXT        NOT NULL,
  relationship  TEXT        NOT NULL,
  is_primary    BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_contacts_user ON emergency_contacts (user_id);

-- ─── Medical Profiles ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS medical_profiles (
  user_id     TEXT        PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  blood_type  TEXT,
  allergies   TEXT[]      NOT NULL DEFAULT '{}',
  conditions  TEXT[]      NOT NULL DEFAULT '{}',
  medications TEXT[]      NOT NULL DEFAULT '{}',
  notes       TEXT,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── Equipment Items ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS equipment_items (
  id            TEXT        PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
  ambulance_id  TEXT        NOT NULL REFERENCES ambulances(id) ON DELETE CASCADE,
  name          TEXT        NOT NULL,
  category      TEXT        NOT NULL,
  status        TEXT        NOT NULL DEFAULT 'ok'
                  CHECK (status IN ('ok', 'warning', 'low')),
  last_checked  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_equipment_ambulance ON equipment_items (ambulance_id);

-- ─── Shifts ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS shifts (
  id            TEXT        PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
  paramedic_id  TEXT        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  ambulance_id  TEXT        REFERENCES ambulances(id) ON DELETE SET NULL,
  type          TEXT        NOT NULL,   -- e.g. 'Day Shift', 'Night Shift'
  start_time    TIMESTAMPTZ NOT NULL,
  end_time      TIMESTAMPTZ NOT NULL,
  status        TEXT        NOT NULL DEFAULT 'scheduled'
                  CHECK (status IN ('scheduled', 'active', 'completed', 'cancelled')),
  partner_name  TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shifts_paramedic ON shifts (paramedic_id);
CREATE INDEX IF NOT EXISTS idx_shifts_ambulance ON shifts (ambulance_id);
CREATE INDEX IF NOT EXISTS idx_shifts_start     ON shifts (start_time);

-- ─── Shift Swap Requests ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS shift_swap_requests (
  id            TEXT        PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
  shift_id      TEXT        NOT NULL REFERENCES shifts(id) ON DELETE CASCADE,
  requester_id  TEXT        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message       TEXT,
  status        TEXT        NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_swap_requests_shift     ON shift_swap_requests (shift_id);
CREATE INDEX IF NOT EXISTS idx_swap_requests_requester ON shift_swap_requests (requester_id);

-- ─── updated_at trigger function ─────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['users', 'ambulances', 'incidents'] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_trigger
      WHERE tgname = 'trg_' || t || '_updated_at'
    ) THEN
      EXECUTE format(
        'CREATE TRIGGER trg_%I_updated_at
         BEFORE UPDATE ON %I
         FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
        t, t
      );
    END IF;
  END LOOP;
END;
$$;
