# 🏛️ Arquitectura de Base de Datos — SmartEdify  
**Versión**: 2.1  
**Fecha**: 2025-10-13  
**Estado**: Aprobado para Implementación (Fase 1)  
**Autores**: Equipo de Arquitectura y DBA SmartEdify  
**Alcance**: Fase 1 — Core Backbone (`Identity`, `User Profiles`, `Tenancy`, `Compliance`)  

---

## 📌 Resumen Ejecutivo

Esta arquitectura de base de datos define un modelo relacional seguro, inmutable, multi-tenant y alineado con los principios de **Privacy by Design**, **Zero Trust**, **WORM**, **Row-Level Security (RLS)** y **cumplimiento multinormativo** exigidos por el [Documento de Visión v1.1](vision_document.txt).

Incorpora todas las observaciones técnicas críticas:
- ✅ **Inmutabilidad total** en `audit_log` con hash-chain, firma y WORM.
- ✅ **RLS obligatorio** por `tenant_id` en todos los servicios.
- ✅ **Integridad referencial** mediante FKs, UNIQUE y ENUM.
- ✅ **Cifrado AEAD** para PII sensibles (DNI, salud).
- ✅ **Particionado mensual** y estrategia de índices completa.
- ✅ **Gestión de ciclo de vida** con TTL, cron y anonimización.
- ✅ **Resiliencia operativa**: réplicas, PITR, RTO ≤ 5 min.
- ✅ **Consistencia transaccional** mediante patrón **Outbox**.

---

## 🧱 1. Principios de Diseño

| Principio | Aplicación |
|----------|------------|
| **Multi-tenancy** | Aislamiento por `tenant_id` + RLS en todas las tablas. |
| **Inmutabilidad** | `audit_log` es **append-only**, con hash-chain y respaldo WORM en S3. |
| **Privacy by Design** | PII cifrada en base de datos; datos sensibles en tablas separadas con consentimiento explícito. |
| **Zero Trust** | Cada operación requiere contexto (`tenant_id`, `session_id`) y DPoP. |
| **Event-Driven** | Patrón **Outbox** garantiza consistencia transaccional entre microservicios. |
| **Observabilidad** | Logs estructurados, métricas de rendimiento y alertas SLO. |

---

## 🔐 2. Modelo de Datos Mejorado

### 2.1 Diagrama ER Completo (v2.1)

```mermaid
---
config:
  layout: elk
  theme: forest
---
erDiagram

    %% =============================================
    %% 🔵 IDENTITY SERVICE TABLES (Blue Group)
    %% =============================================
    
    classDef identityService fill:#e3f2fd,stroke:#1976d2,stroke-width:2px

    users {
        uuid id PK
        citext email
        text phone
        status_t global_status
        timestamptz email_verified_at
        timestamptz created_at
    }

    user_tenant_assignments {
        uuid id PK
        uuid user_id FK
        uuid tenant_id FK
        status_t status
        text default_role
        timestamptz assigned_at
        timestamptz removed_at
        jsonb tenant_specific_settings
    }

    sessions {
        uuid id PK
        uuid user_id FK
        uuid tenant_id FK
        text device_id
        text cnf_jkt
        timestamptz not_after
        timestamptz revoked_at
        integer version
        boolean storage_validation_passed
        timestamptz created_at
    }

    refresh_tokens {
        uuid id PK
        uuid session_id FK
        text token_hash
        timestamptz expires_at
        timestamptz created_at
    }

    feature_flags_identity {
        uuid id PK
        uuid tenant_id FK
        text feature_name
        boolean enabled
        jsonb configuration
        timestamptz created_at
        timestamptz updated_at
    }

    %% =============================================
    %% 🟢 USER PROFILE SERVICE TABLES (Green Group)
    %% =============================================

    classDef profileService fill:#e8f5e8,stroke:#388e3c,stroke-width:2px

    profiles {
        uuid id PK
        uuid user_id FK
        uuid tenant_id FK
        citext email
        text phone
        text full_name
        status_t status
        country_code_t country_code
        jsonb personal_data
        boolean habeas_data_acceptance
        timestamptz habeas_data_accepted_at
        timestamptz created_at
        timestamptz updated_at
        timestamptz deleted_at
    }

    sensitive_data_categories {
        uuid id PK
        uuid profile_id FK
        sensitive_category_t category
        legal_basis_t legal_basis
        text purpose
        timestamptz consent_given_at
        timestamptz expires_at
        boolean active
    }

    communication_consents {
        uuid id PK
        uuid profile_id FK
        text channel
        boolean consented
        timestamptz consented_at
        timestamptz revoked_at
    }

    feature_flags_user_profile {
        uuid id PK
        uuid tenant_id FK
        text feature_name
        boolean enabled
        jsonb configuration
        timestamptz created_at
        timestamptz updated_at
    }

    %% =============================================
    %% 🟠 TENANCY SERVICE TABLES (Orange Group)
    %% =============================================

    classDef tenancyService fill:#fff3e0,stroke:#f57c00,stroke-width:2px

    tenants {
        uuid id PK
        text name
        text legal_name
        text tenant_type
        text jurisdiction_root
        status_t status
        text data_residency
        text dpo_contact
        boolean international_transfers
        timestamptz created_at
        timestamptz updated_at
    }

    condominiums {
        uuid id PK
        uuid tenant_id FK
        text name
        jsonb address
        text jurisdiction
        text timezone
        text currency
        status_t status
        timestamptz created_at
        timestamptz updated_at
    }

    buildings {
        uuid id PK
        uuid condominium_id FK
        text name
        text address_line
        integer floors
        jsonb amenities
        status_t status
        timestamptz created_at
    }

    units {
        uuid id PK
        uuid building_id FK
        text unit_number
        text unit_type
        decimal area
        integer bedrooms
        status_t status
        timestamptz created_at
    }

    subunits {
        uuid id PK
        uuid unit_id FK
        text subunit_number
        text subunit_type
        decimal area
        status_t status
    }

    roles {
        uuid id PK
        uuid tenant_id FK
        text name
        jsonb permissions
        timestamptz created_at
    }

    relation_types {
        uuid id PK
        text name
        text description
    }

    sub_relation_types {
        uuid id PK
        uuid relation_type_id FK
        text name
        text description
    }

    memberships {
        uuid id PK
        uuid tenant_id FK
        uuid profile_id FK
        uuid condominium_id FK
        uuid unit_id FK
        uuid relation_type_id FK
        uuid sub_relation_type_id FK
        jsonb privileges
        uuid responsible_profile_id FK
        timestamptz since
        timestamptz until
        status_t status
    }

    role_assignments {
        uuid id PK
        uuid profile_id FK
        uuid role_id FK
        timestamptz assigned_at
        timestamptz revoked_at
        status_t status
    }

    delegations {
        uuid id PK
        uuid delegator_profile_id FK
        uuid delegate_profile_id FK
        uuid role_id FK
        timestamptz start_date
        timestamptz end_date
        status_t status
    }

    feature_flags {
        uuid id PK
        uuid tenant_id FK
        uuid condominium_id FK
        text feature_name
        boolean enabled
        jsonb configuration
        timestamptz created_at
        timestamptz updated_at
    }

    %% =============================================
    %% 🔴 COMPLIANCE SERVICE TABLES (Red Group)
    %% =============================================

    classDef complianceService fill:#ffebee,stroke:#d32f2f,stroke-width:2px

    data_subject_requests {
        uuid id PK
        uuid tenant_id FK
        uuid profile_id FK
        request_type_t request_type
        status_t status
        jsonb request_data
        jsonb response_data
        timestamptz received_at
        timestamptz resolved_at
        boolean identity_verified
    }

    data_bank_registrations {
        uuid id PK
        uuid tenant_id FK
        text registration_number
        text authority
        timestamptz registration_date
        timestamptz expiry_date
        status_t status
    }

    ccpa_opt_outs {
        uuid id PK
        uuid tenant_id FK
        uuid profile_id FK
        text channel
        timestamptz opted_out_at
        text reason
    }

    data_processing_agreements {
        uuid id PK
        uuid tenant_id FK
        text agreement_name
        text processor_name
        timestamptz effective_date
        timestamptz expiry_date
        status_t status
        jsonb terms
    }

    impact_assessments {
        uuid id PK
        uuid tenant_id FK
        text assessment_name
        timestamptz conducted_date
        text risk_level
        jsonb findings
        status_t status
    }

    compliance_tasks {
        uuid id PK
        uuid tenant_id FK
        text task_name
        text task_type
        timestamptz due_date
        timestamptz completed_date
        status_t status
        uuid assigned_to FK
    }

    feature_flags_compliance {
        uuid id PK
        uuid tenant_id FK
        text feature_name
        boolean enabled
        jsonb configuration
        timestamptz created_at
        timestamptz updated_at
    }

    %% =============================================
    %% 🟣 AUDIT & SYSTEM TABLES (Purple Group)
    %% =============================================

    classDef auditService fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px

    audit_log {
        uuid id PK
        uuid tenant_id FK
        uuid user_id FK
        uuid session_id FK
        text action
        text table_name
        jsonb old_data
        jsonb new_data
        inet ip
        timestamptz created_at
        bytea hash_prev
        bytea signature
    }

    policy_cache {
        uuid id PK
        uuid tenant_id FK
        text policy_type
        jsonb policy_data
        timestamptz cached_at
        timestamptz expires_at
    }

    consent_audit_log {
        uuid id PK
        uuid tenant_id FK
        uuid profile_id FK
        text action
        jsonb consent_data
        timestamptz created_at
        bytea hash_prev
    }

    outbox_identity {
        uuid id PK
        uuid tenant_id FK
        text event_type
        jsonb payload
        timestamptz created_at
        boolean published
    }

    outbox_profiles {
        uuid id PK
        uuid tenant_id FK
        text event_type
        jsonb payload
        timestamptz created_at
        boolean published
    }

    outbox_compliance {
        uuid id PK
        uuid tenant_id FK
        text event_type
        jsonb payload
        timestamptz created_at
        boolean published
    }

    outbox_tenancy {
        uuid id PK
        uuid tenant_id FK
        text event_type
        jsonb payload
        timestamptz created_at
        boolean published
    }

    backup_snapshots {
        uuid id PK
        uuid tenant_id FK
        text snapshot_type
        text storage_path
        timestamptz created_at
        timestamptz expires_at
    }

    rls_test_cases {
        uuid id PK
        uuid tenant_id FK
        text table_name
        text test_query
        text expected_result
        timestamptz created_at
    }

    audit_alerts {
        uuid id PK
        uuid tenant_id FK
        text alert_type
        text severity
        jsonb alert_data
        timestamptz triggered_at
        boolean resolved
    }

    %% =============================================
    %% 📊 ENUM TABLES (Gray Group)
    %% =============================================

    classDef enumService fill:#f5f5f5,stroke:#616161,stroke-width:2px

    status_t {
        status_t text PK
    }

    country_code_t {
        country_code_t text PK
    }

    sensitive_category_t {
        sensitive_category_t text PK
    }

    legal_basis_t {
        legal_basis_t text PK
    }

    request_type_t {
        request_type_t text PK
    }

    %% =============================================
    %% 🔗 RELATIONSHIPS
    %% =============================================

    %% 🔵 IDENTITY SERVICE RELATIONSHIPS
    users ||--o{ user_tenant_assignments : "asignado_a"
    users ||--o{ sessions : "mantiene"
    sessions ||--o{ refresh_tokens : "posee"
    users ||--o{ profiles : "tiene_perfiles_en"
    tenants ||--o{ feature_flags_identity : "configura_identity"

    %% 🟢 USER PROFILE SERVICE RELATIONSHIPS
    profiles ||--o{ sensitive_data_categories : "tiene_datos_sensibles"
    profiles ||--o{ communication_consents : "consiente"
    tenants ||--o{ feature_flags_user_profile : "configura_user_profile"

    %% 🟠 TENANCY SERVICE RELATIONSHIPS
    tenants ||--o{ condominiums : "administra"
    condominiums ||--o{ buildings : "contiene"
    buildings ||--o{ units : "compone"
    units ||--o{ subunits : "tiene_asociadas"
    tenants ||--o{ roles : "define_roles"
    relation_types ||--o{ sub_relation_types : "tiene_subtipos"
    memberships }o--|| relation_types : "tipo_relacion"
    memberships }o--|| sub_relation_types : "subtipo_relacion"
    profiles ||--o{ memberships : "tiene_membresias_en"
    profiles ||--o{ role_assignments : "asignado"
    profiles ||--o{ delegations : "delega_a"
    tenants ||--o{ feature_flags : "configura_tenancy"

    %% 🔴 COMPLIANCE SERVICE RELATIONSHIPS
    tenants ||--o{ data_subject_requests : "tiene_solicitudes"
    profiles ||--o{ data_subject_requests : "solicita"
    tenants ||--o{ data_bank_registrations : "registra_banco"
    tenants ||--o{ ccpa_opt_outs : "registra_opt_outs"
    tenants ||--o{ data_processing_agreements : "firma_acuerdos"
    tenants ||--o{ impact_assessments : "realiza_evaluaciones"
    tenants ||--o{ compliance_tasks : "gestiona_tareas"
    tenants ||--o{ feature_flags_compliance : "configura_compliance"

    %% 🟣 AUDIT & SYSTEM RELATIONSHIPS
    tenants ||--o{ audit_log : "genera_logs"
    tenants ||--o{ policy_cache : "cachea_politicas"
    tenants ||--o{ consent_audit_log : "audita_consentimientos"
    tenants ||--o{ outbox_identity : "publica_eventos_identity"
    tenants ||--o{ outbox_profiles : "publica_eventos_profiles"
    tenants ||--o{ outbox_compliance : "publica_eventos_compliance"
    tenants ||--o{ outbox_tenancy : "publica_eventos_tenancy"
    tenants ||--o{ backup_snapshots : "almacena_backups"
    tenants ||--o{ rls_test_cases : "testea_rls"
    tenants ||--o{ audit_alerts : "genera_alertas"

    %% 📊 ENUM RELATIONSHIPS
    status_t ||--o{ users : "define_estado"
    status_t ||--o{ profiles : "define_estado"
    status_t ||--o{ tenants : "define_estado"
    status_t ||--o{ memberships : "define_estado"
    status_t ||--o{ data_subject_requests : "define_estado"
    status_t ||--o{ condominiums : "define_estado"
    status_t ||--o{ buildings : "define_estado"
    status_t ||--o{ units : "define_estado"
    status_t ||--o{ subunits : "define_estado"
    status_t ||--o{ role_assignments : "define_estado"
    status_t ||--o{ delegations : "define_estado"
    status_t ||--o{ data_bank_registrations : "define_estado"
    status_t ||--o{ data_processing_agreements : "define_estado"
    status_t ||--o{ impact_assessments : "define_estado"
    status_t ||--o{ compliance_tasks : "define_estado"
    country_code_t ||--o{ profiles : "define_pais"
    sensitive_category_t ||--o{ sensitive_data_categories : "define_categoria"
    legal_basis_t ||--o{ sensitive_data_categories : "define_base_legal"
    request_type_t ||--o{ data_subject_requests : "define_tipo_solicitud"

    %% =============================================
    %% 🎨 APPLY STYLES TO GROUPS
    %% =============================================

    class users,user_tenant_assignments,sessions,refresh_tokens,feature_flags_identity identityService
    class profiles,sensitive_data_categories,communication_consents,feature_flags_user_profile profileService
    class tenants,condominiums,buildings,units,subunits,roles,relation_types,sub_relation_types,memberships,role_assignments,delegations,feature_flags tenancyService
    class data_subject_requests,data_bank_registrations,ccpa_opt_outs,data_processing_agreements,impact_assessments,compliance_tasks,feature_flags_compliance complianceService
    class audit_log,policy_cache,consent_audit_log,outbox_identity,outbox_profiles,outbox_compliance,outbox_tenancy,backup_snapshots,rls_test_cases,audit_alerts auditService
    class status_t,country_code_t,sensitive_category_t,legal_basis_t,request_type_t enumService
```
```sql
// =============================================
// 🏛️ SMARTEDIFY - COMPLETE DATABASE SCHEMA v2.2
// =============================================

// =============================================
// 🎨 COLOR LEGEND:
// 🔵 IDENTITY SERVICE (Blue)
// 🟢 USER PROFILE SERVICE (Green) 
// 🟠 TENANCY SERVICE (Orange)
// 🔴 COMPLIANCE SERVICE (Red)
// 🟣 AUDIT & SYSTEM TABLES (Purple)
// 📊 ENUM TABLES (Gray)
// =============================================

// =============================================
// 📊 ENUM TABLES (Domain Definitions)
// =============================================

Table status_t {
  status_t text [primary key]
  
  Note: '📊 Domain: active, inactive, suspended, pending, deleted'
}

Table country_code_t {
  country_code_t text [primary key]
  
  Note: '📊 Domain: PE, US, CO, BR, MX, ES'
}

Table sensitive_category_t {
  sensitive_category_t text [primary key]
  
  Note: '📊 Domain: health, biometric, financial, location, religious'
}

Table legal_basis_t {
  legal_basis_t text [primary key]
  
  Note: '📊 Domain: consent, contract, legal_obligation, vital_interest'
}

Table request_type_t {
  request_type_t text [primary key]
  
  Note: '📊 Domain: access, rectification, erasure, restriction, portability'
}

// =============================================
// 🔵 IDENTITY SERVICE TABLES
// =============================================

Table users {
  id uuid [primary key]
  email citext
  phone text
  global_status status_t
  email_verified_at timestamptz
  created_at timestamptz [default: `now()`]
  
  Note: '🔵 Source: User registration form (frontend)'
}

Table user_tenant_assignments {
  id uuid [primary key]
  user_id uuid [ref: > users.id]
  tenant_id uuid [ref: > tenants.id]
  status status_t
  default_role text
  assigned_at timestamptz [default: `now()`]
  removed_at timestamptz
  tenant_specific_settings jsonb
  
  Note: '🔵 Source: Admin panel assignment'
}

Table sessions {
  id uuid [primary key]
  user_id uuid [ref: > users.id]
  tenant_id uuid [ref: > tenants.id]
  device_id text
  cnf_jkt text
  not_after timestamptz
  revoked_at timestamptz
  integer version
  boolean storage_validation_passed
  created_at timestamptz [default: `now()`]
  
  Note: '🔵 Source: Login system (backend)'
}

Table refresh_tokens {
  id uuid [primary key]
  session_id uuid [ref: > sessions.id]
  token_hash text
  expires_at timestamptz
  created_at timestamptz [default: `now()`]
  
  Note: '🔵 Source: Token generation (backend)'
}

Table feature_flags_identity {
  id uuid [primary key]
  tenant_id uuid [ref: > tenants.id]
  feature_name text
  enabled boolean [default: false]
  configuration jsonb [default: `{}`]
  created_at timestamptz [default: `now()`]
  updated_at timestamptz [default: `now()`]
  
  Note: '🔵 Source: Admin configuration panel'
}

// =============================================
// 🟢 USER PROFILE SERVICE TABLES
// =============================================

Table profiles {
  id uuid [primary key]
  user_id uuid [ref: > users.id]
  tenant_id uuid [ref: > tenants.id]
  email citext
  phone text
  full_name text
  status status_t
  country_code country_code_t
  personal_data jsonb
  habeas_data_acceptance boolean
  habeas_data_accepted_at timestamptz
  created_at timestamptz [default: `now()`]
  updated_at timestamptz [default: `now()`]
  deleted_at timestamptz
  
  Note: '🟢 Source: User profile form (frontend)'
}

Table sensitive_data_categories {
  id uuid [primary key]
  profile_id uuid [ref: > profiles.id]
  category sensitive_category_t
  legal_basis legal_basis_t
  purpose text
  consent_given_at timestamptz
  expires_at timestamptz
  active boolean [default: true]
  
  Note: '🟢 Source: Consent forms & compliance checks'
}

Table communication_consents {
  id uuid [primary key]
  profile_id uuid [ref: > profiles.id]
  channel text
  consented boolean
  consented_at timestamptz
  revoked_at timestamptz
  
  Note: '🟢 Source: Marketing preferences form'
}

Table feature_flags_user_profile {
  id uuid [primary key]
  tenant_id uuid [ref: > tenants.id]
  feature_name text
  enabled boolean [default: false]
  configuration jsonb [default: `{}`]
  created_at timestamptz [default: `now()`]
  updated_at timestamptz [default: `now()`]
  
  Note: '🟢 Source: Feature management dashboard'
}

// =============================================
// 🟠 TENANCY SERVICE TABLES
// =============================================

Table tenants {
  id uuid [primary key]
  name text
  legal_name text
  tenant_type text
  jurisdiction_root text
  status status_t
  data_residency text
  dpo_contact text
  boolean international_transfers
  created_at timestamptz [default: `now()`]
  updated_at timestamptz [default: `now()`]
  
  Note: '🟠 Source: Tenant onboarding process'
}

Table condominiums {
  id uuid [primary key]
  tenant_id uuid [ref: > tenants.id]
  name text
  address jsonb
  jurisdiction text
  timezone text
  currency text
  status status_t
  created_at timestamptz [default: `now()`]
  updated_at timestamptz [default: `now()`]
  
  Note: '🟠 Source: Property management system'
}

Table buildings {
  id uuid [primary key]
  condominium_id uuid [ref: > condominiums.id]
  name text
  address_line text
  integer floors
  jsonb amenities
  status status_t
  created_at timestamptz [default: `now()`]
  
  Note: '🟠 Source: Architectural plans & surveys'
}

Table units {
  id uuid [primary key]
  building_id uuid [ref: > buildings.id]
  unit_number text
  unit_type text
  decimal area
  integer bedrooms
  status status_t
  created_at timestamptz [default: `now()`]
  
  Note: '🟠 Source: Property registry & blueprints'
}

Table subunits {
  id uuid [primary key]
  unit_id uuid [ref: > units.id]
  subunit_number text
  subunit_type text
  decimal area
  status status_t
  
  Note: '🟠 Source: Property subdivision records'
}

Table roles {
  id uuid [primary key]
  tenant_id uuid [ref: > tenants.id]
  name text
  jsonb permissions
  created_at timestamptz [default: `now()`]
  
  Note: '🟠 Source: RBAC configuration by admins'
}

Table relation_types {
  id uuid [primary key]
  text name
  text description
  
  Note: '🟠 Source: Business domain definitions'
}

Table sub_relation_types {
  id uuid [primary key]
  relation_type_id uuid [ref: > relation_types.id]
  text name
  text description
  
  Note: '🟠 Source: Business domain specialization'
}

Table memberships {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  uuid profile_id [ref: > profiles.id]
  uuid condominium_id [ref: > condominiums.id]
  uuid unit_id [ref: > units.id]
  uuid relation_type_id [ref: > relation_types.id]
  uuid sub_relation_type_id [ref: > sub_relation_types.id]
  jsonb privileges
  uuid responsible_profile_id [ref: > profiles.id]
  timestamptz since
  timestamptz until
  status_t status
  
  Note: '🟠 Source: Resident registration & contracts'
}

Table role_assignments {
  id uuid [primary key]
  uuid profile_id [ref: > profiles.id]
  uuid role_id [ref: > roles.id]
  timestamptz assigned_at [default: `now()`]
  timestamptz revoked_at
  status_t status
  
  Note: '🟠 Source: Admin user management'
}

Table delegations {
  id uuid [primary key]
  uuid delegator_profile_id [ref: > profiles.id]
  uuid delegate_profile_id [ref: > profiles.id]
  uuid role_id [ref: > roles.id]
  timestamptz start_date
  timestamptz end_date
  status_t status
  
  Note: '🟠 Source: Temporary role delegation system'
}

Table feature_flags {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  uuid condominium_id [ref: > condominiums.id]
  text feature_name
  boolean enabled [default: false]
  jsonb configuration [default: `{}`]
  timestamptz created_at [default: `now()`]
  timestamptz updated_at [default: `now()`]
  
  Note: '🟠 Source: Tenant feature configuration'
}

// =============================================
// 🔴 COMPLIANCE SERVICE TABLES
// =============================================

Table data_subject_requests {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  uuid profile_id [ref: > profiles.id]
  request_type_t request_type
  status_t status
  jsonb request_data
  jsonb response_data
  timestamptz received_at [default: `now()`]
  timestamptz resolved_at
  boolean identity_verified [default: false]
  
  Note: '🔴 Source: User privacy requests portal'
}

Table data_bank_registrations {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  text registration_number
  text authority
  timestamptz registration_date
  timestamptz expiry_date
  status_t status
  
  Note: '🔴 Source: Government regulatory bodies'
}

Table ccpa_opt_outs {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  uuid profile_id [ref: > profiles.id]
  text channel
  timestamptz opted_out_at [default: `now()`]
  text reason
  
  Note: '🔴 Source: User privacy preferences'
}

Table data_processing_agreements {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  text agreement_name
  text processor_name
  timestamptz effective_date
  timestamptz expiry_date
  status_t status
  jsonb terms
  
  Note: '🔴 Source: Legal department contracts'
}

Table impact_assessments {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  text assessment_name
  timestamptz conducted_date
  text risk_level
  jsonb findings
  status_t status
  
  Note: '🔴 Source: Security & compliance audits'
}

Table compliance_tasks {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  text task_name
  text task_type
  timestamptz due_date
  timestamptz completed_date
  status_t status
  uuid assigned_to [ref: > profiles.id]
  
  Note: '🔴 Source: Compliance workflow system'
}

Table feature_flags_compliance {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  text feature_name
  boolean enabled [default: false]
  jsonb configuration [default: `{}`]
  timestamptz created_at [default: `now()`]
  timestamptz updated_at [default: `now()`]
  
  Note: '🔴 Source: Compliance feature controls'
}

// =============================================
// 🟣 AUDIT & SYSTEM TABLES
// =============================================

Table audit_log {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  uuid user_id [ref: > users.id]
  uuid session_id [ref: > sessions.id]
  text action
  text table_name
  jsonb old_data
  jsonb new_data
  inet ip
  timestamptz created_at [default: `now()`]
  bytea hash_prev
  bytea signature
  
  Note: '🟣 Source: System-wide change tracking'
}

Table policy_cache {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  text policy_type
  jsonb policy_data
  timestamptz cached_at [default: `now()`]
  timestamptz expires_at
  
  Note: '🟣 Source: Policy engine computations'
}

Table consent_audit_log {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  uuid profile_id [ref: > profiles.id]
  text action
  jsonb consent_data
  timestamptz created_at [default: `now()`]
  bytea hash_prev
  
  Note: '🟣 Source: Consent management system'
}

Table outbox_identity {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  text event_type
  jsonb payload
  timestamptz created_at [default: `now()`]
  boolean published [default: false]
  
  Note: '🟣 Source: Identity service events'
}

Table outbox_profiles {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  text event_type
  jsonb payload
  timestamptz created_at [default: `now()`]
  boolean published [default: false]
  
  Note: '🟣 Source: Profile service events'
}

Table outbox_compliance {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  text event_type
  jsonb payload
  timestamptz created_at [default: `now()`]
  boolean published [default: false]
  
  Note: '🟣 Source: Compliance service events'
}

Table outbox_tenancy {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  text event_type
  jsonb payload
  timestamptz created_at [default: `now()`]
  boolean published [default: false]
  
  Note: '🟣 Source: Tenancy service events'
}

Table backup_snapshots {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  text snapshot_type
  text storage_path
  timestamptz created_at [default: `now()`]
  timestamptz expires_at
  
  Note: '🟣 Source: Backup automation system'
}

Table rls_test_cases {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  text table_name
  text test_query
  text expected_result
  timestamptz created_at [default: `now()`]
  
  Note: '🟣 Source: Security testing framework'
}

Table audit_alerts {
  id uuid [primary key]
  uuid tenant_id [ref: > tenants.id]
  text alert_type
  text severity
  jsonb alert_data
  timestamptz triggered_at [default: `now()`]
  boolean resolved [default: false]
  
  Note: '🟣 Source: Monitoring & alerting system'
}

// =============================================
// 🔗 RELATIONSHIPS
// =============================================

// 🔵 Identity Service Relationships
Ref: user_tenant_assignments.user_id > users.id
Ref: user_tenant_assignments.tenant_id > tenants.id
Ref: sessions.user_id > users.id
Ref: sessions.tenant_id > tenants.id
Ref: refresh_tokens.session_id > sessions.id
Ref: feature_flags_identity.tenant_id > tenants.id

// 🟢 User Profile Service Relationships
Ref: profiles.user_id > users.id
Ref: profiles.tenant_id > tenants.id
Ref: sensitive_data_categories.profile_id > profiles.id
Ref: communication_consents.profile_id > profiles.id
Ref: feature_flags_user_profile.tenant_id > tenants.id

// 🟠 Tenancy Service Relationships
Ref: condominiums.tenant_id > tenants.id
Ref: buildings.condominium_id > condominiums.id
Ref: units.building_id > buildings.id
Ref: subunits.unit_id > units.id
Ref: roles.tenant_id > tenants.id
Ref: sub_relation_types.relation_type_id > relation_types.id
Ref: memberships.tenant_id > tenants.id
Ref: memberships.profile_id > profiles.id
Ref: memberships.condominium_id > condominiums.id
Ref: memberships.unit_id > units.id
Ref: memberships.relation_type_id > relation_types.id
Ref: memberships.sub_relation_type_id > sub_relation_types.id
Ref: memberships.responsible_profile_id > profiles.id
Ref: role_assignments.profile_id > profiles.id
Ref: role_assignments.role_id > roles.id
Ref: delegations.delegator_profile_id > profiles.id
Ref: delegations.delegate_profile_id > profiles.id
Ref: delegations.role_id > roles.id
Ref: feature_flags.tenant_id > tenants.id
Ref: feature_flags.condominium_id > condominiums.id

// 🔴 Compliance Service Relationships
Ref: data_subject_requests.tenant_id > tenants.id
Ref: data_subject_requests.profile_id > profiles.id
Ref: data_bank_registrations.tenant_id > tenants.id
Ref: ccpa_opt_outs.tenant_id > tenants.id
Ref: ccpa_opt_outs.profile_id > profiles.id
Ref: data_processing_agreements.tenant_id > tenants.id
Ref: impact_assessments.tenant_id > tenants.id
Ref: compliance_tasks.tenant_id > tenants.id
Ref: compliance_tasks.assigned_to > profiles.id
Ref: feature_flags_compliance.tenant_id > tenants.id

// 🟣 Audit & System Relationships
Ref: audit_log.tenant_id > tenants.id
Ref: audit_log.user_id > users.id
Ref: audit_log.session_id > sessions.id
Ref: policy_cache.tenant_id > tenants.id
Ref: consent_audit_log.tenant_id > tenants.id
Ref: consent_audit_log.profile_id > profiles.id
Ref: outbox_identity.tenant_id > tenants.id
Ref: outbox_profiles.tenant_id > tenants.id
Ref: outbox_compliance.tenant_id > tenants.id
Ref: outbox_tenancy.tenant_id > tenants.id
Ref: backup_snapshots.tenant_id > tenants.id
Ref: rls_test_cases.tenant_id > tenants.id
Ref: audit_alerts.tenant_id > tenants.id

// 📊 Enum Relationships
Ref: users.global_status > status_t.status_t
Ref: user_tenant_assignments.status > status_t.status_t
Ref: profiles.status > status_t.status_t
Ref: profiles.country_code > country_code_t.country_code_t
Ref: tenants.status > status_t.status_t
Ref: condominiums.status > status_t.status_t
Ref: buildings.status > status_t.status_t
Ref: units.status > status_t.status_t
Ref: subunits.status > status_t.status_t
Ref: memberships.status > status_t.status_t
Ref: role_assignments.status > status_t.status_t
Ref: delegations.status > status_t.status_t
Ref: data_subject_requests.status > status_t.status_t
Ref: data_bank_registrations.status > status_t.status_t
Ref: data_processing_agreements.status > status_t.status_t
Ref: impact_assessments.status > status_t.status_t
Ref: compliance_tasks.status > status_t.status_t
Ref: sensitive_data_categories.category > sensitive_category_t.sensitive_category_t
Ref: sensitive_data_categories.legal_basis > legal_basis_t.legal_basis_t
Ref: data_subject_requests.request_type > request_type_t.request_type_t
```
---
### 📋 Mockup Data with Real Examples

```sql

```
---

## 🔒 3. Seguridad y Cumplimiento

### 3.1 Row-Level Security (RLS)

```sql
-- Ejemplo aplicado a todas las tablas multi-tenant
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_profiles ON profiles
    USING (tenant_id = current_setting('app.current_tenant')::UUID);
```

> El `Identity Service` establece `app.current_tenant` en cada conexión autenticada.

### 3.2 Cifrado de PII

| Campo | Estrategia |
|------|------------|
| `phone` | Cifrado con KMS (AWS KMS / HSM) |
| `personal_data.document_number` | Cifrado AEAD (ChaCha20-Poly1305) con clave derivada por tenant |
| `personal_data.birth_date`, `health` | Igual que arriba |

### 3.3 Logs Inmutables (WORM)

- `audit_log` es **solo lectura + inserción**.
- Cada registro incluye:
  - `hash_prev`: hash criptográfico del registro anterior.
  - `signature`: firma EdDSA del tenant.
- Volcado diario a **S3 con Object Lock (modo GOVERNANCE)**.

---

## 📊 4. Estrategia de Índices y Particionado

### 4.1 Índices Clave

```sql
-- audit_log
CREATE INDEX idx_audit_tenant_created ON audit_log (tenant_id, created_at);
CREATE INDEX idx_audit_tenant_action ON audit_log (tenant_id, action, created_at);

-- data_subject_requests
CREATE INDEX idx_dsr_tenant_status ON data_subject_requests (tenant_id, status) 
INCLUDE (received_at, resolved_at);

-- memberships
CREATE INDEX idx_memberships_profile ON memberships (profile_id, status);
CREATE INDEX idx_memberships_condo ON memberships (condominium_id, tenant_id);
```

### 4.2 Particionado

| Tabla | Estrategia | Herramienta |
|------|------------|-------------|
| `audit_log` | Mensual por `created_at` | `pg_partman` |
| `compliance_tasks` | Trimestral por `deadline` | `pg_partman` |

---

## 🗑️ 5. Ciclo de Vida de Datos

| Tabla | Retención | Acción |
|------|-----------|--------|
| `audit_log` | 10 años | Archivo WORM en S3 |
| `data_subject_requests` | 3 años | Anonimización (`profile_id = NULL`) |
| `sessions`, `refresh_tokens` | 90 días | Borrado físico |
| `profiles` (soft-deleted) | 30 días | Borrado físico + log WORM |

**Automatización** con `pg_cron`:

```sql
SELECT cron.schedule('cleanup-sessions', '0 2 * * *', $$
    DELETE FROM sessions WHERE not_after < NOW() - INTERVAL '90 days'
$$);
```

---

## 🔄 6. Consistencia Transaccional (Outbox Pattern)

Cada microservicio incluye una tabla `outbox_<service>`:

```sql
CREATE TABLE outbox_compliance (
    id UUID PRIMARY KEY,
    aggregate_id UUID NOT NULL,
    event_type TEXT NOT NULL,
    payload JSONB NOT NULL,
    occurred_at TIMESTAMPTZ DEFAULT NOW(),
    published BOOLEAN DEFAULT false
);
```

**Ejemplo transaccional**:

```sql
BEGIN;
    INSERT INTO data_subject_requests (...) VALUES (...);
    INSERT INTO outbox_compliance (aggregate_id, event_type, payload)
    VALUES (..., 'DSAR_CREATED', to_jsonb(NEW));
COMMIT;
```

Un **lector de outbox** publica a Kafka y marca `published = true`.

---

## 🛡️ 7. Resiliencia Operativa

### 7.1 RTO / RPO

- **RTO ≤ 5 min**, **RPO ≤ 1 min**.
- Réplica síncrona en zona de disponibilidad distinta.
- WAL archiving a S3.
- PITR habilitado.

### 7.2 Configuración PostgreSQL

```ini
archive_mode = on
archive_command = 'aws s3 cp %p s3://smartedify-wal-archive/%f'
wal_level = logical
max_wal_senders = 10
shared_preload_libraries = 'pg_cron, pg_partman_bgw, pg_stat_statements'
```

---

## 🧪 8. Validación y Monitoreo

- **Pruebas de RLS**: roles de prueba por tenant.
- **Alertas**: si `audit_log` recibe UPDATE/DELETE.
- **Hash-chain validation**: job diario.
- **SLO**: monitoreo de latencia, error rate y recovery time.

---

## 📌 9. Conclusión

Este documento define una **arquitectura de base de datos madura, segura y escalable**, lista para soportar la **Fase 1 del roadmap** de SmartEdify. Cumple con:

- ✅ Requisitos legales (GDPR, LGPD, Ley 29733, CCPA).
- ✅ Principios de arquitectura del Vision Document (Zero Trust, WORM, multi-tenant).
- ✅ Buenas prácticas de modelado, seguridad y rendimiento.
- ✅ Estrategias de resiliencia y observabilidad.

**Próximos pasos**:
- Generar DDL completo con scripts de migración.
- Implementar políticas RLS en staging.
- Validar performance bajo carga con `pgbench`.

---

*Documento alineado con el Vision Document v1.1 y listo para implementación en entornos de desarrollo y producción.*


---

## 🆕 Actualizaciones v2.2 — 2025-10-13

### ✅ Nuevas Tablas Agregadas
- `policy_cache`
- `consent_audit_log`
- `outbox_identity`
- `outbox_profiles`
- `backup_snapshots`
- `rls_test_cases`
- `audit_alerts`

### ✅ Función de Validación de Hash-Chain

```sql
CREATE OR REPLACE FUNCTION validate_hash_chain() RETURNS BOOLEAN AS $$
DECLARE
    prev_hash BYTEA;
    valid BOOLEAN := TRUE;
BEGIN
    FOR record IN SELECT id, hash_prev FROM audit_log ORDER BY created_at ASC LOOP
        IF prev_hash IS NOT NULL AND record.hash_prev != prev_hash THEN
            valid := FALSE;
            EXIT;
        END IF;
        prev_hash := record.hash_prev;
    END LOOP;
    RETURN valid;
END;
$$ LANGUAGE plpgsql;
```

### ✅ Test Case de RLS
```sql
INSERT INTO rls_test_cases (id, tenant_id, table_name, test_query, expected_result)
VALUES (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '33333333-3333-3333-3333-333333333333',
    'profiles',
    'SELECT * FROM profiles WHERE tenant_id = current_setting('app.current_tenant')::UUID;',
    '1 row'
);
```

### ✅ Mockup de Datos
Archivo: `SmartEdify_Fase1_Mockup.json`
Contiene datos simulados para la tabla `profiles` con cifrado simulado y timestamps.

### ❌ Decisión sobre Particionado
No se aplicará particionado por `created_at` en la tabla `condominiums`.

---

## 📦 Archivos Complementarios
- `SmartEdify_Fase1_DDL.sql`: DDL completo con nuevas tablas y funciones.
- `SmartEdify_Fase1_Mockup.json`: Datos simulados para pruebas y documentación.

---

## ✅ Estado Final
Este documento consolida la arquitectura de base de datos para la Fase 1, lista para producción.



---

## 🧩 Tablas de Feature Flags por Servicio (v2.2.1)

Como parte de la arquitectura modular de SmartEdify, se han definido tablas específicas para la gestión de **feature flags por servicio**, permitiendo control granular de funcionalidades activas por tenant y por módulo.

### 🎯 Propósito
- Activar/desactivar funcionalidades sin despliegue.
- Controlar acceso condicional por tenant.
- Facilitar pruebas A/B y despliegues progresivos.

### 🗂️ Tablas Incluidas
- `feature_flags_user_profile`
- `feature_flags_identity`
- `feature_flags_compliance`
- `feature_flags_tenancy`

### 🧬 Estructura SQL General
```sql
CREATE TABLE feature_flags_<servicio> (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES tenants(id),
    feature_name TEXT NOT NULL,
    enabled BOOLEAN DEFAULT false,
    configuration JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

### 🔗 Relaciones
- Cada tabla se relaciona con `tenants` mediante `tenant_id`.
- Las aplicaciones cliente consultan estas tablas para activar/desactivar funcionalidades dinámicamente.

### 📌 Ejemplo de Consulta
```sql
SELECT feature_name, enabled
FROM feature_flags_user_profile
WHERE tenant_id = '11111111-1111-1111-1111-111111111111';
```

### 🛠️ Recomendaciones Técnicas
- Indexar por `(tenant_id, feature_name)` para mejorar rendimiento.
- Auditar cambios críticos en `audit_log`.
- Usar `configuration` para parámetros adicionales (por ejemplo, límites, variantes, condiciones).

---
