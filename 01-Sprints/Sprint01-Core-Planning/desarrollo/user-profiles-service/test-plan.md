# 🧪 Plan de Pruebas: User Profiles Service (3002)

## 1. Objetivos de las Pruebas

Este plan de pruebas tiene como objetivo validar la correcta implementación del `user-profiles-service` como la fuente canónica de identidad funcional. Las pruebas se enfocarán en la integridad de las relaciones jerárquicas, la correcta gestión de roles y permisos, el aislamiento de datos multi-tenant y la resiliencia del servicio frente a fallos en sus dependencias.

---

## 2. Tipos de Pruebas

### 2.1. Pruebas Unitarias

- **Objetivo:** Validar la lógica de negocio interna y las restricciones del modelo de datos.
- **Cobertura Mínima:** 85%.
- **Escenarios Clave:**
  - Lógica de validación de la coherencia entre el tipo de membresía y el tipo de unidad (ej. `OWNER` solo en unidades `PRIVATE`).
  - Lógica de negocio para la terminación y transferencia de membresías.
  - Validación de la estructura y el scope en la creación de delegaciones temporales.
  - Correcta generación de eventos Kafka ante cambios en perfiles, roles o membresías.

### 2.2. Pruebas de Integración

- **Objetivo:** Validar la correcta comunicación y colaboración con otros servicios y con la base de datos.
- **Escenarios Clave:**
  - **Aislamiento de Datos (RLS):**
    - Crear perfiles y membresías para dos tenants distintos (A y B).
    - Autenticado como un administrador del Tenant A, intentar leer, modificar o eliminar datos del Tenant B.
    - **Verificar** que todas las operaciones fallen con un error `403 Forbidden` o `404 Not Found`, y que en ningún caso se filtre información.
  - **Integración con Tenancy Service:**
    - Intentar crear una membresía para una `unit_id` que no existe en el `tenancy-service`.
    - **Verificar** que la operación falle con un error de clave foránea o de validación.
  - **Integración con Compliance Service (PDP):**
    - Llamar al endpoint `POST /evaluate`.
    - **Verificar** que la solicitud se delega correctamente al `compliance-service` y que la respuesta (permitir/denegar) se refleja.
    - Modificar un rol de usuario y verificar que el caché de políticas se invalida (Push-invalidation).
  - **Flujo DSAR:**
    - Iniciar un proceso de borrado de datos (`POST /privacy/data`).
    - **Verificar** que se emite el evento `DataDeletionRequested` y que el servicio espera las confirmaciones de `identity-service` y `documents-service` antes de finalizar el proceso.

### 2.3. Pruebas de Seguridad

- **Objetivo:** Identificar vulnerabilidades relacionadas con la manipulación de roles, permisos y membresías.
- **Escenarios Clave:**
  - **Escalada de Privilegios:**
    - Intentar auto-asignarse un rol de `ADMIN` o un cargo oficial sin los permisos adecuados.
    - Intentar crear una delegación de permisos que el delegante no posee.
    - Intentar extender el TTL de una delegación más allá del máximo permitido (90 días).
  - **Acceso a Datos No Autorizado:**
    - Como usuario estándar, intentar acceder a los endpoints de administración (ej. `POST /bulk/execute`).
    - Como `TENANT`, intentar modificar la configuración de la membresía que solo el `OWNER` puede gestionar.

### 2.4. Pruebas de Rendimiento y Carga

- **Objetivo:** Asegurar que el servicio cumple con sus SLOs bajo cargas de trabajo realistas.
- **Escenarios Clave:**
  - **SLO de Lectura de Perfil:** Cargar el endpoint `GET /me` (que consolida múltiples datos). **Objetivo: P95 ≤ 120 ms**.
  - **SLO de Evaluación de Permisos:** Realizar pruebas de carga sobre `POST /evaluate` para medir la latencia con y sin caché. **Objetivo: P95 ≤ 150 ms**.
  - **Prueba de Carga de Bulk:** Ejecutar un job de `POST /bulk/execute` con 10,000 registros y verificar que el sistema maneja la carga sin exceder los umbrales de `processing_time_p95` y que el backpressure funciona.

### 2.5. Pruebas de Resiliencia (Chaos Engineering)

- **Objetivo:** Validar la capacidad del servicio para manejar fallos en sus dependencias.
- **Escenarios Clave:**
  - **Fallo del Compliance Service:** Simular una caída del PDP y **verificar** que el endpoint `/evaluate` utiliza el caché de políticas y, una vez expirado, aplica una política de `fail-closed` (denegando el acceso).
  - **Fallo de Kafka:** Simular la caída del bus de eventos y **verificar** que los eventos salientes se encolan (patrón Outbox) y se envían una vez que Kafka se recupera.
  - **Fallo de la Base de Datos:** Simular la caída de la base de datos y **verificar** que el servicio deja de aceptar peticiones de escritura y responde con errores `503 Service Unavailable` de forma controlada.

---

## 3. Herramientas y Entorno

- **Pruebas Unitarias/Integración:** JUnit 5, Mockito, Testcontainers.
- **Pruebas de API y Carga:** k6, Postman/Newman.
- **Chaos Engineering:** Gremlin, Istio Fault Injection.
- **Entorno:** Pipeline de CI/CD en GitLab que despliega en un entorno de `staging` para la ejecución de pruebas automatizadas.


---

## ✅ Actualizaciones según Arquitectura de Base de Datos v2.2 (2025-10-13)

### 🔐 Validación Extendida de RLS
- Confirmación de que todas las tablas (`profiles`, `memberships`, `roles`, `role_assignments`, `profile_entitlements`, `communication_consents`) tienen RLS activo por `tenant_id`.
- Se recomienda agregar validación cruzada por `condominium_id` en vistas y funciones.

### 🧩 Campos explícitos añadidos
- `tenant_id` y `condominium_id` están presentes en todas las entidades relacionales.
- Esto permite trazabilidad directa, simplifica políticas RLS y mejora el rendimiento de consultas.

### 📣 Eventos Kafka extendidos
- Se añaden eventos:
  - `DelegationMisuseDetected`
  - `ConsentPolicyVersionMismatch`
  - `MembershipConflictResolved`

### 📄 Alineación con DBML y OpenAPI
- El modelo DBML actualizado refleja todas las relaciones y claves necesarias.
- El contrato OpenAPI incluye ahora `updatedAt` en `Profile` y metadatos extendidos en `Consent`.

### 🧠 Recomendaciones técnicas adicionales
- Validar que `responsible_profile_id` pertenezca al mismo `condominium_id`.
- Confirmar que `unit_id` con `kind='COMMON'` no admita membresías de tipo `OWNER`, `TENANT`, `CONVIVIENTE`.
- Asegurar que los triggers de validación estén activos y auditados.

---

## ✅ Estado Final
Este plan de pruebas ha sido actualizado para reflejar completamente la arquitectura de base de datos v2.2 y está listo para ejecución en entorno de staging.
