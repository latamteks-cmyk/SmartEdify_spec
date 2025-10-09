# 📋 Backlog del Producto: Fase 1 - Core Backbone

Este documento desglosa los Epics e Historias de Usuario iniciales para la implementación de los servicios del Core, basados en las especificaciones técnicas aprobadas.

---

## Epic 1: 🔑 Identity Service (Autenticación y Seguridad Central)

**Objetivo:** Establecer una autoridad de identidad robusta, segura y conforme a los estándares modernos, que sirva como la única fuente de verdad para la autenticación en la plataforma.

| ID | Historia de Usuario | Prioridad | Sprint Target |
|----|---------------------|-----------|----------------|
| ID-01 | Como **usuario final**, quiero registrarme y autenticarme usando **Passkeys (WebAuthn)** para tener un acceso seguro y sin contraseña (AAL3). | Crítica | Sprint 2 |
| ID-02 | Como **desarrollador de un servicio cliente**, necesito que el Identity Service emita **tokens de acceso JWT con DPoP** para prevenir el robo y la reutilización de tokens. | Crítica | Sprint 2 |
| ID-03 | Como **administrador de un tenant B2B**, necesito un **endpoint de descubrimiento OIDC por tenant** (`/.well-known/openid-configuration`) para federar mis propios usuarios de forma segura. | Alta | Sprint 2 |
| ID-04 | Como **auditor de cumplimiento**, necesito que **todas las operaciones de autenticación y cambio de estado de sesión** se registren en un log inmutable (WORM) para garantizar la no repudiación. | Crítica | Sprint 3 |
| ID-05 | Como **residente**, quiero usar un **QR seguro y de corta duración (COSE/JWS)** generado por el sistema para registrar mi asistencia en una asamblea legal. | Alta | Sprint 3 |
| ID-06 | Como **desarrollador**, necesito que la rotación de claves **JWKS (cada 90 días)** sea automática y soporte un período de rollover de 7 días para evitar fallos de validación de tokens. | Crítica | Sprint 2 |
| ID-07 | Como **usuario**, mi sesión debe ser revocada globalmente en **menos de 30 segundos** si un administrador o yo mismo iniciamos un logout de seguridad. | Alta | Sprint 3 |
| ID-08 | Como **desarrollador**, necesito que el Identity Service **valide y registre el `kid` de cada token emitido contra el JWKS activo** para evitar inconsistencias en la validación de firmas. | Crítica | Sprint 2 |
| ID-09 | Como **sistema**, debo **rechazar tokens sin DPoP o con nonce reutilizado**, registrando el intento en WORM y generando una métrica de seguridad. | Crítica | Sprint 2 |
| ID-10 | Como **auditor**, necesito que **cada operación de autenticación incluya en el log WORM metadatos de dispositivo** (attestation, OS, modelo) para trazabilidad forense. | Alta | Sprint 3 |
| ID-11 | Como **desarrollador en CI**, necesito un **modo mock de KMS/HSM** para ejecutar pruebas de integración sin depender de infraestructura externa. | Media | Sprint 2 |
| ID-12 | Como **sistema**, debo **publicar eventos estandarizados en Kafka** (`AuthSuccess.v1`, `SessionRevoked.v1`) con esquema registrado en Schema Registry. | Crítica | Sprint 3 |

---

## Epic 2: 🏢 Tenancy Service (Estructura Organizacional)

**Objetivo:** Crear el servicio que modela la jerarquía física y legal de la plataforma, proporcionando el contexto organizacional para todos los demás servicios.

| ID | Historia de Usuario | Prioridad | Sprint Target |
|----|---------------------|-----------|----------------|
| TS-01 | Como **Administrador de Plataforma**, quiero poder crear y configurar **Tenants**, asignándoles una jurisdicción raíz y una región de residencia de datos. | Crítica | Sprint 4 |
| TS-02 | Como **Administrador de Tenant**, quiero poder definir la jerarquía de mi organización, incluyendo **Condominios, Edificios y Unidades** (privadas y comunes). | Crítica | Sprint 4 |
| TS-03 | Como **desarrollador**, necesito que el servicio garantice el **aislamiento estricto de datos entre tenants** a nivel de base de datos mediante políticas RLS automáticas. | Crítica | Sprint 4 |
| TS-04 | Como **servicio consumidor (ej. Governance)**, necesito suscribirme a **eventos Kafka** (`CondominiumCreated`, `UnitReassigned`) para reaccionar a cambios en la estructura del tenant. | Alta | Sprint 4 |
| TS-05 | Como **arquitecto**, necesito que el servicio gestione el ciclo de vida de las **claves de cifrado por tenant** a través de la integración con KMS/HSM. | Alta | Sprint 4 |
| TS-06 | Como **servicio consumidor**, necesito que el Tenancy Service **exponga un endpoint para validar la pertenencia de un usuario a un condominio/unidad en tiempo real**, con respuesta en <100ms. | Crítica | Sprint 4 |
| TS-07 | Como **arquitecto**, necesito que **cada tenant tenga su propio namespace criptográfico** (KMS key, tenant_id en contexto) y que este se propague automáticamente a todos los servicios del stack. | Alta | Sprint 4 |
| TS-08 | Como **sistema**, debo **garantizar que el `tenant_id` y `condominium_id` se inyecten en el contexto de OpenTelemetry** de cada solicitud entrante. | Media | Sprint 4 |

---

## Epic 3: 👤 User Profiles Service (Identidad Funcional y Roles)

**Objetivo:** Gestionar los perfiles de usuario, sus relaciones con la estructura del tenant y los permisos funcionales, actuando como el puente entre la identidad y la gobernanza.

| ID | Historia de Usuario | Prioridad | Sprint Target |
|----|---------------------|-----------|----------------|
| UP-01 | Como **Administrador de Condominio**, quiero poder **crear perfiles de usuario** y asignarlos a unidades con una relación específica (ej. `OWNER`, `TENANT`). | Crítica | Sprint 3 |
| UP-02 | Como **Oficial de Cumplimiento**, quiero poder gestionar un **catálogo de roles y cargos oficiales** (ej. `PRESIDENTE`, `SECRETARIO`) basado en plantillas por jurisdicción. | Alta | Sprint 3 |
| UP-03 | Como **propietario (Owner)**, quiero poder **delegar permisos temporales** (ej. derecho a voto) a mi arrendatario (Tenant) para una asamblea específica. | Alta | Sprint 5 |
| UP-04 | Como **servicio backend**, necesito un endpoint `/evaluate` que determine si un usuario tiene un permiso específico (ej. `governance:vote`) en un contexto determinado. | Crítica | Sprint 3 |
| UP-05 | Como **usuario**, quiero que mi **consentimiento para el tratamiento de datos** sea registrado de forma inmutable y versionado según la política que acepté. | Crítica | Sprint 3 |
| UP-06 | Como **desarrollador**, necesito que el servicio emita eventos Kafka (`UserProfileUpdated`, `RoleAssigned`) para mantener la sincronización de datos en el ecosistema. | Alta | Sprint 3 |
| UP-07 | Como **servicio de gobernanza**, necesito que el UPS **exponga un endpoint para validar si un usuario tiene un cargo oficial vigente** (ej. `SECRETARIO`) en un condominio específico al momento de firmar un acta. | Crítica | Sprint 3 |
| UP-08 | Como **usuario**, debo poder **revocar mi consentimiento previo** y que esto se registre con timestamp, versión de política y efecto inmediato en el procesamiento de mis datos. | Alta | Sprint 3 |
| UP-09 | Como **sistema**, debo **emitir un evento `ConsentRevoked.v1`** cuando un usuario retira su consentimiento, para que otros servicios (Compliance, Analytics) actúen en consecuencia. | Media | Sprint 3 |
| UP-10 | Como **desarrollador**, necesito que el UPS **no almacene PII en texto claro**, sino que use cifrado con clave por tenant o referencias a KMS. | Crítica | Sprint 3 |

---

## Epic 4: 🛠️ Transversal / Plataforma (NUEVO)

> *Este epic agrupa capacidades técnicas críticas que no pertenecen a un solo servicio, pero son obligatorias para el Sprint 1.*

| ID | Historia de Usuario | Prioridad | Sprint Target |
|----|---------------------|-----------|----------------|
| PLT-01 | Como **equipo de QA**, necesito un **plan de pruebas de caos** que valide el modo **fail-closed** del Compliance Service y la resiliencia de Identity ante fallos de JWKS/Redis. | Crítica | Sprint 2 |
| PLT-02 | Como **pipeline de CI**, debo **fallar si `kid_mismatch_detected_total > 0` o si los esquemas de eventos no están en Schema Registry**. | Crítica | Sprint 2 |
| PLT-03 | Como **desarrollador**, necesito que **todos los servicios propaguen `tenant_id`, `condominium_id` y `user_role` en el contexto de OpenTelemetry** para observabilidad por tenant. | Alta | Sprint 2 |
| PLT-04 | Como **arquitecto**, necesito que **todos los endpoints críticos expongan métricas RED (Rate, Errors, Duration)** y se integren con el dashboard central de Grafana. | Media | Sprint 2 |

---

## ✅ Notas de Gestión

- **Sprint 2** se convierte en el **sprint de hardening técnico**, con foco en seguridad, observabilidad y resiliencia.
- Las historias **ID-08, ID-09, ID-12, PLT-01 y PLT-02** son **bloqueantes para RC** según la Revisión del CTO (acciones H-02, H-04, H-06, H-07).
- El **Epic 4 (Transversal)** debe ser gestionado por el equipo de Plataforma/DevEx, con dependencias claras en los demás equipos.

