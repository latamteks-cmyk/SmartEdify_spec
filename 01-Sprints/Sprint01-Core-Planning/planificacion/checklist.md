# ✅ Checklist de Cierre — Sprint 1 Backbone (SmartEdify)
**Fecha de generación:** 2025-10-09 11:56:07  
**Ámbito:** Identity (3001), User Profiles (3002), Tenancy (3003), Plataforma, BFF/Frontends, Documentación y Operaciones.  
**Formato:** `Responsable — [ ] Tarea` (todas las tareas son atómicas y verificables).

---

## 0. Gobierno del Sprint
- **PM/PO** — [ ] Congelar alcance Sprint 1 y criterios de salida.
- **PM/PO** — [ ] Publicar cronograma y hitos (staging, RC, producción).
- **PM/PO** — [ ] Asignar responsables por servicio y aprobar carga.

---

## 1) Identity Service (3001)
- **Identity Lead** — [ ] Implementar issuer por tenant: `https://auth.{region}.smartedify.global/t/{tenant_id}` (discovery por path).
- **Identity Lead** — [ ] Exponer `/{tenant_id}/.well-known/openid-configuration` y `/{tenant_id}/.well-known/jwks.json`.
- **Identity Dev** — [ ] Flujos OIDC: `/authorize`, `/oauth/par`, `/oauth/token`, `/oauth/introspect`, `/oauth/revoke`, `/userinfo`.
- **Identity Dev** — [ ] Enforce PKCE en `authorization_code` y prohibir `implicit`/`hybrid`.
- **Identity Dev** — [ ] DPoP: validar `htu|htm|jti|ath`, clock skew y anti-replay en Redis regional.
- **Identity Dev** — [ ] WebAuthn: registro y autenticación; AAL2/AAL3 con attestation cuando aplique.
- **Identity Dev** — [ ] Fallback TOTP: enrolamiento y recuperación solo con app certificada.
- **Identity Dev** — [ ] Refresh tokens: rotación + reuse-detection + `cnf.jkt` (sender-constrained).
- **Identity Dev** — [ ] Logout global: `/logout` + `backchannel-logout` + `not-before` por `sub`.
- **Identity Dev** — [ ] QR de identidad (COSE/JWS, TTL 300 s, `kid`): `POST /identity/v2/contextual-tokens` y `/validate`.
- **Identity SRE** — [ ] JWKS: rotación 90 d, rollover 7 d, cache TTL ≤ 5 min, background refresh.
- **Identity SRE** — [ ] Métricas: `auth_latency_p95`, `token_validation_error_rate`, `revocation_latency_p95`.
- **QA** — [ ] E2E: registro → activación → login → revocación.
- **SecOps** — [ ] Pentest de flujos OIDC/DPoP/WebAuthn y fuzzing de JWT.

---

## 2) User Profiles Service (3002)
- **Profiles Lead** — [ ] CRUD de perfiles con verificación de identidad (enlace con Identity).
- **Profiles Dev** — [ ] Roles y delegaciones con expiración/TTL y auditoría de uso.
- **Profiles Dev** — [ ] Relación `profile ↔ unit ↔ condominium` con constraints y RLS.
- **Profiles Dev** — [ ] Evaluador PBAC `/evaluate` con OPA bundles **firmados** (Ed25519/ES256).
- **Profiles Dev** — [ ] Invalidation push de cache al cambiar roles/delegaciones.
- **Profiles Dev** — [ ] DSAR proxy: export/borrado coordinado con Compliance/Documents.
- **Profiles SRE** — [ ] Métricas: `pdp_latency_p95`, `pdp_cache_hit_rate`, `pdp_cache_invalidation_latency_p95`.
- **QA** — [ ] Tests de idempotencia y conflictos de membresía (RFC 7807).

---

## 3) Tenancy Service (3003)
- **Tenancy Lead** — [ ] Modelo jerárquico `tenant → condominium → building → unit → space`.
- **Tenancy Dev** — [ ] API CRUD (RFC 7807) + búsquedas por contexto.
- **Tenancy Dev** — [ ] Metadatos: `data_residency`, `region_code`, `jurisdiction_id`.
- **Tenancy Dev** — [ ] Eventos Kafka: `TenantCreated`, `JurisdictionChanged`, `UnitReassigned` (Schema Registry).
- **Tenancy DBA** — [ ] RLS por `tenant_id`; índices y cardinalidades validadas.
- **Tenancy SRE** — [ ] Fallback de lookups firmados (KMS) cuando el servicio no esté disponible.
- **QA** — [ ] Pruebas de consistencia jerárquica y reconciliación cross-region.

---

## 4) Plataforma (Gateway, Cache, Mensajería, Observabilidad, Seguridad)
- **Platform Lead** — [ ] Gateway (8080) con validación JWT+DPoP, rate-limits por `tenant_id`/IP/ASN.
- **Platform Dev** — [ ] Redis regional: espacios para JWKS cache, anti-replay DPoP, sesiones.
- **Platform Dev** — [ ] Kafka + Schema Registry + DLQ + Retention policies.
- **Platform SRE** — [ ] Prometheus/Grafana/OTel Collector; paneles base por servicio.
- **Platform SecOps** — [ ] mTLS en malla (Istio), rotación de certs 90 d.
- **Platform SecOps** — [ ] Secrets Manager: rotación automática, acceso por política mínima.
- **Platform SRE** — [ ] Backups automáticos; RTO/RPO: Identity ≤5m/≤1m; Profiles/Tenancy ≤15m/≤5m.
- **Platform SRE** — [ ] DRP y pruebas de restore verificadas.

---

## 5) BFFs y Frontend (Pista PMV)
- **BFF Lead** — [ ] BFF Admin/User/Mobile: proxies autenticados, sin lógica de negocio.
- **Web Admin** — [ ] Login PKCE, gestión básica de usuarios, invitaciones, selector tenant/condominio.
- **Web User** — [ ] Login PKCE, activación por invitación, perfil y relaciones.
- **Mobile** — [ ] Login PKCE + DPoP, lector de **QR de identidad** y notificaciones.
- **FE Eng** — [ ] No almacenar tokens en `localStorage`; usar cookies HTTPOnly o token storage seguro vía BFF.
- **FE Eng** — [ ] Internacionalización básica y accesibilidad AA.
- **FE/OTel** — [ ] Telemetría web (trace/correlation IDs) hasta BFF y Gateway.
- **QA** — [ ] E2E Web/Mobile: activación → login → lectura de catálogos.

---

## 6) Notificaciones y Documentos (mínimos para PMV)
- **Notifications Dev** — [ ] Envío de invitaciones con deep link y expiración.
- **Notifications Dev** — [ ] Plantillas transaccionales multi-idioma.
- **Documents Dev** — [ ] WORM para evidencias mínimas (login crítico, activación, cambios de rol).
- **QA** — [ ] Verificación de un solo uso del enlace y expiración.

---

## 7) Seguridad y Cumplimiento
- **SecOps** — [ ] Política anti-enumeración (rate-limit + respuestas homogéneas + opcional proof-of-work).
- **SecOps** — [ ] Política de recuperación de credenciales AAL2 (sin SMS/email only).
- **SecOps/Compliance** — [ ] Modo degradado de Compliance (marcador + SLA ≤24 h + auditoría WORM).
- **SecOps** — [ ] Pentest de endpoints críticos y auditoría de permisos PBAC.
- **Compliance** — [ ] Boletines normativos y seeds de cargos firmantes por jurisdicción.

---

## 8) Observabilidad y Métricas
- **Observability** — [ ] Dashboards: `auth_latency_p95`, `token_validation_error_rate`, `jwks_refresh_latency_p95`, `revocation_latency_p95`.
- **Observability** — [ ] Métricas adicionales: `pdp_latency_p95`, `device_attestation_failure_rate`, `dpop_replay_block_rate`.
- **Observability** — [ ] Alertas: expiración próxima de claves, `policy_version_skew > 1`, DLQ > 0.
- **Observability** — [ ] Trazas de extremo a extremo (FE → BFF → Gateway → Servicio).

---

## 9) CI/CD y Calidad
- **DevEx** — [ ] Lint y validación **OpenAPI 3.1** (tres servicios) en pipeline.
- **DevEx** — [ ] Contract tests BFF↔Gateway↔Servicios.
- **DevEx** — [ ] SCA/DAST, secrets scanning, firma de imágenes, SBOM.
- **DevEx** — [ ] Policy-as-Code (OPA) en el pipeline; bundles firmados y verificados.
- **QA** — [ ] Pruebas de carga: `auth_latency_p95` y `revocation_latency_p95` dentro de SLO.
- **QA** — [ ] Chaos tests mínimos: caída de Compliance, latencia Redis/JWKS cross-region.

---

## 10) Datos Semilla y Feature Flags
- **Data Eng** — [ ] Semillas: tenant demo, condominio, unidades y usuarios admin.
- **Data Eng** — [ ] Semillas de roles base y cargos firmantes por jurisdicción.
- **FE Lead** — [ ] Feature flags para habilitar Governance/Reservations en Sprint 2.

---

## 11) Documentación
- **Tech Writer** — [ ] SAD.md Global actualizado (v1.1).
- **Tech Writer** — [ ] Especificaciones técnicas: Identity, Profiles, Tenancy (v1.x).
- **Tech Writer** — [ ] OpenAPI 3.1 publicados y enlazados.
- **Tech Writer** — [ ] Threat Model Backbone (STRIDE/LINDDUN) actualizado.
- **Tech Writer** — [ ] Runbooks: rotación JWKS/KMS, revocación global, DRP, caída de Compliance.
- **Tech Writer** — [ ] Readme de Frontend/BFF con prácticas de seguridad (PKCE, DPoP, storage).

---

## 12) Go/No-Go y Post-Release
- **SRE/PM** — [ ] Checklist Go/No-Go firmado por áreas (Dev, QA, Sec, Compliance).
- **SRE** — [ ] Runbook de rollback y ventanas de mantenimiento.
- **PM/PO** — [ ] Plan de soporte post-release y canal de incidencias.

> **Criterio de salida Sprint 1:** Registro→Activación→Login→Revocación→Lectura de catálogos funcionando en staging, con observabilidad, seguridad y DRP verificados.
