# 🎯 Alcance del Servicio: Identity Service (3001)

## 1. Propósito y Rol en el Ecosistema

El **Identity Service** es la **autoridad central de identidad (IdP)** para toda la plataforma SmartEdify. Su responsabilidad principal es gestionar el ciclo de vida de la identidad digital, la autenticación y las sesiones de todos los actores del sistema (usuarios y máquinas) de una manera segura, resiliente y conforme a las normativas.

Actúa como la puerta de entrada segura y el pilar de la confianza criptográfica, implementando un modelo **Zero Trust** donde cada solicitud de acceso es explícitamente verificada.

---

## 2. Funcionalidades Dentro del Alcance (In Scope)

- **Gestión del Ciclo de Vida de Credenciales:**
  - Registro y mantenimiento de credenciales de autenticación fuerte **(WebAuthn/Passkeys)**.
  - Gestión de métodos AAL2 como TOTP para casos de uso específicos.

- **Procesos de Autenticación:**
  - Ejecución de flujos de autenticación multi-factor (MFA) adaptativos.
  - Validación de credenciales y aplicación de políticas de seguridad de contraseñas (HaveIBeenPwned).

- **Emisión y Gestión de Tokens:**
  - Implementación de un servidor de autorización **OAuth 2.1**.
  - Emisión de Access Tokens (JWT) y Refresh Tokens con el mecanismo de seguridad **DPoP (sender-constrained)**.
  - Gestión del ciclo de vida de Refresh Tokens, incluyendo rotación y revocación.

- **Gestión de Sesiones:**
  - Creación, mantenimiento y revocación de sesiones de usuario.
  - Implementación de **logout global** a través de eventos y el claim `not_before`.

- **Generación de Artefactos Criptográficos:**
  - Emisión de **QR contextuales firmados (COSE/JWS)** para casos de uso de validez legal (ej. acceso a asambleas).
  - Publicación de claves públicas a través de endpoints **JWKS por tenant**.

- **Procesos de Cumplimiento y Privacidad:**
  - Iniciación y orquestación de flujos de **DSAR (Data Subject Access Request)**, delegando en otros servicios para la ejecución.
  - Registro inmutable de todos los eventos de seguridad y auditoría en un sistema **WORM**.

- **Integración y Descubrimiento:**
  - Exposición de endpoints de descubrimiento **OIDC (`.well-known/openid-configuration`)** por tenant para facilitar la federación B2B.

---

## 3. Funcionalidades Fuera de Alcance (Out of Scope)

Este servicio tiene límites estrictos para mantener un bajo acoplamiento y una alta cohesión:

- ❌ **No gestiona datos de perfil de usuario:** La información personal (nombre, preferencias, etc.) y los atributos no relacionados con la autenticación son responsabilidad del **`user-profiles-service`**.

- ❌ **No gestiona la jerarquía organizacional:** La estructura de tenants, condominios, edificios y unidades es gestionada exclusivamente por el **`tenancy-service`**.

- ❌ **No define ni evalúa políticas de negocio o cumplimiento:** La lógica de autorización (ej. "¿puede este usuario votar?") y la validación de normativas son delegadas en tiempo de ejecución al **`compliance-service`**.

- ❌ **No almacena PII sensible:** Datos como el identificador nacional (DNI, RUC, etc.) no se almacenan en este servicio. Su gestión y cifrado son responsabilidad de otros servicios del dominio Core.

---

## 4. Dependencias Críticas

- **`tenancy-service` (Síncrona):** Para obtener el contexto organizacional (tenant, condominio) de un usuario durante el proceso de autenticación y emisión de tokens.
- **`compliance-service` (Síncrona):** Para validar en tiempo de ejecución si un intento de autenticación o una operación crítica (ej. emisión de QR) cumple con las políticas legales y de negocio vigentes.
- **`user-profiles-service` (Síncrona):** Para obtener información de roles o cargos oficiales que deban ser incluidos como claims en los tokens.
- **`Kafka` (Asíncrona):** Para la publicación de eventos de auditoría (`auth.events`) de forma desacoplada y resiliente.
- **`KMS/HSM` (Infraestructura):** Para la gestión segura del ciclo de vida de las claves criptográficas utilizadas para firmar tokens y QRs.
