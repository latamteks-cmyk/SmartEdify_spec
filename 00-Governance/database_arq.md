# SmartEdify · Arquitectura de Datos Actualizada (Implementación Completa)

## 🔄 Modificaciones Implementadas

### 1. Desnormalización de `tenant_id` y RLS Optimizado

```erDiagram
    %% =============================================
    %% IDENTITY SERVICE (3001) - Núcleo de Autenticación
    %% =============================================
    users {
        uuid id PK "UUID v4 global"
        citext email "Case-insensitive, único global"
        text phone "Cifrado KMS (no almacenado en claro)"
        text global_status "ACTIVE, SUSPENDED, DELETED"
        timestamptz email_verified_at
        timestamptz created_at
    }

    user_tenant_assignments {
        uuid id PK
        uuid user_id FK
        uuid tenant_id FK
        text status "ACTIVE, SUSPENDED, REMOVED"
        text default_role "USER, ADMIN, etc."
        timestamptz assigned_at
        timestamptz removed_at
        jsonb tenant_specific_settings
    }

    sessions {
        uuid id PK
        uuid user_id FK
        uuid tenant_id "Desnormalizado para RLS"
        text device_id
        text cnf_jkt "DPoP confirmation thumbprint"
        timestamptz not_after "Clave para particionado"
        timestamptz revoked_at
        integer version "Optimistic locking"
        boolean storage_validation_passed "Validación explícita desde frontend"
        timestamptz created_at
    }

    refresh_tokens {
        uuid id PK
        uuid session_id FK
        text token_hash "SHA-256 irrevertible"
        timestamptz expires_at "Clave para particionado"
        timestamptz created_at
    }

    feature_flags {
        uuid id PK
        uuid tenant_id "Desnormalizado para RLS"
        text name
        text description
        boolean enabled
        timestamptz created_at
        timestamptz updated_at
    }

    %% =============================================
    %% USER PROFILES SERVICE (3002) - Identidad Funcional
    %% =============================================
    profiles {
        uuid id PK
        uuid user_id FK
        uuid tenant_id "Desnormalizado para RLS"
        citext email "Único por tenant"
        text phone "Cifrado KMS"
        text full_name
        text status "PENDING_VERIFICATION, ACTIVE, etc."
        text country_code
        jsonb personal_data
        timestamptz created_at
        timestamptz updated_at
        timestamptz deleted_at
    }

    relation_types {
        uuid id PK
        text code "OWNER, TENANT, FAMILY_MEMBER, BOARD_MEMBER, VENDOR"
        text description
        text category "RESIDENT, STAFF, GOVERNANCE, EXTERNAL"
        boolean can_vote
        boolean can_represent
        boolean requires_approval
    }

    sub_relation_types {
        uuid id PK
        uuid relation_type_id FK
        text code "PRIMARY_OWNER, CO_OWNER, SPOUSE, PRESIDENT, etc."
        text description
        integer weight
        jsonb inheritance_chain
    }

    memberships {
        uuid id PK
        uuid tenant_id "Desnormalizado para RLS"
        uuid profile_id FK
        uuid condominium_id
        uuid unit_id
        text relation
        text sub_relation
        jsonb privileges
        uuid responsible_profile_id FK
        timestamptz since
        timestamptz until
        text status "ACTIVE, ENDED, SUSPENDED"
    }

    roles {
        uuid id PK
        uuid tenant_id "Desnormalizado para RLS"
        uuid condominium_id
        text name
        jsonb permissions
    }

    role_assignments {
        uuid id PK
        uuid tenant_id "Desnormalizado para RLS"
        uuid profile_id FK
        uuid condominium_id
        uuid role_id FK
        timestamptz granted_at
        timestamptz revoked_at
    }

    delegations {
        uuid id PK
        uuid delegator_profile_id FK
        uuid delegate_profile_id FK
        uuid condominium_id FK
        uuid tenant_id "Desnormalizado para RLS"
        text scope
        timestamptz expires_at
        timestamptz revoked_at
        timestamptz created_at
    }

    communication_consents {
        uuid id PK
        uuid tenant_id "Desnormalizado para RLS"
        uuid profile_id FK
        text channel
        text purpose
        boolean allowed
        text policy_version
        timestamptz updated_at
    }

    %% =============================================
    %% TENANCY SERVICE (3003) - Raíz Organizacional
    %% =============================================
    tenants {
        uuid id PK
        text name
        text legal_name
        text tenant_type "ADMIN_COMPANY | INDIVIDUAL_CONDOMINIUM"
        text jurisdiction_root
        text status
        text data_residency
        timestamptz created_at
        timestamptz updated_at
    }

    condominiums {
        uuid id PK
        uuid tenant_id "Desnormalizado para RLS"
        text name
        jsonb address
        text jurisdiction "PE, BR, CL, CO, US, ES"
        text timezone
        text currency
        text status
        timestamptz created_at
        timestamptz updated_at
    }

    buildings {
        uuid id PK
        uuid tenant_id "Desnormalizado para RLS"
        uuid condominium_id FK
        text name
        integer floors
        jsonb address_override
        timestamptz created_at
        timestamptz updated_at
    }

    units {
        uuid id PK
        uuid tenant_id "Desnormalizado para RLS"
        uuid building_id FK
        text unit_number "101, A01, Casa-01"
        text type "RESIDENTIAL, COMMERCIAL, PARKING, STORAGE"
        decimal area_sqm
        integer bedrooms
        integer bathrooms
        text status
        timestamptz created_at
        timestamptz updated_at
    }

    subunits {
        uuid id PK
        uuid tenant_id "Desnormalizado para RLS"
        uuid unit_id FK
        text subunit_number "P-101, D-101, J-01"
        text description
        text type "PARKING, STORAGE, GARDEN, BALCONY"
        decimal area_sqm
        boolean is_common_area
        text access_code
        timestamptz created_at
        timestamptz updated_at
    }

    %% =============================================
    %% CUMPLIMIENTO Y AUDITORÍA
    %% =============================================
    compliance_tasks {
        uuid id PK
        uuid tenant_id "Desnormalizado para RLS"
        text task_type
        text status
        timestamptz deadline
        timestamptz created_at
    }

    audit_log {
        uuid id PK
        uuid tenant_id "Desnormalizado para RLS"
        uuid user_id
        uuid session_id
        text action
        text table_name
        jsonb old_data
        jsonb new_data
        inet ip
        timestamptz created_at
    }

    %% =============================================
    %% RELACIONES PRINCIPALES
    %% =============================================
    users ||--o{ user_tenant_assignments : "asignado_a"
    user_tenant_assignments }o--|| tenants : "pertenece_a"
    users ||--o{ sessions : "mantiene"
    sessions ||--o{ refresh_tokens : "posee"
    tenants ||--o{ feature_flags : "configura"

    users ||--o{ profiles : "tiene_perfiles_en"
    profiles ||--o{ memberships : "tiene_membresias_en"
    relation_types ||--o{ sub_relation_types : "tiene_subtipos"
    memberships }o--|| relation_types : "tipo_relacion"
    memberships }o--|| sub_relation_types : "subtipo_relacion"

    tenants ||--o{ condominiums : "administra"
    condominiums ||--o{ buildings : "contiene"
    buildings ||--o{ units : "compone"
    units ||--o{ subunits : "tiene_asociadas"

    profiles ||--o{ role_assignments : "asignado"
    roles ||--o{ role_assignments : "asignado_en"
    profiles ||--o{ delegations : "delega_a"
    profiles ||--o{ communication_consents : "consiente"
```
