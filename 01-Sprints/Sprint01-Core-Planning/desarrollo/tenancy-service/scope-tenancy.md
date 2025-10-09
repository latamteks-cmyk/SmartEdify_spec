# 🎯 Alcance del Servicio: Tenancy Service (3003)

## 1. Propósito y Rol en el Ecosistema

El **Tenancy Service** es la **“raíz de confianza organizacional”** de la plataforma SmartEdify. Su responsabilidad exclusiva es definir, gestionar y servir la jerarquía organizacional y jurídica del ecosistema:

**Tenant → Condominium → Building → Unit → Space**

Este servicio actúa como la fuente canónica de la verdad para la estructura física y legal, proveyendo el contexto indispensable sobre el cual operan todos los demás microservicios, desde la identidad hasta la gobernanza y las finanzas.

---

## 2. Funcionalidades Dentro del Alcance (In Scope)

- **Gestión de la Jerarquía Organizacional:**
  - Operaciones CRUD completas para las entidades `Tenants`, `Condominiums`, `Buildings`, `Units` y `Spaces`.
  - Mantenimiento de las relaciones y la cardinalidad entre estas entidades.

- **Mapeo Jurisdiccional y de Residencia:**
  - Asociación de cada `Condominium` a una jurisdicción legal específica (ej. `PE`, `BR`, `CL`).
  - Asignación de una región de residencia de datos (`data_residency`) a nivel de `Tenant`.

- **Aislamiento de Datos:**
  - Propietario de la implementación de políticas **Row-Level Security (RLS)** en la base de datos, asegurando que cada consulta esté aislada por `tenant_id`.

- **Orquestación de Cifrado:**
  - Gestión del ciclo de vida de las claves de cifrado por tenant, delegando las operaciones criptográficas en sí a un **KMS/HSM**.

- **Publicación de Eventos de Topología:**
  - Emisión de eventos a través de Kafka (`tenancy.events`) para notificar a otros servicios sobre cambios en la estructura organizacional (ej. `CondominiumCreated`, `UnitReassigned`, `JurisdictionChanged`).

---

## 3. Funcionalidades Fuera de Alcance (Out of Scope)

Para mantener un bajo acoplamiento y una alta cohesión, el Tenancy Service **NO** realiza las siguientes funciones:

- ❌ **No gestiona usuarios ni perfiles:** La información de usuarios, roles o permisos es responsabilidad del **`user-profiles-service`**.
- ❌ **No gestiona autenticación ni sesiones:** La identidad digital y el ciclo de vida de los tokens son gestionados exclusivamente por el **`identity-service`**.
- ❌ **No contiene lógica de negocio de dominios específicos:** No sabe qué es una "reserva", una "votación" o una "transacción financiera". Solo provee el contexto (`Unit`, `Space`) para que otros servicios actúen.
- ❌ **No define políticas de cumplimiento:** Las reglas de negocio y normativas son definidas y evaluadas por el **`compliance-service`**.

---

## 4. Dependencias Críticas

- **Consumidores Principales:**
  - **`identity-service`:** Consulta el `tenancy-service` para validar la pertenencia de un usuario a un tenant/condominio durante la autenticación.
  - **`user-profiles-service`:** Se sincroniza con este servicio para vincular perfiles de usuario a unidades (`units`).
  - **`governance-service`, `finance-service`, `asset-management-service`:** Consumen datos de la jerarquía para contextualizar sus operaciones.

- **Servicios de Plataforma:**
  - **`Kafka`:** Utilizado para la publicación asíncrona de eventos de cambio de topología.
  - **`PostgreSQL`:** Utilizado como base de datos principal, con RLS habilitado.
  - **`Redis`:** Para el cacheo de contexto de tenant y la invalidación distribuida.
  - **`KMS/HSM`:** Para la gestión de claves de cifrado por tenant.
