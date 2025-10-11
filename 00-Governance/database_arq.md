Claro. A continuación, se presenta la **versión corregida del archivo `database_arq.md`**, actualizada para cerrar los gaps identificados, especialmente:

- Añadir **`jurisdiction` en `sessions`** para soporte de cumplimiento en tiempo real.
- Incluir **`condominium_id` opcional en `refresh_tokens`** para flujos contextuales por condominio.
- Agregar tabla **`delegations`** en `user_profiles` para apoderados temporales.
- Clarificar el contrato de **`storage_validation_passed`**.
- Corregir la relación entre `profiles.user_id` y `users.id` con una nota de coherencia referencial en entornos globales.

---

```markdown
# Representación Gráfica Completa Actualizada - SmartEdify Databases

## 🗂️ Diagrama ERD Completo Actualizado

```erDiagram
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
        uuid condominium_id FK "Condominio contextual (opcional)"
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
        text jurisdiction "Jurisdicción activa (PE, BR, CL, etc.)"
        timestamptz not_after "Invalida sesión después fecha"
        timestamptz revoked_at "Timestamp revocación"
        integer version "Para optimistic locking"
        boolean storage_validation_passed "Validaciones almacenamiento seguro (true solo si frontend pasa validación explícita vía header X-Storage-Validated)"
    }

    feature_flags {
        uuid id PK "UUID v4 flag"
        uuid tenant_id "ID tenant aplica"
        text name "Nombre técnico flag"
        text description "Descripción legible"
        boolean enabled "Estado actual flag"
        timestamptz created_at "Fecha creación flag"
        timestamptz updated_at "Última modificación"
    }

    %% =============================================
    %% USER PROFILES SERVICE (3002) - Identidad Funcional
    %% =============================================
    profiles {
        uuid id PK
        uuid user_id FK "Vinculo con Identity Service (global)"
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

    delegations {
        uuid id PK
        uuid delegator_profile_id FK "Perfil que delega"
        uuid delegate_profile_id FK "Perfil delegado"
        uuid condominium_id FK "Condominio donde aplica la delegación"
        text scope "Ej: assembly:123, vote:2025-10-15"
        timestamptz expires_at "TTL de la delegación"
        timestamptz revoked_at "Revocación anticipada"
        timestamptz created_at "default: now()"
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
    profiles ||--o{ delegations : "delega_a"
```

## 🏗️ Diagrama de Jerarquía Organizacional

*(Sin cambios respecto a la versión anterior — sigue siendo correcto y coherente)*

## 🔐 Esquema de Seguridad Multi-Tenant

*(Sin cambios — RLS ya cubre correctamente todos los niveles)*

## 🔄 Flujo de Datos entre Servicios

*(Actualizado implícitamente por nuevas relaciones)*

## 📊 Mockup de Datos - Escenario Real Completo

*(Sin cambios — los ejemplos siguen siendo válidos)*

## 🎯 Consultas de Ejemplo para Escenarios Complejos

### 4. Delegaciones activas por condominio

```sql
SELECT 
    dpr.full_name as "Delegador",
    dte.full_name as "Delegado",
    c.name as "Condominio",
    d.scope,
    d.expires_at
FROM delegations d
JOIN profiles dpr ON d.delegator_profile_id = dpr.id
JOIN profiles dte ON d.delegate_profile_id = dte.id
JOIN condominiums c ON d.condominium_id = c.id
WHERE d.expires_at > NOW()
AND d.revoked_at IS NULL
ORDER BY c.name, d.expires_at;
```

## 📝 Notas Técnicas Adicionales

- **`profiles.user_id`**: Apunta a `users.id` global. En entornos con sharding global, la integridad referencial se garantiza a nivel de aplicación, no mediante FK estricta, para permitir replicación multi-región.
- **`storage_validation_passed`**: Solo se establece en `true` si el frontend envía el header `X-Storage-Validated: true` durante el login. De lo contrario, permanece en `false`.
- **`refresh_tokens.condominium_id`**: Opcional. Si se proporciona, el token solo es válido en el contexto de ese condominio (usado en flujos como login desde app de condominio específico).
- **`sessions.jurisdiction`**: Derivado de `condominiums.jurisdiction` al iniciar sesión. Usado por `compliance-service` para aplicar políticas correctas en tiempo real.

---

Esta representación gráfica actualizada **cierra todos los gaps críticos** identificados y **refuerza la coherencia entre identidad, contexto organizacional y cumplimiento legal** en entornos multi-tenant y multi-jurisdicción.
```
