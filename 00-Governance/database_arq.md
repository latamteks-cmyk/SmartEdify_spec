# Representación Gráfica Completa Actualizada - SmartEdify Databases

## 🗂️ **Diagrama ERD Completo Actualizado**

```mermaid
erDiagram
    %% =============================================
    %% IDENTITY SERVICE (3001) - Núcleo de Autenticación
    %% =============================================
    users {
        uuid id PK "UUID v4 generado al crear usuario"
        text email "Único a nivel global"
        text phone "Teléfono con código de país"
        text global_status "ACTIVE, SUSPENDED, DELETED"
        timestamptz email_verified_at "Timestamp verificación email"
        timestamptz created_at "Fecha creación registro"
    }

    user_tenant_assignments {
        uuid id PK
        uuid user_id FK
        uuid tenant_id FK
        text status "ACTIVE, SUSPENDED, REMOVED"
        text default_role "USER, ADMIN, etc."
        timestamptz assigned_at
        timestamptz removed_at
        jsonb tenant_specific_settings "Preferencias por tenant"
    }

    webauthn_credentials {
        uuid id PK "UUID v4 interno"
        uuid user_id FK "Relación con users.id"
        bytea credential_id "ID binario credencial WebAuthn"
        bytea public_key "Clave pública formato COSE"
        bigint sign_count "Contador de firmas"
        text rp_id "Relying Party ID"
        text origin "Origen HTTPS del cliente"
        timestamptz last_used_at "Último uso credencial"
        timestamptz created_at "Fecha registro credencial"
    }

    refresh_tokens {
        uuid id PK "UUID v4 token refresco"
        text token_hash "Hash SHA-256 token refresco"
        uuid user_id FK "Usuario dueño token"
        text jkt "DPoP JWK Thumbprint"
        uuid family_id "ID familia tokens"
        text device_id "Identificador dispositivo"
        uuid session_id FK "Sesión asociada token"
        timestamptz expires_at "Fecha expiración"
        boolean revoked "Indica si fue revocado"
        timestamptz created_at "Momento emisión token"
        uuid replaced_by_id "ID nuevo token que invalidó"
    }

    sessions {
        uuid id PK "UUID v4 sesión"
        uuid user_id FK "Usuario asociado"
        uuid tenant_id "Tenant activo en sesión"
        text device_id "Device_id usado en refresh_tokens"
        text cnf_jkt "DPoP confirmation thumbprint"
        timestamptz not_after "Invalida sesión después fecha"
        timestamptz revoked_at "Timestamp revocación"
        integer version "Para optimistic locking"
        boolean storage_validation_passed "Validaciones almacenamiento seguro"
    }

    feature_flags {
        uuid id PK "UUID v4 flag"
        uuid tenant_id "ID tenant aplica"
        text name "Nombre técnico flag"
        text description "Descripción legable"
        boolean enabled "Estado actual flag"
        timestamptz created_at "Fecha creación flag"
        timestamptz updated_at "Última modificación"
    }

    %% =============================================
    %% USER PROFILES SERVICE (3002) - Identidad Funcional
    %% =============================================
    profiles {
        uuid id PK
        uuid user_id FK "Vinculo con Identity Service"
        uuid tenant_id
        text email "Único por tenant"
        text phone
        text full_name
        text status "PENDING_VERIFICATION, ACTIVE, etc."
        text country_code
        jsonb personal_data "Datos personales específicos por tenant"
        timestamptz created_at
        timestamptz updated_at
        timestamptz deleted_at
    }

    relation_types {
        uuid id PK
        text code "OWNER, TENANT, FAMILY_MEMBER, etc."
        text description
        text category "RESIDENT, STAFF, GOVERNANCE, EXTERNAL"
        boolean can_vote "default: false"
        boolean can_represent "default: false"
        boolean requires_approval "default: true"
    }

    sub_relation_types {
        uuid id PK
        uuid relation_type_id FK
        text code "PRIMARY_OWNER, CO_OWNER, SPOUSE, etc."
        text description
        integer weight "Para orden en representación"
        jsonb inheritance_chain "Jerarquía de herencia de permisos"
    }

    memberships {
        uuid id PK
        uuid tenant_id
        uuid profile_id FK
        uuid condominium_id
        uuid unit_id
        text relation "OWNER, TENANT, FAMILY_MEMBER, STAFF, BOARD_MEMBER, VENDOR, etc."
        text sub_relation "PRIMARY_OWNER, CO_OWNER, SPOUSE, CHILD, etc."
        jsonb privileges "default: {}"
        uuid responsible_profile_id FK "Dueño responsable"
        timestamptz since
        timestamptz until
        text status "ACTIVE, ENDED, SUSPENDED"
    }

    roles {
        uuid id PK
        uuid tenant_id
        uuid condominium_id
        text name
        jsonb permissions "default: []"
    }

    role_assignments {
        uuid id PK
        uuid tenant_id
        uuid profile_id FK
        uuid condominium_id
        uuid role_id FK
        timestamptz granted_at "default: now()"
        timestamptz revoked_at
    }

    profile_entitlements {
        uuid id PK
        uuid tenant_id
        uuid profile_id FK
        uuid condominium_id
        text service_code
        text entitlement_key
        timestamptz granted_at "default: now()"
        timestamptz revoked_at
    }

    communication_consents {
        uuid id PK
        uuid tenant_id
        uuid profile_id FK
        text channel
        text purpose
        boolean allowed
        text policy_version
        timestamptz updated_at "default: now()"
    }

    policy_bindings {
        uuid id PK
        uuid tenant_id
        uuid condominium_id
        uuid policy_id
        text policy_version
        text scope
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
        text status "default: ACTIVE"
        text data_residency "Código región residencia datos"

        %% Datos Fiscales
        text tax_identification_type "RUC, NIF, CIF, EIN, etc."
        text tax_identification_number
        text economic_activity_code "Código actividad económica"
        text tax_residency_country
        text tax_regime_type "Régimen fiscal"
        text business_entity_type "Sociedad Anónima, SL, SA de CV, Ltda., etc."
        text commercial_registry_number
        text commercial_registry_office
        date constitution_date
        text legal_representative_tax_id "DNI/NIE representante legal"
        text legal_representative_name
        text legal_representative_nationality

        %% Datos Contacto Legal
        jsonb legal_address "Dirección legal notificaciones"
        jsonb fiscal_address "Dirección fiscal"
        jsonb authorized_signatories "Lista firmantes autorizados"

        timestamptz created_at
        timestamptz updated_at
    }

    condominiums {
        uuid id PK
        uuid tenant_id FK
        text name
        jsonb address "{street, city, country, postal_code}"
        text jurisdiction "Código país: PE, BR, CL"
        text timezone
        text currency
        text status "default: ACTIVE"

        %% Ciclo de Vida y Cumplimiento
        text current_stage "PRE_REGISTRATION, LEGAL_FORMALIZATION, OPERATIONAL, INACTIVE"
        timestamptz stage_started_at "default: now()"
        boolean is_primary "TRUE para condominios individuales"
        text compliance_status "default: PENDING_REVIEW"
        timestamptz last_compliance_check
        date next_compliance_deadline

        %% Datos Legales (Pueden ser NULL en pre-registro)
        text legal_registry_number "Número registro propiedad"
        text property_deed_number "Número escritura pública"
        date property_deed_date "Fecha escritura"
        text property_deed_notary "Notaría/autoridad registro"
        text cadastral_reference "Referencia catastral"
        integer construction_year "Año construcción"
        decimal total_land_area "Área total terreno m²"
        decimal total_built_area "Área construida total m²"
        decimal total_common_areas "Área común total m²"
        boolean horizontal_property_regime "default: true"
        text registry_office "Oficina registral"
        text registry_entry "Asiento registral"
        text legal_representative_id "DNI/RUC representante legal"
        text legal_representative_name "Nombre representante legal"
        text legal_representative_role "Cargo representante legal"
        date constitution_date "Fecha constitución condominio"
        date statutes_approval_date "Fecha aprobación estatutos"
        date last_assembly_date "Fecha última asamblea"

        timestamptz created_at
        timestamptz updated_at
    }

    buildings {
        uuid id PK
        uuid condominium_id FK
        text name
        integer floors
        jsonb address_override "Dirección específica si diferente"
        timestamptz created_at
        timestamptz updated_at
    }

    units {
        uuid id PK
        uuid building_id FK
        text unit_number "101, 102, A01, etc."
        text type "RESIDENTIAL, COMMERCIAL, PARKING, STORAGE"
        decimal area_sqm
        integer bedrooms
        integer bathrooms
        text status "default: ACTIVE"
        timestamptz created_at
        timestamptz updated_at
    }

    subunits {
        uuid id PK
        uuid unit_id FK
        text subunit_number "P-101, D-101, J-01, etc."
        text description "Estacionamiento 1, Depósito A, Jardín, etc."
        text type "PARKING, STORAGE, BALCONY, TERRACE, PATIO, GARDEN"
        decimal area_sqm
        boolean is_common_area "false: privado, true: área común"
        text access_code "Código acceso específico"
        timestamptz created_at
        timestamptz updated_at
    }

    %% =============================================
    %% TABLAS DE CICLO DE VIDA Y CUMPLIMIENTO
    %% =============================================
    condominium_lifecycle_stages {
        uuid id PK
        uuid condominium_id FK
        text stage_type "PRE_REGISTRATION, LEGAL_FORMALIZATION, OPERATIONAL, INACTIVE"
        date start_date
        date target_completion_date
        date actual_completion_date
        text status "IN_PROGRESS, COMPLETED, BLOCKED"
        jsonb required_legal_milestones "Lista hitos legales"
        timestamptz created_at
        timestamptz updated_at
    }

    country_legal_templates {
        uuid id PK
        text country_code "PE, CL, CO, MX, ES, etc."
        text template_type "CONDOMINIUM_REGISTRATION, TAX_OBLIGATIONS, LEGAL_REPRESENTATION"
        jsonb pre_registration_requirements "default: []"
        jsonb legal_formalization_requirements "default: []"
        jsonb operational_requirements "default: []"
        integer max_pre_registration_duration "Días máximos pre-registro"
        integer legal_formalization_deadline "Días completar formalización"
        jsonb compliance_alerts "Configuración alertas requisitos faltantes"
        date effective_from
        date effective_until
        text version
        timestamptz created_at
        timestamptz updated_at
    }

    compliance_requirements_tracking {
        uuid id PK
        uuid condominium_id FK
        uuid country_template_id FK
        text requirement_name
        text requirement_description
        text required_stage
        text current_status "PENDING, IN_PROGRESS, COMPLETED, OVERDUE"
        timestamptz date_identified "default: now()"
        date date_due
        timestamptz date_completed
        boolean blocking_requirement "default: false"
        text compliance_risk_level "LOW, MEDIUM, HIGH, CRITICAL"
        uuid assigned_to_profile_id "Persona responsable"
        text notes
        timestamptz created_at
        timestamptz updated_at
    }

    compliance_alerts {
        uuid id PK
        uuid tenant_id
        uuid condominium_id FK
        text alert_type "MISSING_DATA, DEADLINE_APPROACHING, REGULATORY_CHANGE"
        text alert_severity "INFO, WARNING, ERROR, CRITICAL"
        text requirement_description
        text missing_field "Campo específico faltante"
        text current_stage
        text target_stage
        date deadline
        integer days_until_deadline
        text required_action
        text action_url "URL completar acción"
        text assigned_to_role "ADMIN, LEGAL_REPRESENTATIVE, etc."
        text status "ACTIVE, ACKNOWLEDGED, RESOLVED"
        timestamptz acknowledged_at
        timestamptz resolved_at
        timestamptz created_at
        timestamptz updated_at
    }

    legal_representatives {
        uuid id PK
        uuid tenant_id
        uuid condominium_id FK "NULL si representante tenant"
        text identification_type "DNI, RUC, Pasaporte, NIE, etc."
        text identification_number
        text full_name
        text nationality
        text representative_role "Presidente, Administrador, Apoderado, etc."
        text powers_description "Descripción poderes otorgados"
        text powers_limitations "Limitaciones poderes"
        date appointment_date
        date appointment_end_date
        text appointment_act_reference "Referencia acta nombramiento"
        text email
        text phone
        jsonb address
        text status "default: ACTIVE"
        timestamptz created_at
        timestamptz updated_at
    }

    condominium_legal_records {
        uuid id PK
        uuid condominium_id FK
        uuid tenant_id "Para RLS"
        text registry_type "SUNARP, RCBR, RPP, etc."
        text registry_number
        text registry_volume
        text registry_sheet
        text registry_entry
        date registry_date
        text registration_number
        text notary_office
        text notary_name
        text notary_protocol_number
        date notary_date
        text cadastral_reference
        text cadastral_parcel
        text cadastral_sector
        date effective_from
        date effective_until
        boolean is_current "default: true"
        timestamptz created_at
        timestamptz updated_at
    }

    %% =============================================
    %% RELACIONES PRINCIPALES
    %% =============================================
    users ||--o{ user_tenant_assignments : "asignado_a"
    user_tenant_assignments }o--|| tenants : "pertenece_a"
    users ||--o{ webauthn_credentials : "tiene"
    users ||--o{ refresh_tokens : "posee"
    users ||--o{ sessions : "mantiene"
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
    
    condominiums ||--o{ condominium_lifecycle_stages : "evoluciona"
    condominiums ||--o{ compliance_requirements_tracking : "requiere"
    condominiums ||--o{ compliance_alerts : "notifica"
    condominiums ||--o{ legal_representatives : "representado_por"
    condominiums ||--o{ condominium_legal_records : "registrado_en"
    
    country_legal_templates ||--o{ compliance_requirements_tracking : "define"
    
    profiles ||--o{ role_assignments : "asignado"
    roles ||--o{ role_assignments : "asignado_en"
    profiles ||--o{ profile_entitlements : "otorgado"
    profiles ||--o{ communication_consents : "consiente"
```

## 🏗️ **Diagrama de Jerarquía Organizacional**

```mermaid
flowchart TB
    subgraph GLOBAL["Nivel Global - Identity Service"]
        U1[Usuario: carlos.rodriguez@empresa.com]
        U2[Usuario: elena.garcia@email.com]
        U3[Usuario: miguel.rodriguez@email.com]
    end

    subgraph TENANTS["Tenants - Multi-Organización"]
        T1[Administradora Primavera SA<br/>Tenant Type: ADMIN_COMPANY]
        T2[Condominio Vista Alegre<br/>Tenant Type: INDIVIDUAL_CONDOMINIUM]
        T3[Sky Towers Management<br/>Tenant Type: ADMIN_COMPANY]
    end

    subgraph C1["Condominio: Edificio Aurora"]
        B1A[Torre Principal<br/>15 pisos]
        B1B[Torre Secundaria<br/>12 pisos]
        
        B1A --> U101[Unidad 101<br/>Tipo: RESIDENTIAL]
        U101 --> S101P[Subunidad P-101<br/>Tipo: PARKING]
        U101 --> S101D[Subunidad D-101<br/>Tipo: STORAGE]
        
        B1A --> U115[Unidad 1501<br/>Tipo: PENTHOUSE]
        U115 --> S115P1[Subunidad P-1501<br/>Tipo: PARKING]
        U115 --> S115P2[Subunidad P-1502<br/>Tipo: PARKING]
    end

    subgraph C2["Condominio: Vista Alegre"]
        B2A[Edificio Único<br/>5 pisos]
        B2A --> U201[Unidad Casa 01<br/>Tipo: RESIDENTIAL]
        U201 --> S201J[Subunidad J-01<br/>Tipo: GARDEN]
    end

    subgraph C3["Condominio: Sky Tower Miami"]
        B3A[Main Tower<br/>25 pisos]
        B3A --> U301[Unidad 3201<br/>Tipo: COMMERCIAL]
    end

    %% Relaciones de usuarios con tenants
    U1 --> T1
    U1 --> T2
    U1 --> T3
    U2 --> T1
    U2 --> T2
    U3 --> T1

    %% Relaciones de tenants con condominios
    T1 --> C1
    T1 --> C2
    T2 --> C2
    T3 --> C3

    %% Estilos
    classDef user fill:#e1f5fe,stroke:#01579b
    classDef tenant fill:#f3e5f5,stroke:#4a148c
    classDef condominium fill:#fff3e0,stroke:#e65100
    classDef building fill:#f1f8e9,stroke:#33691e
    classDef unit fill:#e0f2f1,stroke:#004d40
    classDef subunit fill:#fce4ec,stroke:#880e4f
    
    class U1,U2,U3 user
    class T1,T2,T3 tenant
    class C1,C2,C3 condominium
    class B1A,B1B,B2A,B3A building
    class U101,U115,U201,U301 unit
    class S101P,S101D,S115P1,S115P2,S201J subunit
```

## 🔐 **Esquema de Seguridad Multi-Tenant**

```mermaid
flowchart TD
    subgraph IDENTITY_SEC["Identity Service Security"]
        A1[RLS: users - por user_id]
        A2[RLS: sessions - por tenant_id + user_id]
        A3[RLS: user_tenant_assignments - por user_id]
        A4[RLS: feature_flags - por tenant_id]
    end

    subgraph PROFILES_SEC["User Profiles Security"]
        B1[RLS: profiles - por tenant_id]
        B2[RLS: memberships - por tenant_id]
        B3[RLS: roles - por tenant_id + condominium_id]
        B4[RLS: role_assignments - por tenant_id]
    end

    subgraph TENANCY_SEC["Tenancy Service Security"]
        C1[RLS: tenants - por tenant_id]
        C2[RLS: condominiums - por tenant_id]
        C3[RLS: buildings - por condominium_id en tenant]
        C4[RLS: units - por building_id en tenant]
        C5[RLS: subunits - por unit_id en tenant]
    end

    subgraph COMPLIANCE_SEC["Compliance Security"]
        D1[RLS: compliance_alerts - por tenant_id]
        D2[RLS: legal_representatives - por tenant_id]
        D3[RLS: country_legal_templates - por country_code]
    end

    A1 --> A2
    A2 --> A3
    A3 --> A4
    
    B1 --> B2
    B2 --> B3
    B3 --> B4
    
    C1 --> C2
    C2 --> C3
    C3 --> C4
    C4 --> C5
    
    D1 --> D2
    D2 --> D3

    classDef rls fill:#fff3e0,stroke:#e65100
    class A1,A2,A3,A4,B1,B2,B3,B4,C1,C2,C3,C4,C5,D1,D2,D3 rls
```

## 🔄 **Flujo de Datos entre Servicios**

```mermaid
flowchart LR
    subgraph IDENTITY["Identity Service (3001)"]
        A1[users]
        A2[user_tenant_assignments]
        A3[sessions]
    end

    subgraph PROFILES["User Profiles Service (3002)"]
        B1[profiles]
        B2[memberships]
        B3[relation_types]
        B4[roles]
    end

    subgraph TENANCY["Tenancy Service (3003)"]
        C1[tenants]
        C2[condominiums]
        C3[buildings]
        C4[units]
        C5[subunits]
    end

    subgraph COMPLIANCE["Compliance Engine"]
        D1[country_legal_templates]
        D2[compliance_requirements_tracking]
        D3[compliance_alerts]
    end

    %% Flujos principales
    A1 -- "user_id" --> B1
    A2 -- "tenant_id" --> C1
    B1 -- "profile_id" --> B2
    B2 -- "condominium_id, unit_id" --> C2
    C2 -- "jurisdiction" --> D1
    D1 -- "requirements" --> D2
    D2 -- "alerts" --> D3
    
    %% Flujos secundarios
    A3 -- "tenant_id" --> C1
    B2 -- "relation types" --> B3
    B4 -- "role assignments" --> B2
    
    style IDENTITY fill:#e1f5fe
    style PROFILES fill:#f3e5f5
    style TENANCY fill:#fff3e0
    style COMPLIANCE fill:#f1f8e9
```

## 📊 **Mockup de Datos - Escenario Real Completo**

```sql
-- =============================================
-- IDENTITY SERVICE - Usuarios Globales
-- =============================================
INSERT INTO users (id, email, phone, global_status, created_at) VALUES
('u001', 'carlos.rodriguez@empresa.com', '+51987654321', 'ACTIVE', '2023-05-10 09:00:00'),
('u002', 'elena.garcia@email.com', '+51987654322', 'ACTIVE', '2023-05-10 09:00:00'),
('u003', 'miguel.rodriguez@email.com', '+51987654323', 'ACTIVE', '2023-08-15 14:30:00'),
('u004', 'ana.lopez@proveedor.com', '+51987654324', 'ACTIVE', '2024-01-20 11:00:00');

-- =============================================
-- TENANTS - Organizaciones
-- =============================================
INSERT INTO tenants (id, name, legal_name, tenant_type, tax_identification_number, jurisdiction_root) VALUES
('t001', 'Administradora Primavera SA', 'Administradora Primavera Sociedad Anónima', 'ADMIN_COMPANY', '20123456781', 'PE'),
('t002', 'Condominio Vista Alegre', 'Condominio Vista Alegre', 'INDIVIDUAL_CONDOMINIUM', '20123456782', 'PE'),
('t003', 'Sky Towers Management', 'Sky Towers Management LLC', 'ADMIN_COMPANY', '123456789', 'US');

-- =============================================
-- ASIGNACIONES MULTI-TENANT
-- =============================================
INSERT INTO user_tenant_assignments (id, user_id, tenant_id, status, default_role) VALUES
-- Carlos Rodríguez en 3 tenants diferentes
('uta001', 'u001', 't001', 'ACTIVE', 'USER'),
('uta002', 'u001', 't002', 'ACTIVE', 'USER'),
('uta003', 'u001', 't003', 'ACTIVE', 'ADMIN'),

-- Elena García en 2 tenants
('uta004', 'u002', 't001', 'ACTIVE', 'USER'),
('uta005', 'u002', 't002', 'ACTIVE', 'USER'),

-- Miguel Rodríguez en 1 tenant
('uta006', 'u003', 't001', 'ACTIVE', 'USER'),

-- Ana López como proveedor
('uta007', 'u004', 't001', 'ACTIVE', 'VENDOR');

-- =============================================
-- USER PROFILES - Perfiles por Tenant
-- =============================================
INSERT INTO profiles (id, user_id, tenant_id, email, full_name, status) VALUES
-- Carlos en diferentes tenants
('p001', 'u001', 't001', 'carlos.rodriguez@empresa.com', 'Carlos Rodríguez', 'ACTIVE'),
('p002', 'u001', 't002', 'carlos.rodriguez@empresa.com', 'Carlos Rodríguez', 'ACTIVE'),
('p003', 'u001', 't003', 'carlos@sky-towers.com', 'Carlos Rodríguez - Director', 'ACTIVE'),

-- Elena en diferentes tenants
('p004', 'u002', 't001', 'elena.garcia@email.com', 'Elena García de Rodríguez', 'ACTIVE'),
('p005', 'u002', 't002', 'elena.garcia@email.com', 'Elena García', 'ACTIVE'),

-- Miguel en un tenant
('p006', 'u003', 't001', 'miguel.rodriguez@email.com', 'Miguel Rodríguez García', 'ACTIVE'),

-- Ana como proveedor
('p007', 'u004', 't001', 'ana.lopez@proveedor.com', 'Ana López - Limpieza Profesional', 'ACTIVE');

-- =============================================
-- TIPOS DE RELACIÓN
-- =============================================
INSERT INTO relation_types (id, code, description, category, can_vote, can_represent) VALUES
('rt001', 'OWNER', 'Propietario', 'RESIDENT', true, true),
('rt002', 'TENANT', 'Inquilino', 'RESIDENT', true, false),
('rt003', 'FAMILY_MEMBER', 'Familiar', 'RESIDENT', false, false),
('rt004', 'BOARD_MEMBER', 'Miembro Junta Directiva', 'GOVERNANCE', true, true),
('rt005', 'VENDOR', 'Proveedor', 'EXTERNAL', false, false);

INSERT INTO sub_relation_types (id, relation_type_id, code, description, weight) VALUES
-- Para OWNER
('srt001', 'rt001', 'PRIMARY_OWNER', 'Propietario Principal', 100),
('srt002', 'rt001', 'CO_OWNER', 'Co-Propietario', 90),

-- Para TENANT
('srt003', 'rt002', 'PRIMARY_TENANT', 'Inquilino Principal', 80),

-- Para FAMILY_MEMBER
('srt004', 'rt003', 'SPOUSE', 'Cónyuge', 60),
('srt005', 'rt003', 'CHILD', 'Hijo', 50),

-- Para BOARD_MEMBER
('srt006', 'rt004', 'PRESIDENT', 'Presidente', 200),
('srt007', 'rt004', 'TREASURER', 'Tesorero', 180);

-- =============================================
-- ESTRUCTURA FÍSICA
-- =============================================
INSERT INTO condominiums (id, tenant_id, name, jurisdiction, current_stage) VALUES
('c001', 't001', 'Edificio Aurora', 'PE', 'OPERATIONAL'),
('c002', 't001', 'Residencial Sol', 'PE', 'OPERATIONAL'),
('c003', 't002', 'Condominio Vista Alegre', 'PE', 'OPERATIONAL'),
('c004', 't003', 'Sky Tower Miami', 'US', 'LEGAL_FORMALIZATION');

INSERT INTO buildings (id, condominium_id, name, floors) VALUES
('b001', 'c001', 'Torre Principal', 15),
('b002', 'c001', 'Torre Secundaria', 12),
('b003', 'c003', 'Edificio Único', 5);

INSERT INTO units (id, building_id, unit_number, type, area_sqm, status) VALUES
-- Edificio Aurora
('u00101', 'b001', '101', 'RESIDENTIAL', 85.5, 'ACTIVE'),
('u00102', 'b001', '102', 'RESIDENTIAL', 75.0, 'ACTIVE'),
('u00115', 'b001', '1501', 'PENTHOUSE', 180.0, 'ACTIVE'),

-- Residencial Sol
('u00201', 'b002', '201', 'RESIDENTIAL', 90.0, 'ACTIVE'),

-- Vista Alegre
('u00301', 'b003', 'Casa 01', 'RESIDENTIAL', 120.0, 'ACTIVE');

INSERT INTO subunits (id, unit_id, subunit_number, type, description, area_sqm, is_common_area) VALUES
-- Estacionamientos y depósitos para Dept 101
('s001', 'u00101', 'P-101', 'PARKING', 'Estacionamiento cubierto #1', 12.5, false),
('s002', 'u00101', 'D-101', 'STORAGE', 'Depósito en sótano', 8.0, false),

-- Estacionamientos para Penthouse
('s003', 'u00115', 'P-1501', 'PARKING', 'Estacionamiento VIP #1', 15.0, false),
('s004', 'u00115', 'P-1502', 'PARKING', 'Estacionamiento VIP #2', 15.0, false),

-- Jardín privado para casa en Vista Alegre
('s005', 'u00301', 'J-01', 'GARDEN', 'Jardín privado', 45.0, false);

-- =============================================
-- MEMBRESÍAS COMPLEJAS
-- =============================================
INSERT INTO memberships (id, tenant_id, profile_id, condominium_id, unit_id, relation, sub_relation, status, since) VALUES
-- Carlos: Propietario Principal en Edificio Aurora
('m001', 't001', 'p001', 'c001', 'u00101', 'OWNER', 'PRIMARY_OWNER', 'ACTIVE', '2020-03-15'),
('m002', 't001', 'p001', 'c001', 's001', 'OWNER', 'PRIMARY_OWNER', 'ACTIVE', '2020-03-15'),
('m003', 't001', 'p001', 'c001', 's002', 'OWNER', 'PRIMARY_OWNER', 'ACTIVE', '2020-03-15'),

-- Carlos: Inquilino Principal en Residencial Sol
('m004', 't001', 'p001', 'c002', 'u00201', 'TENANT', 'PRIMARY_TENANT', 'ACTIVE', '2023-01-01'),

-- Carlos: Propietario Principal en Vista Alegre
('m005', 't002', 'p002', 'c003', 'u00301', 'OWNER', 'PRIMARY_OWNER', 'ACTIVE', '2018-07-20'),
('m006', 't002', 'p002', 'c003', 's005', 'OWNER', 'PRIMARY_OWNER', 'ACTIVE', '2018-07-20'),

-- Elena: Co-Propietaria en Edificio Aurora
('m007', 't001', 'p004', 'c001', 'u00101', 'OWNER', 'CO_OWNER', 'ACTIVE', '2020-03-15'),

-- Elena: Co-Propietaria en Vista Alegre
('m008', 't002', 'p005', 'c003', 'u00301', 'OWNER', 'CO_OWNER', 'ACTIVE', '2018-07-20'),

-- Miguel: Familiar (Hijo) en Edificio Aurora
('m009', 't001', 'p006', 'c001', 'u00101', 'FAMILY_MEMBER', 'CHILD', 'ACTIVE', '2020-03-15'),

-- Carlos: Presidente Junta Directiva en Sky Tower Miami
('m010', 't003', 'p003', 'c004', NULL, 'BOARD_MEMBER', 'PRESIDENT', 'ACTIVE', '2022-11-01'),

-- Ana: Proveedor de servicios en Edificio Aurora
('m011', 't001', 'p007', 'c001', NULL, 'VENDOR', NULL, 'ACTIVE', '2024-01-20');
```

## 🎯 **Consultas de Ejemplo para Escenarios Complejos**

### **1. Encontrar todas las propiedades de un usuario multi-tenant:**
```sql
SELECT 
    u.email as "Usuario Global",
    t.name as "Tenant",
    t.tenant_type as "Tipo Tenant",
    c.name as "Condominio",
    b.name as "Edificio",
    un.unit_number as "Unidad",
    s.subunit_number as "Subunidad",
    s.type as "Tipo Subunidad",
    m.relation as "Relación",
    m.sub_relation as "Sub-Relación",
    rt.can_vote as "Puede Votar",
    rt.can_represent as "Puede Representar"
FROM users u
JOIN user_tenant_assignments uta ON u.id = uta.user_id
JOIN tenants t ON uta.tenant_id = t.id
JOIN profiles p ON u.id = p.user_id AND t.id = p.tenant_id
JOIN memberships m ON p.id = m.profile_id
LEFT JOIN condominiums c ON m.condominium_id = c.id
LEFT JOIN buildings b ON c.id = b.condominium_id
LEFT JOIN units un ON m.unit_id = un.id
LEFT JOIN subunits s ON m.unit_id = s.unit_id
JOIN relation_types rt ON m.relation = rt.code
WHERE u.email = 'carlos.rodriguez@empresa.com'
AND m.status = 'ACTIVE'
ORDER BY t.name, c.name, un.unit_number;
```

### **2. Miembros con capacidad de voto por condominio:**
```sql
SELECT 
    c.name as "Condominio",
    p.full_name as "Nombre",
    m.relation as "Relación",
    m.sub_relation as "Sub-Relación",
    un.unit_number as "Unidad",
    rt.can_vote as "Puede Votar",
    rt.can_represent as "Puede Representar"
FROM memberships m
JOIN profiles p ON m.profile_id = p.id
JOIN condominiums c ON m.condominium_id = c.id
JOIN relation_types rt ON m.relation = rt.code
LEFT JOIN units un ON m.unit_id = un.id
WHERE c.id = 'c001'
AND m.status = 'ACTIVE'
AND rt.can_vote = true
ORDER BY rt.can_represent DESC, p.full_name;
```

### **3. Resumen de propiedades por usuario:**
```sql
SELECT 
    u.email,
    COUNT(DISTINCT uta.tenant_id) as "Tenants Activos",
    COUNT(DISTINCT m.condominium_id) as "Condominios",
    COUNT(DISTINCT CASE WHEN m.relation = 'OWNER' THEN m.unit_id END) as "Propiedades Propias",
    COUNT(DISTINCT CASE WHEN m.relation = 'TENANT' THEN m.unit_id END) as "Propiedades Alquiladas",
    COUNT(DISTINCT s.id) as "Subunidades"
FROM users u
JOIN user_tenant_assignments uta ON u.id = uta.user_id AND uta.status = 'ACTIVE'
JOIN profiles p ON u.id = p.user_id AND uta.tenant_id = p.tenant_id
JOIN memberships m ON p.id = m.profile_id AND m.status = 'ACTIVE'
LEFT JOIN subunits s ON m.unit_id = s.unit_id
GROUP BY u.id, u.email
ORDER BY "Propiedades Propias" DESC;
```

Esta representación gráfica actualizada incorpora todas las mejoras identificadas:
- ✅ **Subunidades como propiedades independientes** (estacionamientos, depósitos, jardines)
- ✅ **Soporte completo para usuarios multi-tenant y multi-condominio**
- ✅ **Sistema de tipos y sub-tipos de relación complejos**
- ✅ **Estructura legal y fiscal completa**
- ✅ **Ciclo de vida y cumplimiento progresivo**
- ✅ **Escenarios reales con datos de ejemplo**
- ✅ **Consultas útiles para operaciones complejas**
