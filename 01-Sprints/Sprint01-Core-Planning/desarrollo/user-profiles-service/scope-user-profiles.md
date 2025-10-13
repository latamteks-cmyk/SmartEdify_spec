# 🎯 Alcance del Servicio: User Profiles Service (3002)

## 1. Propósito y Rol en el Ecosistema

El **User Profiles Service** es la **fuente canónica de la identidad funcional y relacional** dentro de SmartEdify. Su misión es complementar al `identity-service` (que maneja la autenticación) gestionando los atributos de un usuario, sus relaciones con la jerarquía organizacional y los permisos que posee.

Este servicio actúa como el puente entre la identidad digital de un usuario y su rol y capacidades dentro de la comunidad, sirviendo como una dependencia crítica para los servicios de gobernanza, cumplimiento y operaciones.

---

## 2. Funcionalidades Dentro del Alcance (In Scope)

- **Gestión de Perfiles de Usuario:**
  - Operaciones CRUD para perfiles de usuario, incluyendo atributos no sensibles como nombre completo, preferencias de idioma y notificaciones.

- **Gestión de Membresías y Relaciones:**
  - Vincular perfiles de usuario a unidades (`units`) dentro de un condominio, estableciendo una relación semántica clara (ej. `OWNER`, `TENANT`, `STAFF`).
  - Gestionar el ciclo de vida de estas membresías (activación, terminación, transferencia).

- **Gestión de Roles y Cargos Oficiales:**
  - Asignación de roles funcionales y cargos oficiales (ej. `PRESIDENT`, `ADMIN`) a los perfiles dentro del contexto de un condominio.
  - Gestión de catálogos de roles basados en plantillas por jurisdicción, cuya fuente de verdad es el `compliance-service`.

- **Gestión de Permisos (Entitlements) y Delegaciones:**
  - Asignación de permisos granulares por módulo (`entitlements`).
  - Creación y gestión de **delegaciones temporales** de permisos entre usuarios, con TTL y scope definidos.

- **Evaluación de Permisos:**
  - Exposición de un endpoint `/evaluate` que consolida el contexto de un usuario (roles, membresías, delegaciones) y delega la decisión final de autorización a un PDP (`compliance-service`).

- **Gestión de Consentimientos:**
  - Registro y auditoría inmutable (WORM) de los consentimientos otorgados por los usuarios para diferentes propósitos (ej. marketing, tratamiento de datos).

- **Publicación de Eventos:**
  - Emisión de eventos a Kafka para notificar a otros servicios sobre cambios de estado (`UserProfileUpdated`, `RoleAssigned`, `MembershipTerminated`).

---

## 3. Funcionalidades Fuera de Alcance (Out of Scope)

- ❌ **No realiza autenticación:** No maneja contraseñas, credenciales WebAuthn, ni emite tokens de acceso. Esta es responsabilidad exclusiva del **`identity-service`**.
- ❌ **No define la jerarquía física:** No crea tenants, condominios o unidades. Consume estos datos del **`tenancy-service`**.
- ❌ **No evalúa políticas de cumplimiento:** No contiene la lógica para decidir si una acción es legalmente permitida. Delega esta decisión al **`compliance-service`**.
- ❌ **No almacena PII sensible:** Datos críticos como números de identificación nacional (DNI) no se almacenan aquí. Su manejo es delegado a otros servicios con medidas de seguridad superiores como el cifrado determinístico.

---

## 4. Dependencias Críticas

- **`identity-service` (Asíncrona/Event-driven):** Recibe notificaciones cuando se crea una nueva identidad para poder crear el perfil funcional correspondiente.
- **`tenancy-service` (Síncrona):** Lo consulta para validar la existencia y el tipo de las unidades a las que se asignan las membresías.
- **`compliance-service` (Síncrona y Asíncrona):** Lo consulta para la evaluación de permisos (PDP) y recibe de él las plantillas de roles por jurisdicción.
- **`Kafka` (Asíncrona):** Utilizado para publicar cambios de estado y para la orquestación de flujos complejos como DSAR.


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
Este documento ha sido actualizado para reflejar completamente la arquitectura de base de datos v2.2 y está listo para implementación en producción.
