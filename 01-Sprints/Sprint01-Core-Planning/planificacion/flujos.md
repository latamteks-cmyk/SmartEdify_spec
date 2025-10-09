Basado en el **backlog.md actualizado**, los documentos de arquitectura (`vision_document.md`, `software_architecture.md`, `CTO_Review_Sprint1_Backbone.md`) y las **buenas prácticas de ingeniería de software** (API-First, Event-Driven, Zero Trust, Observabilidad, Privacy by Design), he elaborado una **lista estructurada de flujos del Sprint 1 Backbone**, vinculando cada flujo con:

- Los **Epics y User Stories** que lo componen,
- Los **artefactos técnicos obligatorios** (especificaciones, diagramas, métricas),
- Y las **convenciones de diseño** que deben respetarse.

---

## 🔄 Lista de Flujos del Sprint 1 Backbone

| ID Flujo | Nombre del Flujo | Epics / Historias Clave | Artefactos Técnicos Obligatorios | Convenciones Aplicadas |
|----------|------------------|--------------------------|----------------------------------|------------------------|
| **F-01** | **Registro y Activación Delegada** | - UP-01 (crear perfil)<br>- ID-01 (registro WebAuthn)<br>- UP-05 / UP-08 (consentimiento)<br>- ID-04 / ID-10 (WORM + attestation) | - Diagrama de secuencia (PlantUML)<br>- OpenAPI: `POST /profiles`, `POST /identity/register`<br>- Modelo DBML: tabla `memberships`<br>- Threat Model: STRIDE para activación<br>- Métrica: `activation_success_rate` | - Privacy by Design (PDR-4)<br>- WORM logging (SAD §9.3)<br>- Consent versioning (GDPR/LGPD)<br>- Aislamiento por `tenant_id` (RLS) |
| **F-02** | **Autenticación Segura con WebAuthn + DPoP** | - ID-01, ID-02, ID-06, ID-08, ID-09<br>- PLT-02 (`kid` ↔ JWKS)<br>- ID-11 (mock KMS en CI) | - Diagrama OIDC + WebAuthn + DPoP<br>- OpenAPI: `/authorize`, `/token`, `/userinfo`<br>- Especificación DPoP (headers, clock skew, anti-replay)<br>- Métricas: `webauthn_assertion_latency_p95`, `dpop_replay_block_rate`<br>- CI Job: `kid_consistency_check` | - Zero Trust (PDR-3)<br>- OAuth 2.1 + PKCE<br>- DPoP mandatory (SAD §9.2)<br>- Rate-limit + proof-of-work (ADR-017) |
| **F-03** | **Revocación Global de Sesión** | - ID-07, ID-12<br>- PLT-04 (métricas RED) | - Diagrama de invalidación (sincrónica + asíncrona)<br>- Esquema Kafka: `SessionRevoked.v1`<br>- Métrica: `revocation_latency_p95 ≤ 30s`<br>- Runbook: revocación de dispositivo | - Fail-fast (SAD §6.4)<br>- Event-driven (PDR-7)<br>- Observabilidad end-to-end (PDR-6) |
| **F-04** | **Validación de Membresía y Contexto Organizacional** | - UP-01, UP-04, UP-07<br>- TS-02, TS-06<br>- TS-08, PLT-03 (propagación de contexto) | - OpenAPI: `GET /profiles/{user}/memberships`<br>- Diagrama de consulta con RLS<br>- Modelo de datos: relación `user ↔ unit ↔ condominium`<br>- Métrica: `pdp_latency_p95` | - PBAC con OPA (SAD §6.1)<br>- RLS por `tenant_id` + `condominium_id`<br>- Clean Architecture (PDR-2) |
| **F-05** | **Generación y Validación de QR de Identidad (Contextual Token)** | - ID-05<br>- ID-10 (attestation en WORM)<br>- UP-07 (cargo oficial) | - Especificación COSE/JWS (claims, `kid`, TTL ≤300s)<br>- OpenAPI: `POST /contextual-tokens`, `POST /validate`<br>- Diagrama de generación y validación<br>- Métrica: `qr_generation_latency_p95 ≤ 500ms` | - Firma electrónica avanzada (Vision Doc §4.1)<br>- Device binding (SAD §9.4)<br>- Uso exclusivo para fines legales (ADR-014) |
| **F-06** | **Propagación de Contexto y Observabilidad por Tenant** | - TS-08, PLT-03<br>- PLT-04 (métricas RED) | - Guía de enriquecimiento OTel<br>- Lista de atributos: `tenant_id`, `condominium_id`, `user_role`<br>- Dashboard base en Grafana<br>- Alerta: `policy_version_skew > 1` | - Observabilidad por tenant (PDR-6)<br>- OpenTelemetry Semantic Conventions<br>- SLO monitoring (SAD §11.1) |
| **F-07** | **Gestión de Consentimiento y DSAR** | - UP-05, UP-08, UP-09, UP-10<br>- ID-04 (WORM) | - Matriz de trazabilidad de consentimiento<br>- OpenAPI: endpoints DSAR proxy<br>- Esquema Kafka: `ConsentRevoked.v1`<br>- Política de cifrado PII por tenant (KMS) | - Privacy by Design (PDR-4)<br>- GDPR Art. 7 / LGPD Art. 8<br>- Cifrado de PII (SAD §6.2) |
| **F-08** | **Resiliencia y Hardening Técnico** | - PLT-01 (caos)<br>- ID-11 (mock KMS)<br>- H-01…H-07 (CTO Review) | - Plan de pruebas de caos (Compliance fail-closed, Redis/JWKS)<br>- Script CI: `jwks_interop_test`, `dpop_replay_test`<br>- Runbook: caída de Compliance<br>- Métricas: `compliance_fail_closed_trigger_count`, `kid_mismatch_detected_total` | - Chaos Engineering (SAD §11.2)<br>- Circuit Breaker (Vision Doc §6.1)<br>- Fail-closed (ADR-012) |

---

## 📌 Convenciones y Buenas Prácticas Clave Aplicadas

| Categoría | Convención |
|----------|-----------|
| **API Design** | OpenAPI 3.1 como contrato único; versionado en URL (`/v1/`) |
| **Seguridad** | DPoP obligatorio, WebAuthn AAL3, prohibido HS256, mTLS en malla |
| **Datos** | RLS estricto, PII cifrado por tenant, modelo de membresías explícito |
| **Eventos** | Schema Registry obligatorio, eventos versionados (`*.v1`), idempotencia |
| **Observabilidad** | Atributos de negocio en OTel, dashboards por servicio, alertas basadas en SLO |
| **Calidad** | CI con validación de `kid`/JWKS, contract tests, pentest obligatorio |
| **Resiliencia** | Circuit breaker, fallback con TTL, modo degradado con WORM |

---

## ✅ Recomendación Final

Cada flujo debe tener un **dueño técnico** (Tech Lead del Epic) y un **artefacto principal** (ej. diagrama o especificación) que sirva como **contrato de implementación**.  
Estos flujos son **autocontenidos dentro del Sprint 1–4** y **no dependen de Governance, Compliance ni Documents en runtime**.
