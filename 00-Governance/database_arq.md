# Representación Gráfica del Modelo de Base de Datos

```mermaid
erDiagram
    %% =============================================
    %% IDENTITY SERVICE (3001) - Núcleo de Autenticación
    %% =============================================

    users {
        uuid id PK "UUID v4 global"
        citext email "Case-insensitive, único global"
        text phone "Cifrado KMS"
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
        timestamptz not_after
        timestamptz revoked_at
        integer version "Optimistic locking"
        boolean storage_validation_passed
        timestamptz created_at
    }

    refresh_tokens {
        uuid id PK
        uuid session_id FK
        text token_hash "SHA-256 irrevertible"
        timestamptz expires_at
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
        text code "OWNER, TENANT, FAMILY_MEMBER, etc."
        text description
        text category "RESIDENT, STAFF, GOVERNANCE, EXTERNAL"
        boolean can_vote
        boolean can_represent
        boolean requires_approval
    }

    sub_relation_types {
        uuid id PK
        uuid relation_type_id FK
        text code "PRIMARY_OWNER, CO_OWNER, SPOUSE, etc."
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

## Diagrama de Arquitectura de Microservicios

```mermaid
graph TB
    subgraph "Arquitectura de Microservicios"
        IDENTITY[Identity Service<br/>:3001]
        PROFILES[User Profiles Service<br/>:3002]
        TENANCY[Tenancy Service<br/>:3003]
        
        subgraph "Base de Datos"
            DB1[(Identity DB)]
            DB2[(Profiles DB)]
            DB3[(Tenancy DB)]
        end
        
        subgraph "Clientes"
            WEB[Web Frontend]
            MOBILE[Mobile App]
            ADMIN[Admin Portal]
        end
    end

    WEB --> IDENTITY
    MOBILE --> IDENTITY
    ADMIN --> IDENTITY
    IDENTITY --> PROFILES
    IDENTITY --> TENANCY
    PROFILES --> TENANCY
    
    IDENTITY --> DB1
    PROFILES --> DB2
    TENANCY --> DB3
```

## Flujo de Autenticación y Autorización

```mermaid
sequenceDiagram
    participant C as Cliente
    participant I as Identity Service
    participant P as Profiles Service
    participant T as Tenancy Service
    
    C->>I: Login (email/password)
    I->>I: Validar credenciales
    I->>I: Generar session + tokens
    I->>P: Obtener perfiles del usuario
    I->>C: Devolver tokens + perfiles
    
    C->>T: Request con JWT
    T->>I: Validar token
    I->>T: Token válido + datos usuario
    T->>T: Aplicar RLS por tenant_id
    T->>C: Datos solicitados
```

## Jerarquía Organizacional

```mermaid
graph TD
    subgraph "Jerarquía Multi-Tenant"
        T1[Tenant<br/>Empresa Admin]
        T2[Tenant<br/>Condominio A]
        T3[Tenant<br/>Condominio B]
        
        T1 --> C1[Condominio X]
        T1 --> C2[Condominio Y]
        T2 --> C3[Condominio Z]
        
        C1 --> B1[Edificio A]
        C1 --> B2[Edificio B]
        
        B1 --> U1[Unidad 101]
        B1 --> U2[Unidad 102]
        
        U1 --> S1[Subunidad P-101]
        U1 --> S2[Subunidad S-101]
    end
```

## Características Clave Visualizadas:

1. **Separación por Servicios**: Cada microservicio tiene su propio contexto
2. **Multi-tenancy**: `tenant_id` presente en todas las tablas principales
3. **Seguridad en Capas**: 
   - Identity (autenticación)
   - Profiles (autorización funcional)
   - RLS (seguridad a nivel de fila)
4. **Jerarquía Flexible**: Tenant → Condominio → Edificio → Unidad → Subunidad
5. **Sistema de Relaciones Complejo**: Tipos y subtipos de membresías
