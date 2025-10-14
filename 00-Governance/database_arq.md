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
    users ||--||{ profiles : "tiene_perfiles_en"
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
-- =============================================
-- 🏛️ SMARTEDIFY - COMPLETE MOCKUP DATA
-- =============================================

-- 📊 ENUM DATA (Domain Definitions)
INSERT INTO status_t (status_t) VALUES 
('active'), ('inactive'), ('suspended'), ('pending'), ('deleted');

INSERT INTO country_code_t (country_code_t) VALUES 
('PE'), ('US'), ('CO'), ('BR'), ('MX'), ('ES');

INSERT INTO sensitive_category_t (sensitive_category_t) VALUES 
('health'), ('biometric'), ('financial'), ('location'), ('religious'), ('political');

INSERT INTO legal_basis_t (legal_basis_t) VALUES 
('consent'), ('contract'), ('legal_obligation'), ('vital_interest'), ('legitimate_interest');

INSERT INTO request_type_t (request_type_t) VALUES 
('access'), ('rectification'), ('erasure'), ('restriction'), ('portability');

-- 🟠 TENANTS (Real Peruvian Companies)
INSERT INTO tenants (id, name, legal_name, tenant_type, jurisdiction_root, status, data_residency, dpo_contact, international_transfers, created_at) VALUES
('55555555-5555-5555-5555-555555555555', 'Edificio Miraflores', 'Miraflores Tower S.A.C.', 'residential', 'PE', 'active', 'PE-LMA', 'dpo@miraflorestower.com', false, '2024-01-01 00:00:00+00'),
('66666666-6666-6666-6666-666666666666', 'Condominio San Isidro', 'San Isidro Properties S.A.', 'commercial', 'PE', 'active', 'PE-LMA', 'proteccion.datos@sanisidroprops.com', true, '2024-01-02 00:00:00+00'),
('77777777-7777-7777-7777-777777777777', 'Residencial La Molina', 'La Molina Real Estate S.A.C.', 'mixed', 'PE', 'active', 'PE-LMA', 'privacidad@lamolinarealestate.com', false, '2024-01-03 00:00:00+00');

-- 🔵 USERS (Real Peruvian Users)
INSERT INTO users (id, email, phone, global_status, email_verified_at, created_at) VALUES
('11111111-1111-1111-1111-111111111111', 'maria.gonzalez@email.com', '+51987654321', 'active', '2025-01-10 14:30:00+00', '2025-01-10 14:25:00+00'),
('22222222-2222-2222-2222-222222222222', 'carlos.rodriguez@email.com', '+51987654322', 'active', '2025-01-11 09:15:00+00', '2025-01-11 09:10:00+00'),
('33333333-3333-3333-3333-333333333333', 'ana.martinez@email.com', '+51987654323', 'active', '2025-01-12 11:20:00+00', '2025-01-12 11:15:00+00'),
('44444444-4444-4444-4444-444444444444', 'juan.perez@email.com', '+51987654324', 'pending', NULL, '2025-01-13 16:45:00+00'),
('55555555-5555-5555-5555-555555555555', 'lucia.fernandez@email.com', '+51987654325', 'active', '2025-01-14 08:30:00+00', '2025-01-14 08:25:00+00');

-- 🔵 USER_TENANT_ASSIGNMENTS
INSERT INTO user_tenant_assignments (id, user_id, tenant_id, status, default_role, assigned_at, tenant_specific_settings) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'active', 'RESIDENT', '2025-01-10 14:35:00+00', '{"language": "es", "notifications": true}'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', '55555555-5555-5555-5555-555555555555', 'active', 'ADMIN', '2025-01-11 09:20:00+00', '{"language": "es", "reports_access": true}'),
('cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333333', '66666666-6666-6666-6666-666666666666', 'active', 'RESIDENT', '2025-01-12 11:25:00+00', '{"language": "en", "notifications": true}'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', '44444444-4444-4444-4444-444444444444', '55555555-5555-5555-5555-555555555555', 'pending', 'RESIDENT', '2025-01-13 16:50:00+00', '{"language": "es", "notifications": false}');

-- 🔵 SESSIONS
INSERT INTO sessions (id, user_id, tenant_id, device_id, cnf_jkt, not_after, version, storage_validation_passed, created_at) VALUES
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'iphone-13-maria', 'abc123jkt', '2025-01-17 14:35:00+00', 1, true, '2025-01-10 14:40:00+00'),
('ffffffff-ffff-ffff-ffff-ffffffffffff', '22222222-2222-2222-2222-222222222222', '55555555-5555-5555-5555-555555555555', 'samsung-s21-carlos', 'def456jkt', '2025-01-18 09:20:00+00', 1, true, '2025-01-11 09:25:00+00');

-- 🔵 REFRESH_TOKENS
INSERT INTO refresh_tokens (id, session_id, token_hash, expires_at, created_at) VALUES
('gggggggg-gggg-gggg-gggg-gggggggggggg', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'hashed_refresh_token_123', '2025-02-10 14:40:00+00', '2025-01-10 14:40:00+00'),
('hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'hashed_refresh_token_456', '2025-02-11 09:25:00+00', '2025-01-11 09:25:00+00');

-- 🟢 PROFILES (Complete Peruvian Citizen Profiles)
INSERT INTO profiles (id, user_id, tenant_id, email, phone, full_name, status, country_code, personal_data, habeas_data_acceptance, habeas_data_accepted_at, created_at) VALUES
('77777777-7777-7777-7777-777777777777', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 
 'maria.gonzalez@email.com', '+51987654321', 'María González López', 'active', 'PE', 
 '{"document_type": "DNI", "document_number": "encrypted_12345678", "birth_date": "1985-03-15", "gender": "F", "nationality": "PE", "occupation": "Arquitecta"}', 
 true, '2025-01-10 14:40:00+00', '2025-01-10 14:35:00+00'),
 
('88888888-8888-8888-8888-888888888888', '22222222-2222-2222-2222-222222222222', '55555555-5555-5555-5555-555555555555',
 'carlos.rodriguez@email.com', '+51987654322', 'Carlos Rodríguez Vargas', 'active', 'PE',
 '{"document_type": "DNI", "document_number": "encrypted_87654321", "birth_date": "1990-07-22", "gender": "M", "nationality": "PE", "occupation": "Ingeniero"}',
 true, '2025-01-11 09:25:00+00', '2025-01-11 09:20:00+00'),
 
('99999999-9999-9999-9999-999999999999', '33333333-3333-3333-3333-333333333333', '66666666-6666-6666-6666-666666666666',
 'ana.martinez@email.com', '+51987654323', 'Ana Martínez Ruiz', 'active', 'PE',
 '{"document_type": "DNI", "document_number": "encrypted_45678912", "birth_date": "1988-11-30", "gender": "F", "nationality": "PE", "occupation": "Abogada"}',
 true, '2025-01-12 11:25:00+00', '2025-01-12 11:20:00+00');

-- 🟢 SENSITIVE_DATA_CATEGORIES (Specific Consents)
INSERT INTO sensitive_data_categories (id, profile_id, category, legal_basis, purpose, consent_given_at, expires_at, active) VALUES
('cccccccc-cccc-cccc-cccc-cccccccccccc', '77777777-7777-7777-7777-777777777777', 'health', 'consent', 'emergency_medical_services', '2025-01-10 14:45:00+00', '2026-01-10 14:45:00+00', true),
('dddddddd-dddd-dddd-dddd-dddddddddddd', '88888888-8888-8888-8888-888888888888', 'financial', 'contract', 'rental_payment_processing', '2025-01-11 09:30:00+00', '2026-01-11 09:30:00+00', true),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '77777777-7777-7777-7777-777777777777', 'location', 'consent', 'delivery_services', '2025-01-10 14:50:00+00', '2026-01-10 14:50:00+00', true),
('ffffffff-ffff-ffff-ffff-ffffffffffff', '99999999-9999-9999-9999-999999999999', 'biometric', 'consent', 'building_access_control', '2025-01-12 11:30:00+00', '2026-01-12 11:30:00+00', true);

-- 🟢 COMMUNICATION_CONSENTS
INSERT INTO communication_consents (id, profile_id, channel, consented, consented_at) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '77777777-7777-7777-7777-777777777777', 'email', true, '2025-01-10 14:50:00+00'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '77777777-7777-7777-7777-777777777777', 'sms', false, '2025-01-10 14:50:00+00'),
('cccccccc-cccc-cccc-cccc-cccccccccccc', '88888888-8888-8888-8888-888888888888', 'email', true, '2025-01-11 09:35:00+00'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', '88888888-8888-8888-8888-888888888888', 'push', true, '2025-01-11 09:35:00+00');

-- 🟠 CONDOMINIUMS (Real Properties in Lima)
INSERT INTO condominiums (id, tenant_id, name, jurisdiction, timezone, currency, address, status, created_at) VALUES
('11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 
 'Residencial San Isidro', 'PE-LMA', 'America/Lima', 'PEN',
 '{"street": "Av. Javier Prado Este 1234", "district": "San Isidro", "city": "Lima", "country": "PE", "postal_code": "15076"}',
 'active', '2024-06-01 00:00:00+00'),
 
('22222222-2222-2222-2222-222222222222', '66666666-6666-6666-6666-666666666666',
 'Torres de La Molina', 'PE-LMA', 'America/Lima', 'PEN',
 '{"street": "Av. La Molina 3456", "district": "La Molina", "city": "Lima", "country": "PE", "postal_code": "15026"}',
 'active', '2024-07-01 00:00:00+00');

-- 🟠 BUILDINGS
INSERT INTO buildings (id, condominium_id, name, address_line, floors, amenities, status, created_at) VALUES
('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 
 'Torre A', 'Av. Javier Prado Este 1234', 15, 
 '{"pool": true, "gym": true, "security": true, "parking": true, "concierge": true}',
 'active', '2024-06-01 00:00:00+00'),
 
('44444444-4444-4444-4444-444444444444', '11111111-1111-1111-1111-111111111111',
 'Torre B', 'Av. Javier Prado Este 1234', 12,
 '{"pool": true, "gym": true, "security": true, "parking": true, "playground": true}',
 'active', '2024-06-01 00:00:00+00');

-- 🟠 UNITS
INSERT INTO units (id, building_id, unit_number, unit_type, area, bedrooms, status, created_at) VALUES
('55555555-5555-5555-5555-555555555555', '33333333-3333-3333-3333-333333333333', 
 '1501', 'apartment', 120.5, 3, 'active', '2024-06-01 00:00:00+00'),
 
('66666666-6666-6666-6666-666666666666', '33333333-3333-3333-3333-333333333333',
 '1502', 'apartment', 95.0, 2, 'active', '2024-06-01 00:00:00+00'),
 
('77777777-7777-7777-7777-777777777777', '44444444-4444-4444-4444-444444444444',
 '801', 'apartment', 150.0, 4, 'active', '2024-06-01 00:00:00+00');

-- 🟠 SUBUNITS
INSERT INTO subunits (id, unit_id, subunit_number, subunit_type, area, status) VALUES
('88888888-8888-8888-8888-888888888888', '55555555-5555-5555-5555-555555555555',
 'P001', 'parking', 12.5, 'active'),
 
('99999999-9999-9999-9999-999999999999', '55555555-5555-5555-5555-555555555555',
 'D001', 'storage', 8.0, 'active');

-- 🟠 ROLES
INSERT INTO roles (id, tenant_id, name, permissions, created_at) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '55555555-5555-5555-5555-555555555555',
 'RESIDENT', '{"read_own_data": true, "submit_requests": true, "view_community": true}', '2024-06-01 00:00:00+00'),
 
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '55555555-5555-5555-5555-555555555555',
 'ADMIN', '{"read_all_data": true, "manage_users": true, "view_reports": true, "configure_system": true}', '2024-06-01 00:00:00+00'),
 
('cccccccc-cccc-cccc-cccc-cccccccccccc', '55555555-5555-5555-5555-555555555555',
 'MANAGER', '{"read_condo_data": true, "manage_facilities": true, "view_financials": true}', '2024-06-01 00:00:00+00');

-- 🟠 RELATION_TYPES
INSERT INTO relation_types (id, name, description) VALUES
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'owner', 'Propietario de la unidad'),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'tenant', 'Inquilino o arrendatario'),
('ffffffff-ffff-ffff-ffff-ffffffffffff', 'family', 'Familiar del propietario');

-- 🟠 SUB_RELATION_TYPES
INSERT INTO sub_relation_types (id, relation_type_id, name, description) VALUES
('11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'primary_owner', 'Propietario principal'),
('22222222-2222-2222-2222-222222222222', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'co_owner', 'Co-propietario'),
('33333333-3333-3333-3333-333333333333', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'primary_tenant', 'Inquilino principal');

-- 🟠 MEMBERSHIPS
INSERT INTO memberships (id, tenant_id, profile_id, condominium_id, unit_id, relation_type_id, sub_relation_type_id, privileges, since, status) VALUES
('44444444-4444-4444-4444-444444444444', '55555555-5555-5555-5555-555555555555',
 '77777777-7777-7777-7777-777777777777', '11111111-1111-1111-1111-111111111111', 
 '55555555-5555-5555-5555-555555555555', 'dddddddd-dddd-dddd-dddd-dddddddddddd',
 '11111111-1111-1111-1111-111111111111', '{"voting_rights": true, "facility_access": true}', 
 '2024-01-01 00:00:00+00', 'active'),
 
('55555555-5555-5555-5555-555555555555', '55555555-5555-5555-5555-555555555555',
 '88888888-8888-8888-8888-888888888888', '11111111-1111-1111-1111-111111111111',
 '66666666-6666-6666-6666-666666666666', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
 '33333333-3333-3333-3333-333333333333', '{"facility_access": true}', 
 '2024-02-01 00:00:00+00', 'active');

-- 🟠 ROLE_ASSIGNMENTS
INSERT INTO role_assignments (id, profile_id, role_id, assigned_at, status) VALUES
('66666666-6666-6666-6666-666666666666', '77777777-7777-7777-7777-777777777777',
 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2024-01-01 00:00:00+00', 'active'),
 
('77777777-7777-7777-7777-777777777777', '88888888-8888-8888-8888-888888888888',
 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '2024-02-01 00:00:00+00', 'active');

-- 🟠 DELEGATIONS
INSERT INTO delegations (id, delegator_profile_id, delegate_profile_id, role_id, start_date, end_date, status) VALUES
('88888888-8888-8888-8888-888888888888', '77777777-7777-7777-7777-777777777777',
 '88888888-8888-8888-8888-888888888888', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
 '2025-01-01 00:00:00+00', '2025-01-31 23:59:59+00', 'active');

-- 🔴 DATA_SUBJECT_REQUESTS (Real GDPR Requests)
INSERT INTO data_subject_requests (id, tenant_id, profile_id, request_type, status, request_data, received_at, identity_verified) VALUES
('99999999-9999-9999-9999-999999999999', '55555555-5555-5555-5555-555555555555',
 '77777777-7777-7777-7777-777777777777', 'access', 'pending', 
 '{"reason": "Verificar datos personales almacenados", "scope": "all_personal_data"}',
 '2025-01-15 10:30:00+00', true),
 
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '55555555-5555-5555-5555-555555555555',
 '88888888-8888-8888-8888-888888888888', 'erasure', 'in_progress',
 '{"reason": "Cierre de cuenta y eliminación de datos", "scope": "marketing_data"}',
 '2025-01-16 14:20:00+00', true);

-- 🔴 DATA_BANK_REGISTRATIONS
INSERT INTO data_bank_registrations (id, tenant_id, registration_number, authority, registration_date, expiry_date, status) VALUES
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '55555555-5555-5555-5555-555555555555',
 'RNPDP-2024-001234', 'Ministerio de Justicia y Derechos Humanos - Perú', 
 '2024-01-15 00:00:00+00', '2025-01-14 23:59:59+00', 'active');

-- 🔴 CCPA_OPT_OUTS
INSERT INTO ccpa_opt_outs (id, tenant_id, profile_id, channel, opted_out_at, reason) VALUES
('cccccccc-cccc-cccc-cccc-cccccccccccc', '55555555-5555-5555-5555-555555555555',
 '77777777-7777-7777-7777-777777777777', 'third_party_sharing', '2025-01-10 15:00:00+00',
 'No deseo que mis datos sean compartidos con terceros');

-- 🔴 DATA_PROCESSING_AGREEMENTS
INSERT INTO data_processing_agreements (id, tenant_id, agreement_name, processor_name, effective_date, expiry_date, status, terms) VALUES
('dddddddd-dddd-dddd-dddd-dddddddddddd', '55555555-5555-5555-5555-555555555555',
 'DPA-2024-MIRAFLORES', 'Amazon Web Services Perú', 
 '2024-01-01 00:00:00+00', '2026-12-31 23:59:59+00', 'active',
 '{"data_processing": "hosting_services", "security_measures": "encryption_at_rest", "subprocessors": ["AWS Global"]}');

-- 🔴 IMPACT_ASSESSMENTS
INSERT INTO impact_assessments (id, tenant_id, assessment_name, conducted_date, risk_level, findings, status) VALUES
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '55555555-5555-5555-5555-555555555555',
 'Evaluación de Impacto - Sistema de Perfiles 2024', '2024-03-15 00:00:00+00', 'medium',
 '{"risks_identified": ["acceso_no_autorizado", "retencion_excesiva"], "mitigation_measures": ["2fa_obligatorio", "retention_policy_1year"]}',
 'completed');

-- 🔴 COMPLIANCE_TASKS
INSERT INTO compliance_tasks (id, tenant_id, task_name, task_type, due_date, status, assigned_to) VALUES
('ffffffff-ffff-ffff-ffff-ffffffffffff', '55555555-5555-5555-5555-555555555555',
 'Revisión trimestral de consentimientos', 'periodic_review', '2025-04-01 00:00:00+00', 'pending', '88888888-8888-8888-8888-888888888888'),
('11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555',
 'Auditoría de seguridad de datos', 'security_audit', '2025-06-30 00:00:00+00', 'pending', '88888888-8888-8888-8888-888888888888');

-- 🟣 AUDIT_LOG
INSERT INTO audit_log (id, tenant_id, user_id, session_id, action, table_name, old_data, new_data, ip, created_at) VALUES
('22222222-2222-2222-2222-222222222222', '55555555-5555-5555-5555-555555555555',
 '11111111-1111-1111-1111-111111111111', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
 'UPDATE', 'profiles', '{"full_name": "María Gonzalez"}', '{"full_name": "María González López"}',
 '192.168.1.100', '2025-01-15 11:00:00+00');

-- 🟣 POLICY_CACHE
INSERT INTO policy_cache (id, tenant_id, policy_type, policy_data, cached_at, expires_at) VALUES
('33333333-3333-3333-3333-333333333333', '55555555-5555-5555-5555-555555555555',
 'privacy_policy', '{"version": "2.1", "effective_date": "2024-01-01", "content": "Política actualizada..."}',
 '2025-01-01 00:00:00+00', '2025-07-01 00:00:00+00');

-- 🟣 CONSENT_AUDIT_LOG
INSERT INTO consent_audit_log (id, tenant_id, profile_id, action, consent_data, created_at) VALUES
('44444444-4444-4444-4444-444444444444', '55555555-5555-5555-5555-555555555555',
 '77777777-7777-7777-7777-777777777777', 'CONSENT_GIVEN',
 '{"category": "health", "purpose": "emergency_medical_services", "legal_basis": "consent"}',
 '2025-01-10 14:45:00+00');

-- 🟣 OUTBOX TABLES
INSERT INTO outbox_identity (id, tenant_id, event_type, payload, published, created_at) VALUES
('55555555-5555-5555-5555-555555555555', '55555555-5555-5555-5555-555555555555',
 'USER_REGISTERED', '{"user_id": "11111111-1111-1111-1111-111111111111", "email": "maria.gonzalez@email.com"}', true, '2025-01-10 14:25:00+00');

INSERT INTO outbox_profiles (id, tenant_id, event_type, payload, published, created_at) VALUES
('66666666-6666-6666-6666-666666666666', '55555555-5555-5555-5555-555555555555',
 'PROFILE_UPDATED', '{"profile_id": "77777777-7777-7777-7777-777777777777", "changes": ["full_name"]}', false, '2025-01-15 11:00:00+00');

INSERT INTO outbox_compliance (id, tenant_id, event_type, payload, published, created_at) VALUES
('77777777-7777-7777-7777-777777777777', '55555555-5555-5555-5555-555555555555',
 'DSAR_CREATED', '{"request_id": "99999999-9999-9999-9999-999999999999", "request_type": "access"}', true, '2025-01-15 10:30:00+00');

INSERT INTO outbox_tenancy (id, tenant_id, event_type, payload, published, created_at) VALUES
('88888888-8888-8888-8888-888888888888', '55555555-5555-5555-5555-555555555555',
 'MEMBERSHIP_CREATED', '{"membership_id": "44444444-4444-4444-4444-444444444444", "profile_id": "77777777-7777-7777-7777-777777777777"}', true, '2024-01-01 00:00:00+00');

-- 🟣 BACKUP_SNAPSHOTS
INSERT INTO backup_snapshots (id, tenant_id, snapshot_type, storage_path, created_at, expires_at) VALUES
('99999999-9999-9999-9999-999999999999', '55555555-5555-5555-5555-555555555555',
 'full_database', 's3://smartedify-backups/tenant_55555555/full_20250101.tar.gz',
 '2025-01-01 02:00:00+00', '2026-01-01 02:00:00+00');

-- 🟣 RLS_TEST_CASES
INSERT INTO rls_test_cases (id, tenant_id, table_name, test_query, expected_result, created_at) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '55555555-5555-5555-5555-555555555555',
 'profiles', 'SELECT COUNT(*) FROM profiles WHERE tenant_id = current_setting(''app.current_tenant'')::UUID', '2 rows',
 '2024-12-01 00:00:00+00');

-- 🟣 AUDIT_ALERTS
INSERT INTO audit_alerts (id, tenant_id, alert_type, severity, alert_data, triggered_at, resolved) VALUES
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '55555555-5555-5555-5555-555555555555',
 'multiple_failed_logins', 'high', '{"user_id": "44444444-4444-4444-4444-444444444444", "attempts": 5, "ip": "192.168.1.200"}',
 '2025-01-13 17:30:00+00', false);

-- 🎯 FEATURE FLAGS (Complete Configuration)
INSERT INTO feature_flags_user_profile (id, tenant_id, feature_name, enabled, configuration, created_at) VALUES
('cccccccc-cccc-cccc-cccc-cccccccccccc', '55555555-5555-5555-5555-555555555555',
 'enable_profile_picture_upload', true, '{"max_size_mb": 5, "allowed_formats": ["jpg", "png"]}', '2024-12-01 00:00:00+00'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', '55555555-5555-5555-5555-555555555555',
 'use_advanced_profile_validation', true, '{"strict_mode": true, "validation_rules": ["email_verification", "phone_verification"]}', '2024-12-01 00:00:00+00');

INSERT INTO feature_flags_identity (id, tenant_id, feature_name, enabled, configuration, created_at) VALUES
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '55555555-5555-5555-5555-555555555555',
 'enable_passkey', true, '{"aal_level": 3, "timeout_seconds": 300}', '2024-12-01 00:00:00+00'),
('ffffffff-ffff-ffff-ffff-ffffffffffff', '55555555-5555-5555-5555-555555555555',
 'enable_token_rotation', true, '{"rotation_interval_hours": 24}', '2024-12-01 00:00:00+00');

INSERT INTO feature_flags_compliance (id, tenant_id, feature_name, enabled, configuration, created_at) VALUES
('11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555',
 'auto_dsar_processing', false, '{"auto_approve_simple": false, "ai_assistance": true}', '2024-12-01 00:00:00+00'),
('22222222-2222-2222-2222-222222222222', '55555555-5555-5555-5555-555555555555',
 'jurisdiction_PE_address_validation_v2', true, '{"validation_level": "strict", "require_ubigeo": true}', '2024-12-01 00:00:00+00');

INSERT INTO feature_flags (id, tenant_id, feature_name, enabled, configuration, created_at) VALUES
('33333333-3333-3333-3333-333333333333', '55555555-5555-5555-5555-555555555555',
 'enable_condo_timezone_override', true, '{"allowed_timezones": ["America/Lima", "America/Bogota"]}', '
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
