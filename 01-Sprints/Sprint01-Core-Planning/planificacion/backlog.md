# 📋 Backlog del Producto: Fase 1 - Core Backbone

Este documento desglosa los Epics e Historias de Usuario iniciales para la implementación de los servicios del Core, basados en las especificaciones técnicas aprobadas.

---

## Epic 1: 🔑 Identity Service (Autenticación y Seguridad Central)

**Objetivo:** Establecer una autoridad de identidad robusta, segura y conforme a los estándares modernos, que sirva como la única fuente de verdad para la autenticación en la plataforma.

| ID | Historia de Usuario | Prioridad | Sprint Target |
|----|---------------------|-----------|---------------|
| **ID-01** | Como **usuario final**, quiero registrarme y autenticarme usando **Passkeys (WebAuthn)** para tener un acceso seguro y sin contraseña (AAL3). | Crítica | Sprint 2 |
| **ID-02** | Como **desarrollador de un servicio cliente**, necesito que el Identity Service emita **tokens de acceso JWT con DPoP** para prevenir el robo y la reutilización de tokens. | Crítica | Sprint 2 |
| **ID-03** | Como **administrador de un tenant B2B**, necesito un **endpoint de descubrimiento OIDC por tenant** (`/.well-known/openid-configuration`) para federar mis propios usuarios de forma segura. | Alta | Sprint 2 |
| **ID-04** | Como **auditor de cumplimiento**, necesito que **todas las operaciones de autenticación y cambio de estado de sesión** se registren en un log inmutable (WORM) para garantizar la no repudiación. | Crítica | Sprint 3 |
| **ID-05** | Como **residente**, quiero usar un **QR seguro y de corta duración (COSE/JWS)** generado por el sistema para registrar mi asistencia en una asamblea legal. | Alta | Sprint 3 |
| **ID-06** | Como **desarrollador**, necesito que la rotación de claves **JWKS (cada 90 días)** sea automática y soporte un período de rollover de 7 días para evitar fallos de validación de tokens. | Crítica | Sprint 2 |
| **ID-07** | Como **usuario**, mi sesión debe ser revocada globalmente en **menos de 30 segundos** si un administrador o yo mismo iniciamos un logout de seguridad. | Alta | Sprint 3 |

---

## Epic 2: 🏢 Tenancy Service (Estructura Organizacional)

**Objetivo:** Crear el servicio que modela la jerarquía física y legal de la plataforma, proporcionando el contexto organizacional para todos los demás servicios.

| ID | Historia de Usuario | Prioridad | Sprint Target |
|----|---------------------|-----------|---------------|
| **TS-01** | Como **Administrador de Plataforma**, quiero poder crear y configurar **Tenants**, asignándoles una jurisdicción raíz y una región de residencia de datos. | Crítica | Sprint 4 |
| **TS-02** | Como **Administrador de Tenant**, quiero poder definir la jerarquía de mi organización, incluyendo **Condominios, Edificios y Unidades** (privadas y comunes). | Crítica | Sprint 4 |
| **TS-03** | Como **desarrollador**, necesito que el servicio garantice el **aislamiento estricto de datos entre tenants** a nivel de base de datos mediante políticas RLS automáticas. | Crítica | Sprint 4 |
| **TS-04** | Como **servicio consumidor (ej. Governance)**, necesito suscribirme a **eventos Kafka** (`CondominiumCreated`, `UnitReassigned`) para reaccionar a cambios en la estructura del tenant. | Alta | Sprint 4 |
| **TS-05** | Como **arquitecto**, necesito que el servicio gestione el ciclo de vida de las **claves de cifrado por tenant** a través de la integración con KMS/HSM. | Alta | Sprint 4 |

---

## Epic 3: 👤 User Profiles Service (Identidad Funcional y Roles)

**Objetivo:** Gestionar los perfiles de usuario, sus relaciones con la estructura del tenant y los permisos funcionales, actuando como el puente entre la identidad y la gobernanza.

| ID | Historia de Usuario | Prioridad | Sprint Target |
|----|---------------------|-----------|---------------|
| **UP-01** | Como **Administrador de Condominio**, quiero poder **crear perfiles de usuario** y asignarlos a unidades con una relación específica (ej. `OWNER`, `TENANT`). | Crítica | Sprint 3 |
| **UP-02** | Como **Oficial de Cumplimiento**, quiero poder gestionar un **catálogo de roles y cargos oficiales** (ej. `PRESIDENTE`, `SECRETARIO`) basado en plantillas por jurisdicción. | Alta | Sprint 3 |
| **UP-03** | Como **propietario (Owner)**, quiero poder **delegar permisos temporales** (ej. derecho a voto) a mi arrendatario (Tenant) para una asamblea específica. | Alta | Sprint 5 |
| **UP-04** | Como **servicio backend**, necesito un endpoint `/evaluate` que determine si un usuario tiene un permiso específico (ej. `governance:vote`) en un contexto determinado. | Crítica | Sprint 3 |
| **UP-05** | Como **usuario**, quiero que mi **consentimiento para el tratamiento de datos** sea registrado de forma inmutable y versionado según la política que acepté. | Crítica | Sprint 3 |
| **UP-06** | Como **desarrollador**, necesito que el servicio emita eventos Kafka (`UserProfileUpdated`, `RoleAssigned`) para mantener la sincronización de datos en el ecosistema. | Alta | Sprint 3 |
