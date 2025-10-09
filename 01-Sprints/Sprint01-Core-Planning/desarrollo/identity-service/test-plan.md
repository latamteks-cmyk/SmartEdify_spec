# 🧪 Plan de Pruebas: Identity Service (3001)

## 1. Objetivos de las Pruebas

Este plan de pruebas tiene como objetivo garantizar que el `identity-service` cumpla con los más altos estándares de seguridad, rendimiento, resiliencia y corrección funcional, validando su rol como núcleo de confianza de la plataforma SmartEdify.

Las pruebas se derivan de los Criterios de Aceptación (DoD), la matriz de riesgos y los SLOs definidos en la especificación técnica.

---

## 2. Tipos de Pruebas

### 2.1. Pruebas Unitarias

- **Objetivo:** Validar la lógica de negocio interna de forma aislada.
- **Cobertura Mínima:** 85%.
- **Escenarios Clave:**
  - Validación de formatos de email y teléfono.
  - Lógica de generación de claims para JWT.
  - Verificación de pruebas de posesión DPoP.
  - Lógica de rotación y expiración de Refresh Tokens.
  - Serialización y deserialización de credenciales WebAuthn.

### 2.2. Pruebas de Integración

- **Objetivo:** Validar la correcta comunicación y colaboración entre el `identity-service` y sus dependencias críticas.
- **Escenarios Clave:**
  - **Flujo OIDC Completo:** Simular un cliente OIDC que completa el flujo `authorization_code` con PKCE y DPoP.
  - **Integración con Tenancy Service:** Verificar que el contexto de `tenant_id` y `condominium_id` se obtiene y se inyecta correctamente en los tokens.
  - **Integración con Compliance Service:** Simular una llamada al PDP durante un login de alto riesgo y verificar que la decisión (permitir/denegar) se acata.
  - **Publicación en Kafka:** Confirmar que los eventos de auditoría (ej. `LoginExitoso`, `TokenRevocado`) se publican en el topic `auth.events` con el formato y schema correctos.
  - **Rotación de JWKS:** Simular una rotación de claves y verificar que los servicios cliente pueden seguir validando tokens durante el período de `rollover`.

### 2.3. Pruebas de Seguridad (Pentesting y DAST)

- **Objetivo:** Identificar y mitigar vulnerabilidades de seguridad de forma proactiva.
- **Escenarios Clave:**
  - **Bypass de Autenticación:** Intentar acceder a recursos protegidos con tokens inválidos, expirados o sin firma DPoP.
  - **Ataques de Replay:** Intentar reutilizar códigos de autorización, JWTs y pruebas DPoP.
  - **Escalada de Privilegios:** Manipular los claims de un token para intentar obtener permisos elevados.
  - **Aislamiento de Tenants:** Intentar usar un token emitido para `tenant-A` para acceder a recursos de `tenant-B`.
  - **Validación de Flujos Inseguros:** Confirmar que el endpoint `/authorize` rechaza peticiones sin PKCE (flujo implícito).
  - **Seguridad de QR:** Intentar validar un QR después de su TTL o reutilizarlo.

### 2.4. Pruebas de Rendimiento y Carga

- **Objetivo:** Asegurar que el servicio cumple con los SLOs definidos bajo cargas de trabajo realistas y extremas.
- **Escenarios Clave:**
  - **SLO de Latencia:** Medir la latencia P95 de los endpoints `/oauth/token` y `/authorize` bajo una carga de 1000 RPM. **Objetivo: ≤ 3s**.
  - **SLO de Revocación Global:** Medir el tiempo que tarda en propagarse una revocación de sesión a todos los nodos. **Objetivo: P95 ≤ 30s**.
  - **Prueba de Estrés:** Aumentar la carga en el endpoint `/oauth/token` hasta encontrar el punto de quiebre para validar la efectividad del auto-escalado y el rate limiting.

### 2.5. Pruebas de Resiliencia (Chaos Engineering)

- **Objetivo:** Validar la capacidad del servicio para soportar fallos en sus dependencias y recuperarse de forma controlada.
- **Escenarios Clave (basados en el DRP):**
  - **Fallo del Compliance Service:** Simular una caída del `compliance-service` y verificar que el `identity-service` aplica la política de **fail-closed** (bloquea operaciones críticas) correctamente.
  - **Fallo de Redis:** Simular una caída del clúster de Redis y verificar que el servicio entra en **modo degradado** (deshabilitando el anti-replay de DPoP temporalmente) sin dejar de operar.
  - **Fallo de KMS:** Simular la indisponibilidad del KMS regional y verificar que el servicio conmuta a las claves de respaldo en **menos de 30 segundos**.
  - **Latencia en Tenancy Service:** Introducir latencia en las llamadas al `tenancy-service` y verificar que el `identity-service` utiliza su caché local para no degradar el rendimiento.

---

## 3. Herramientas y Entorno

- **Pruebas Unitarias/Integración:** JUnit 5, Mockito, Testcontainers (para PostgreSQL y Kafka).
- **Pruebas de API:** Postman/Newman, REST Assured.
- **Pruebas de Carga:** k6, Gatling.
- **Pruebas de Seguridad:** OWASP ZAP, Snyk.
- **Chaos Engineering:** Gremlin, Istio Fault Injection.
- **Entorno:** Las pruebas se ejecutarán en un entorno de `staging` aislado y como parte del pipeline de CI/CD en GitLab.
