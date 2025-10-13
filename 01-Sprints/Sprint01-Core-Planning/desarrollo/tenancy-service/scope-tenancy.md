## 🎯 Alcance del Servicio: Tenancy Service (3003) — Versión Consolidada

### 1. Propósito y Rol en el Ecosistema

El **Tenancy Service** es la “raíz de confianza organizacional” de SmartEdify. Su responsabilidad exclusiva es definir, gestionar y servir la jerarquía organizacional y jurídica del ecosistema:

**Tenant → Condominium → Building → Unit → Subunit (Space)**

Este servicio actúa como fuente canónica de la verdad para la estructura física y legal, proveyendo el contexto indispensable sobre el cual operan todos los demás microservicios, desde la identidad hasta la gobernanza, cumplimiento y finanzas.

---

### 2. Funcionalidades Dentro del Alcance (In Scope)

#### 🏢 Gestión Jerárquica
- Operaciones CRUD completas para `tenants`, `condominiums`, `buildings`, `units`, `subunits`.
- Validación de cardinalidad, integridad referencial y relaciones entre entidades.
- Soporte para unidades privadas y subunidades comunes (`is_common_area`).

#### ⚖️ Mapeo Legal y Residencial
- Asociación de `condominiums` a jurisdicciones legales (`PE`, `BR`, `CL`, etc.).
- Asignación de `data_residency` por `tenant`, con trazabilidad legal y compatibilidad con el `Compliance Service`.

#### 🔐 Aislamiento de Datos
- Implementación de **Row-Level Security (RLS)** por `tenant_id` y `condominium_id`.
- Validación de vistas, funciones y materialized views para respetar el contexto RLS.

#### 🔑 Orquestación Criptográfica
- Gestión del ciclo de vida de claves por tenant.
- Delegación de operaciones criptográficas a KMS/HSM con rotación programada y respaldo legal.

#### 📣 Publicación de Eventos
- Emisión de eventos Kafka (`tenancy.events`) como:
  - `TenantCreated`
  - `CondominiumUpdated`
  - `UnitReassigned`
  - `JurisdictionChanged`
- Triggers en base de datos para sincronización con otros servicios.

#### 📊 Compatibilidad con Dashboards
- Soporte para vistas materializadas como `tenancy_overview` y `compliance_dashboard`.
- Estructura optimizada para consultas híbridas (bajo demanda + eventos).

---

### 3. Funcionalidades Fuera del Alcance (Out of Scope)

Para mantener bajo acoplamiento y alta cohesión, el Tenancy Service **NO** realiza:

- ❌ Gestión de usuarios, perfiles o roles (delegado al `User Profiles Service`).
- ❌ Autenticación, sesiones o tokens (delegado al `Identity Service`).
- ❌ Lógica de negocio de otros dominios (reservas, votaciones, pagos).
- ❌ Evaluación de políticas legales o normativas (delegado al `Compliance Service`).

---

### 4. Dependencias Críticas

#### 🔄 Consumidores Principales
- `Identity Service`: valida pertenencia a tenant/condominio durante login.
- `User Profiles Service`: vincula perfiles a unidades (`unit_id`) y cargos oficiales.
- `Governance`, `Finance`, `Asset Management`: consumen jerarquía para contextualizar operaciones.

#### 🧱 Servicios de Plataforma
- `PostgreSQL`: base de datos principal con RLS habilitado.
- `Kafka`: publicación de eventos de topología.
- `Redis`: cache de contexto de tenant y invalidación distribuida.
- `KMS/HSM`: gestión de claves por tenant con respaldo criptográfico.

---

### 5. Observaciones Técnicas y Recomendaciones

| Área | Observación | Recomendación |
|------|-------------|---------------|
| **RLS** | Correctamente aplicado por `tenant_id` y `condominium_id`. | Validar que todas las vistas, funciones y materialized views respeten el contexto RLS. |
| **Eventos Kafka** | Flujo de eventos está modelado. | Asegurar triggers para publicar `UnitCreated`, `JurisdictionChanged`, `TenantUpdated`. |
| **Jerarquía** | Tablas reflejan la estructura física y legal. | Añadir validaciones de integridad entre `units` y `subunits`, y entre `buildings` y `condominiums`. |
| **Jurisdicción** | Campo `jurisdiction` presente en `condominiums`. | Validar consistencia con `data_residency`, `timezone` y `compliance_requirements`. |
| **Materialización** | Compatible con vistas para dashboards. | Implementar `tenancy_overview` como vista materializada con refresh programado. |
| **Criptografía** | Delegación a KMS/HSM está definida. | Asegurar que las claves estén asociadas a `tenant_id` y que se respete la rotación de 90 días. |
| **Cache Redis** | Utilizado para contexto de tenant. | Validar TTL e invalidación por eventos topológicos (`CondominiumUpdated`, `UnitReassigned`). |

---



---

### 🆕 Actualizaciones según Arquitectura de Base de Datos v2.2 (2025-10-13)

#### ✅ Campos explícitos añadidos
- Todas las entidades descendientes (`buildings`, `units`, `subunits`) ahora incluyen explícitamente `tenant_id` y `condominium_id`.
- Esto mejora la trazabilidad directa, simplifica las políticas RLS y optimiza las consultas.

#### ✅ Nuevos eventos Kafka definidos
- `UnitCreated`
- `TenantUpdated`
- `JurisdictionChanged`
- `SubunitAssigned`

#### ✅ Alineación con DBML y OpenAPI
- El modelo DBML actualizado refleja todas las relaciones y claves necesarias.
- El contrato OpenAPI incluye ahora `updatedAt` en `Tenant` y metadatos extendidos en `DataResidency` (`complianceFrameworks`, `retentionPolicy`, `replicationRegions`).

#### ✅ Recomendaciones técnicas adicionales
- Validar que `subunits` tengan integridad referencial con `units` y `condominiums`.
- Asegurar que `data_residency` esté sincronizado con `jurisdiction`, `timezone` y `compliance_requirements`.
- Confirmar que los triggers de eventos estén activos y auditados.

---

### ✅ Estado Final
Este documento ha sido actualizado para reflejar completamente la arquitectura de base de datos v2.2 y está listo para implementación en producción.
