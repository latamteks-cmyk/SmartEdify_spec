-- ============================================================
-- SmartEdify — Database Schema Unificado v2.2 (Producción)
-- PostgreSQL 14+
-- ============================================================

-- =====================
-- Extensiones
-- =====================
CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- digest(), gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS citext;     -- citext
CREATE EXTENSION IF NOT EXISTS pg_cron;    -- scheduler

-- =====================
-- 1) Tablas de dominio (listas controladas)
-- =====================
CREATE TABLE IF NOT EXISTS status_t (status_t text PRIMARY KEY);
CREATE TABLE IF NOT EXISTS country_code_t (country_code_t text PRIMARY KEY);
CREATE TABLE IF NOT EXISTS sensitive_category_t (sensitive_category_t text PRIMARY KEY);
CREATE TABLE IF NOT EXISTS legal_basis_t (legal_basis_t text PRIMARY KEY);
CREATE TABLE IF NOT EXISTS request_type_t (request_type_t text PRIMARY KEY);

-- =====================
-- 2) Identity
-- =====================
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email citext UNIQUE,
  phone text,
  global_status text REFERENCES status_t(status_t),
  email_verified_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tenants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  legal_name text,
  tenant_type text,
  jurisdiction_root text,
  status text REFERENCES status_t(status_t),
  data_residency text,
  dpo_contact text,
  international_transfers boolean DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_tenant_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  status text REFERENCES status_t(status_t),
  default_role text,
  assigned_at timestamptz NOT NULL DEFAULT now(),
  removed_at timestamptz,
  tenant_specific_settings jsonb
);

CREATE TABLE IF NOT EXISTS sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  device_id text,
  cnf_jkt text,
  not_after timestamptz,
  revoked_at timestamptz,
  version integer,
  storage_validation_passed boolean,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  token_hash text NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS feature_flags_identity (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  feature_name text NOT NULL,
  enabled boolean NOT NULL DEFAULT false,
  configuration jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, feature_name)
);

-- =====================
-- 3) User Profile (PII con AEAD envelope)
-- =====================
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  email citext,
  phone text,
  full_name text,
  status text REFERENCES status_t(status_t),
  country_code text REFERENCES country_code_t(country_code_t),
  -- AEAD envelope
  personal_data_ct bytea,
  personal_data_aad bytea,
  personal_data_kid text,
  habeas_data_acceptance boolean,
  habeas_data_accepted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE IF NOT EXISTS communication_consents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  channel text,
  consented boolean,
  consented_at timestamptz,
  revoked_at timestamptz
);

CREATE TABLE IF NOT EXISTS feature_flags_user_profile (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  feature_name text NOT NULL,
  enabled boolean NOT NULL DEFAULT false,
  configuration jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, feature_name)
);

-- =====================
-- 4) Tenancy
-- =====================
CREATE TABLE IF NOT EXISTS condominiums (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  name text NOT NULL,
  address jsonb,
  jurisdiction text,
  timezone text,
  currency text,
  status text REFERENCES status_t(status_t),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS buildings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  condominium_id uuid NOT NULL REFERENCES condominiums(id),
  name text,
  address_line text,
  floors integer,
  amenities jsonb,
  status text REFERENCES status_t(status_t),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS units (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  building_id uuid NOT NULL REFERENCES buildings(id),
  unit_number text,
  unit_type text,
  area numeric,
  bedrooms integer,
  status text REFERENCES status_t(status_t),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS subunits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id uuid NOT NULL REFERENCES units(id),
  subunit_number text,
  subunit_type text,
  area numeric,
  status text REFERENCES status_t(status_t)
);

CREATE TABLE IF NOT EXISTS roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  name text NOT NULL,
  permissions jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS relation_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text
);

CREATE TABLE IF NOT EXISTS sub_relation_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  relation_type_id uuid NOT NULL REFERENCES relation_types(id),
  name text NOT NULL,
  description text
);

CREATE TABLE IF NOT EXISTS memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  profile_id uuid NOT NULL REFERENCES profiles(id),
  condominium_id uuid REFERENCES condominiums(id),
  unit_id uuid REFERENCES units(id),
  relation_type_id uuid REFERENCES relation_types(id),
  sub_relation_type_id uuid REFERENCES sub_relation_types(id),
  privileges jsonb,
  responsible_profile_id uuid REFERENCES profiles(id),
  since timestamptz,
  until timestamptz,
  status text REFERENCES status_t(status_t)
);

CREATE TABLE IF NOT EXISTS role_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES profiles(id),
  role_id uuid NOT NULL REFERENCES roles(id),
  assigned_at timestamptz,
  revoked_at timestamptz,
  status text REFERENCES status_t(status_t)
);

CREATE TABLE IF NOT EXISTS delegations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  delegator_profile_id uuid NOT NULL REFERENCES profiles(id),
  delegate_profile_id uuid NOT NULL REFERENCES profiles(id),
  role_id uuid NOT NULL REFERENCES roles(id),
  start_date timestamptz,
  end_date timestamptz,
  status text REFERENCES status_t(status_t)
);

CREATE TABLE IF NOT EXISTS feature_flags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  condominium_id uuid REFERENCES condominiums(id),
  feature_name text NOT NULL,
  enabled boolean NOT NULL DEFAULT false,
  configuration jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, condominium_id, feature_name)
);

-- =====================
-- 5) Compliance
-- =====================
CREATE TABLE IF NOT EXISTS data_subject_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  profile_id uuid REFERENCES profiles(id),
  request_type text REFERENCES request_type_t(request_type_t),
  status text REFERENCES status_t(status_t),
  payload jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz
);

CREATE TABLE IF NOT EXISTS data_bank_registrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  status text REFERENCES status_t(status_t),
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS data_processing_agreements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  counterparty text,
  status text REFERENCES status_t(status_t),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS impact_assessments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  status text REFERENCES status_t(status_t),
  findings jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS compliance_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  status text REFERENCES status_t(status_t),
  title text,
  details jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ccpa_opt_outs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  profile_id uuid REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS feature_flags_compliance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  feature_name text NOT NULL,
  enabled boolean NOT NULL DEFAULT false,
  configuration jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, feature_name)
);

-- =====================
-- 6) Audit & System (WORM + hash-chain + particionado)
-- =====================
CREATE TABLE IF NOT EXISTS audit_log (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  seq bigint GENERATED BY DEFAULT AS IDENTITY,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  actor_user_id uuid,
  actor_session_id uuid,
  table_name text NOT NULL,
  action text NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE','TRUNCATE','FUNCTION')),
  row_pk jsonb,
  diff jsonb,
  payload jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  hash_prev bytea,
  hash_curr bytea,
  signature bytea,
  PRIMARY KEY (tenant_id, seq)
) PARTITION BY RANGE (created_at);

CREATE TABLE IF NOT EXISTS audit_log_2025_10
  PARTITION OF audit_log FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

CREATE OR REPLACE FUNCTION audit_log_before_insert()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  prev_hash bytea;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext(NEW.tenant_id::text));
  SELECT al.hash_curr INTO prev_hash
  FROM audit_log al
  WHERE al.tenant_id = NEW.tenant_id
  ORDER BY al.seq DESC
  LIMIT 1;
  NEW.hash_prev := prev_hash;
  NEW.hash_curr := digest(
      coalesce(NEW.tenant_id::text,'') || '|' ||
      coalesce(NEW.table_name,'')      || '|' ||
      coalesce(NEW.action,'')          || '|' ||
      coalesce(NEW.payload::text,'')   || '|' ||
      coalesce(encode(NEW.hash_prev,'hex'),''),
      'sha256'
  );
  RETURN NEW;
END$$;

CREATE OR REPLACE FUNCTION audit_log_block_mutations()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'audit_log es WORM: no se permiten %', TG_OP;
END$$;

CREATE TRIGGER trg_audit_log_bi BEFORE INSERT ON audit_log
FOR EACH ROW EXECUTE FUNCTION audit_log_before_insert();
CREATE TRIGGER trg_audit_log_bu BEFORE UPDATE ON audit_log
FOR EACH ROW EXECUTE FUNCTION audit_log_block_mutations();
CREATE TRIGGER trg_audit_log_bd BEFORE DELETE ON audit_log
FOR EACH ROW EXECUTE FUNCTION audit_log_block_mutations();

CREATE TABLE IF NOT EXISTS consent_audit_log (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid,
  consent_id uuid,
  event text NOT NULL,
  payload jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  hash_prev bytea,
  hash_curr bytea,
  signature bytea
) PARTITION BY RANGE (created_at);

CREATE TABLE IF NOT EXISTS consent_audit_log_2025_10
  PARTITION OF consent_audit_log FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

CREATE TRIGGER trg_consent_audit_bi BEFORE INSERT ON consent_audit_log
FOR EACH ROW EXECUTE FUNCTION audit_log_before_insert();
CREATE TRIGGER trg_consent_audit_bu BEFORE UPDATE ON consent_audit_log
FOR EACH ROW EXECUTE FUNCTION audit_log_block_mutations();
CREATE TRIGGER trg_consent_audit_bd BEFORE DELETE ON consent_audit_log
FOR EACH ROW EXECUTE FUNCTION audit_log_block_mutations();

CREATE TABLE IF NOT EXISTS policy_cache (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject uuid,
  table_name text,
  policy jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS backup_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  location text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rls_test_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  table_name text NOT NULL,
  test_query text NOT NULL,
  expected_result text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit_alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  alert_type text,
  severity text,
  alert_data jsonb,
  triggered_at timestamptz NOT NULL DEFAULT now(),
  resolved boolean DEFAULT false
);

-- =====================
-- 7) Outbox por servicio (multi-tenant + particionado)
-- =====================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'outbox_identity') THEN
    EXECUTE $DDL$
      CREATE TABLE outbox_identity (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id uuid NOT NULL REFERENCES tenants(id),
        aggregate_id uuid NOT NULL,
        event_type text NOT NULL,
        payload jsonb NOT NULL,
        occurred_at timestamptz NOT NULL DEFAULT now(),
        created_at timestamptz NOT NULL DEFAULT now(),
        published_at timestamptz,
        UNIQUE (tenant_id, aggregate_id, event_type, occurred_at)
      ) PARTITION BY RANGE (created_at)
    $DDL$;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'outbox_profiles') THEN
    EXECUTE replace($DDL$, 'outbox_identity', 'outbox_profiles');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'outbox_compliance') THEN
    EXECUTE replace($DDL$, 'outbox_identity', 'outbox_compliance');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'outbox_tenancy') THEN
    EXECUTE replace($DDL$, 'outbox_identity', 'outbox_tenancy');
  END IF;
END$$;

CREATE TABLE IF NOT EXISTS outbox_identity_2025_10
  PARTITION OF outbox_identity FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE IF NOT EXISTS outbox_profiles_2025_10
  PARTITION OF outbox_profiles FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE IF NOT EXISTS outbox_compliance_2025_10
  PARTITION OF outbox_compliance FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE IF NOT EXISTS outbox_tenancy_2025_10
  PARTITION OF outbox_tenancy FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

-- =====================
-- 8) RLS obligatorio y forzado por tenant_id
-- =====================
CREATE OR REPLACE FUNCTION enforce_rls(_tbl regclass)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', _tbl);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', _tbl);
  EXECUTE format('DROP POLICY IF EXISTS tenant_isolation ON %s', _tbl);
  EXECUTE format(
    $$CREATE POLICY tenant_isolation ON %s
      USING (tenant_id = current_setting(''app.current_tenant'')::uuid)$$,
    _tbl
  );
END$$;

-- Aplicar a tablas multi-tenant
SELECT enforce_rls('user_tenant_assignments');
SELECT enforce_rls('sessions');
SELECT enforce_rls('feature_flags_identity');
SELECT enforce_rls('profiles');
SELECT enforce_rls('communication_consents');
SELECT enforce_rls('feature_flags_user_profile');
SELECT enforce_rls('condominiums');
SELECT enforce_rls('roles');
SELECT enforce_rls('memberships');
SELECT enforce_rls('role_assignments');
SELECT enforce_rls('delegations');
SELECT enforce_rls('feature_flags');
SELECT enforce_rls('data_subject_requests');
SELECT enforce_rls('data_bank_registrations');
SELECT enforce_rls('data_processing_agreements');
SELECT enforce_rls('impact_assessments');
SELECT enforce_rls('compliance_tasks');
SELECT enforce_rls('ccpa_opt_outs');
SELECT enforce_rls('feature_flags_compliance');
SELECT enforce_rls('audit_log');
SELECT enforce_rls('consent_audit_log');
SELECT enforce_rls('policy_cache');
SELECT enforce_rls('backup_snapshots');
SELECT enforce_rls('rls_test_cases');
SELECT enforce_rls('audit_alerts');
SELECT enforce_rls('outbox_identity');
SELECT enforce_rls('outbox_profiles');
SELECT enforce_rls('outbox_compliance');
SELECT enforce_rls('outbox_tenancy');

-- =====================
-- 9) Triggers de updated_at
-- =====================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END$$;

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT tablename FROM pg_tables
           WHERE schemaname = 'public' AND tablename IN (
             'tenants','profiles','condominiums','feature_flags_identity','feature_flags_user_profile','feature_flags'
           ) LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_%s_updated_at ON %s', r.tablename, r.tablename);
    EXECUTE format('CREATE TRIGGER trg_%s_updated_at BEFORE UPDATE ON %s FOR EACH ROW EXECUTE FUNCTION set_updated_at()', r.tablename, r.tablename);
  END LOOP;
END$$;

-- =====================
-- 10) Índices críticos
-- =====================
CREATE INDEX IF NOT EXISTS idx_audit_log_tenant_created    ON audit_log (tenant_id, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_log_tenant_action     ON audit_log (tenant_id, action, created_at);
CREATE INDEX IF NOT EXISTS idx_dsr_tenant_status           ON data_subject_requests (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_memberships_profile_status  ON memberships (profile_id, status);
CREATE INDEX IF NOT EXISTS idx_memberships_condo_tenant    ON memberships (condominium_id, tenant_id);
CREATE INDEX IF NOT EXISTS idx_outbox_identity_tenant_time ON outbox_identity (tenant_id, created_at);
CREATE INDEX IF NOT EXISTS idx_outbox_profiles_tenant_time ON outbox_profiles (tenant_id, created_at);
CREATE INDEX IF NOT EXISTS idx_outbox_compliance_tenant_time ON outbox_compliance (tenant_id, created_at);
CREATE INDEX IF NOT EXISTS idx_outbox_tenancy_tenant_time  ON outbox_tenancy (tenant_id, created_at);

-- =====================
-- 11) Jobs operativos (pg_cron)
-- =====================
SELECT cron.schedule('cleanup-sessions', '0 2 * * *',
$$DELETE FROM sessions WHERE not_after < now() - INTERVAL '90 days'$$);

SELECT cron.schedule('anonymize-dsar', '5 2 * * *',
$$UPDATE data_subject_requests SET profile_id = NULL
  WHERE created_at < now() - INTERVAL '3 years'$$);

SELECT cron.schedule('purge-soft-deleted-profiles', '10 2 * * *',
$$DELETE FROM profiles WHERE deleted_at IS NOT NULL AND deleted_at < now() - INTERVAL '30 days'$$);
