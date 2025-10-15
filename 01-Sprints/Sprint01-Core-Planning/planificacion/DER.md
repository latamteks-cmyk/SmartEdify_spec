# **Diagrama Entidad-Relación (DER) — SmartEdify Fase 1**

## **1. Introducción**

Este DER describe la estructura lógica y relacional de la base de datos para la Fase 1 de SmartEdify. Su propósito es asegurar **integridad de datos**, **aislamiento multi-tenant** y **cumplimiento normativo** desde la raíz del modelo.

---
### Diagrama entidad-relación

```mermaid
erDiagram
  users {
    uuid id PK
    citext email UNIQUE
    text phone
    text global_status FK
    timestamptz email_verified_at
    timestamptz created_at
  }
  tenants {
    uuid id PK
    text name
    text legal_name
    text tenant_type
    text jurisdiction_root
    text status FK
    text data_residency
    text dpo_contact
    boolean international_transfers
    timestamptz created_at
    timestamptz updated_at
  }
  user_tenant_assignments {
    uuid id PK
    uuid user_id FK
    uuid tenant_id FK
    text status FK
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
  profiles {
    uuid id PK
    uuid user_id FK
    uuid tenant_id FK
    citext email
    text phone
    text full_name
    text status FK
    text country_code FK
    bytea personal_data_ct
    bytea personal_data_aad
    text personal_data_kid
    boolean habeas_data_acceptance
    timestamptz habeas_data_accepted_at
    timestamptz created_at
    timestamptz updated_at
    timestamptz deleted_at
  }
  communication_consents {
    uuid id PK
    uuid profile_id FK
    text channel
    boolean consented
    timestamptz consented_at
    timestamptz revoked_at
  }
  condominiums {
    uuid id PK
    uuid tenant_id FK
    text name
    jsonb address
    text jurisdiction
    text timezone
    text currency
    text status FK
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
    text status FK
    timestamptz created_at
  }
  units {
    uuid id PK
    uuid building_id FK
    text unit_number
    text unit_type
    numeric area
    integer bedrooms
    text status FK
    timestamptz created_at
  }
  subunits {
    uuid id PK
    uuid unit_id FK
    text subunit_number
    text subunit_type
    numeric area
    text status FK
  }
  roles {
    uuid id PK
    uuid tenant_id FK
    text name
    jsonb permissions
    timestamptz created_at
  }
  memberships {
    uuid id PK
    uuid tenant_id FK
    uuid profile_id FK
    uuid condominium_id FK
    uuid unit_id FK
    jsonb privileges
    uuid responsible_profile_id FK
    timestamptz since
    timestamptz until
    text status FK
  }
  role_assignments {
    uuid id PK
    uuid profile_id FK
    uuid role_id FK
    timestamptz assigned_at
    timestamptz revoked_at
    text status FK
  }
  delegations {
    uuid id PK
    uuid delegator_profile_id FK
    uuid delegate_profile_id FK
    uuid role_id FK
    timestamptz start_date
    timestamptz end_date
    text status FK
  }
  data_subject_requests {
    uuid id PK
    uuid tenant_id FK
    uuid profile_id FK
    text request_type FK
    text status FK
    jsonb payload
    timestamptz created_at
    timestamptz resolved_at
  }
  data_bank_registrations {
    uuid id PK
    uuid tenant_id FK
    text status FK
    jsonb metadata
    timestamptz created_at
  }
  data_processing_agreements {
    uuid id PK
    uuid tenant_id FK
    text counterparty
    text status FK
    timestamptz created_at
  }
  impact_assessments {
    uuid id PK
    uuid tenant_id FK
    text status FK
    jsonb findings
    timestamptz created_at
  }
  compliance_tasks {
    uuid id PK
    uuid tenant_id FK
    text status FK
    text title
    jsonb details
    timestamptz created_at
  }
  ccpa_opt_outs {
    uuid id PK
    uuid tenant_id FK
    uuid profile_id FK
    timestamptz created_at
  }
  audit_log {
    uuid tenant_id FK
    bigint seq PK
    uuid id
    uuid actor_user_id
    uuid actor_session_id
    text table_name
    text action
    jsonb row_pk
    jsonb diff
    jsonb payload
    timestamptz created_at
    bytea hash_prev
    bytea hash_curr
    bytea signature
  }

  users ||--o{ user_tenant_assignments : ""
  tenants ||--o{ user_tenant_assignments : ""
  users ||--o{ profiles : ""
  tenants ||--o{ profiles : ""
  profiles ||--o{ communication_consents : ""
  tenants ||--o{ condominiums : ""
  condominiums ||--o{ buildings : ""
  buildings ||--o{ units : ""
  units ||--o{ subunits : ""
  tenants ||--o{ roles : ""
  profiles ||--o{ memberships : ""
  condominiums ||--o{ memberships : ""
  units ||--o{ memberships : ""
  roles ||--o{ role_assignments : ""
  profiles ||--o{ role_assignments : ""
  profiles ||--o{ delegations : ""
  profiles ||--o{ delegations : ""
  roles ||--o{ delegations : ""
  tenants ||--o{ data_subject_requests : ""
  profiles ||--o{ data_subject_requests : ""
  tenants ||--o{ data_bank_registrations : ""
  tenants ||--o{ data_processing_agreements : ""
  tenants ||--o{ impact_assessments : ""
  tenants ||--o{ compliance_tasks : ""
  tenants ||--o{ ccpa_opt_outs : ""
  profiles ||--o{ ccpa_opt_outs : ""
  tenants ||--o{ audit_log : ""
```

---

## **2. Entidades Principales y Relaciones**

### **A. Identidad y Tenancy**

* **users**

  * *PK*: id (UUID)
  * email (único)
  * global_status → status_t
  * 1 usuario → N asignaciones a tenants (`user_tenant_assignments`)

* **tenants**

  * *PK*: id (UUID)
  * status → status_t
  * 1 tenant → N condominiums
  * 1 tenant → N users (a través de user_tenant_assignments)

* **user_tenant_assignments**

  * *PK*: id (UUID)
  * user_id → users
  * tenant_id → tenants
  * status → status_t
  * Relación N:M (usuarios pueden pertenecer a varios tenants y viceversa)

* **sessions**

  * *PK*: id (UUID)
  * user_id → users
  * tenant_id → tenants
  * Relación 1:N (usuario puede tener muchas sesiones por tenant)
  * 1 session → N refresh_tokens

* **refresh_tokens**

  * *PK*: id (UUID)
  * session_id → sessions

---

### **B. Perfiles y Consentimientos**

* **profiles**

  * *PK*: id (UUID)
  * user_id → users
  * tenant_id → tenants
  * status → status_t
  * country_code → country_code_t
  * Relación 1:1 (cada user_id por tenant_id es único; enforced en lógica de negocio)
  * 1 profile → N communication_consents
  * 1 profile → N memberships

* **communication_consents**

  * *PK*: id (UUID)
  * profile_id → profiles

---

### **C. Estructura Organizacional**

* **condominiums**

  * *PK*: id (UUID)
  * tenant_id → tenants
  * status → status_t
  * 1 condominium → N buildings

* **buildings**

  * *PK*: id (UUID)
  * condominium_id → condominiums
  * status → status_t
  * 1 building → N units

* **units**

  * *PK*: id (UUID)
  * building_id → buildings
  * status → status_t
  * 1 unit → N subunits

* **subunits**

  * *PK*: id (UUID)
  * unit_id → units
  * status → status_t

---

### **D. Roles, Membresías y Delegaciones**

* **roles**

  * *PK*: id (UUID)
  * tenant_id → tenants
  * 1 role → N role_assignments

* **memberships**

  * *PK*: id (UUID)
  * tenant_id → tenants
  * profile_id → profiles
  * condominium_id → condominiums
  * unit_id → units (opcional)
  * responsible_profile_id → profiles (opcional)
  * status → status_t

* **role_assignments**

  * *PK*: id (UUID)
  * profile_id → profiles
  * role_id → roles
  * status → status_t

* **delegations**

  * *PK*: id (UUID)
  * delegator_profile_id → profiles
  * delegate_profile_id → profiles
  * role_id → roles
  * status → status_t

---

### **E. Compliance**

* **data_subject_requests**

  * *PK*: id (UUID)
  * tenant_id → tenants
  * profile_id → profiles
  * request_type → request_type_t
  * status → status_t

* **data_bank_registrations**

  * *PK*: id (UUID)
  * tenant_id → tenants
  * status → status_t

* **data_processing_agreements**

  * *PK*: id (UUID)
  * tenant_id → tenants
  * status → status_t

* **impact_assessments**

  * *PK*: id (UUID)
  * tenant_id → tenants
  * status → status_t

* **compliance_tasks**

  * *PK*: id (UUID)
  * tenant_id → tenants
  * status → status_t

* **ccpa_opt_outs**

  * *PK*: id (UUID)
  * tenant_id → tenants
  * profile_id → profiles

---

### **F. Auditoría**

* **audit_log**

  * *PK*: (tenant_id, seq)
  * tenant_id → tenants
  * Cubre toda acción relevante, particionado por fecha
  * Relación 1:N: un tenant tiene muchos registros de auditoría

---

## **3. Diagrama Visual (formato texto/mermaid)**

> Si requieres el DER en formato visual, este ejemplo es compatible con herramientas como [dbdiagram.io](https://dbdiagram.io) o cualquier editor Mermaid.

```mermaid
erDiagram

users ||--o{ user_tenant_assignments : "asigna"
tenants ||--o{ user_tenant_assignments : "asigna"
users ||--o{ profiles : "tiene"
tenants ||--o{ profiles : "tiene"
profiles ||--o{ communication_consents : "otorga"
tenants ||--o{ condominiums : "administra"
condominiums ||--o{ buildings : "tiene"
buildings ||--o{ units : "tiene"
units ||--o{ subunits : "tiene"
tenants ||--o{ roles : "define"
profiles ||--o{ memberships : "posee"
condominiums ||--o{ memberships : "asocia"
units ||--o{ memberships : "asocia"
roles ||--o{ role_assignments : "asigna"
profiles ||--o{ role_assignments : "recibe"
profiles ||--o{ delegations : "puede delegar"
profiles ||--o{ delegations : "puede ser delegado"
roles ||--o{ delegations : "para"
tenants ||--o{ data_subject_requests : "recibe"
profiles ||--o{ data_subject_requests : "origina"
tenants ||--o{ data_bank_registrations : "declara"
tenants ||--o{ data_processing_agreements : "firma"
tenants ||--o{ impact_assessments : "evalua"
tenants ||--o{ compliance_tasks : "genera"
tenants ||--o{ ccpa_opt_outs : "gestiona"
profiles ||--o{ ccpa_opt_outs : "inicia"
tenants ||--o{ audit_log : "registra"
```

---

## **4. Notas de Cumplimiento y Seguridad**

* **Multi-tenancy:** Todas las entidades clave están relacionadas por `tenant_id` y protegidas por RLS a nivel de base de datos.
* **PII y privacidad:** Datos sensibles en `profiles` sólo accedidos por lógica autorizada; el cifrado AEAD impide exposición accidental.
* **Integridad:** ON DELETE CASCADE/SET NULL en relaciones para evitar huérfanos y mantener coherencia ante bajas lógicas o físicas.
* **Auditoría:** Toda modificación relevante genera un registro en `audit_log` (cumplimiento WORM).
* **Dominio normalizado:** Tablas como `status_t`, `country_code_t`, `request_type_t` evitan valores mágicos.

---

## **5. Resumen de Relaciones Clave**

* Un **usuario** puede estar en **muchos tenants** y viceversa.
* Un **perfil** pertenece a 1 usuario y 1 tenant; puede tener muchas membresías y roles.
* Un **tenant** puede tener muchos condominios, buildings, unidades, y usuarios.
* **Membresías** y **roles** permiten modelar jerarquía y permisos dentro de un condominio/tenant.
* **Cumplimiento** y **auditoría** están siempre anclados al tenant y, cuando aplica, al perfil.

---


¿O deseas ver alguna sección en formato tabular para una especificación funcional más detallada?
Puedo generar la imagen o el archivo fuente compatible con Lucidchart, Draw.io, dbdiagram.io o Mermaid según tu preferencia. ¡Indícame cuál necesitas!
