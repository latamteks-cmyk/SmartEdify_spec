# smartedify_spec

Repositorio de **especificaciones funcionales y técnicas** de SmartEdify.
Contiene la visión, arquitectura, alcances por microservicio, ADRs, OpenAPI, DBML, planes de prueba y artefactos de despliegue documental alineados con un **proceso ágil de sprints** y enfoque **mobile-first**.

---

## 🎯 Objetivo

* Ser la **fuente única de verdad** de la documentación.
* Evitar contradicciones entre documentos mediante **plantillas y CI documental**.
* Asegurar trazabilidad desde **Visión → SAD → Scope Global → Scope por servicio → ADRs → OpenAPI/DBML → QA/Runbooks**.

---

## 📂 Estructura

```
smartedify_spec/
├─ 00-Governance/
│  ├─ vision_document.md
│  ├─ software_architecture.md         # SAD
│  ├─ system_scope.md                  # SCOPE global
│  ├─ roadmap_gantt.md
│  ├─ threat_model.md
│  ├─ security_policies.md
│  └─ adr/
│     ├─ ADR-001-Architecture-Base.md
│     ├─ ADR-002-Passkey-Recovery.md
│     ├─ ADR-004-OPA-Bundle-Signing.md
│     ├─ ADR-005-EdDSA-Support.md
│     ├─ ADR-011-Validation-Metrics.md
│     ├─ ADR-016-Condominium-Entity.md
│     └─ ...
│
├─ 01-Sprints/
│  ├─ Sprint01-Core-Planning/
│  │  ├─ planificacion/
│  │  │  ├─ sprint_goal.md
│  │  │  ├─ backlog.md
│  │  │  ├─ team_roles.md
│  │  │  └─ risk_matrix.md
│  │  ├─ desarrollo/
│  │  │  ├─ identity-service/
│  │  │  │  ├─ scope-identity.md
│  │  │  │  ├─ openapi.yaml
│  │  │  │  ├─ dbml-schema.dbml
│  │  │  │  └─ test-plan.md
│  │  │  ├─ user-profiles-service/
│  │  │  ├─ tenancy-service/
│  │  │  └─ compliance-service/
│  │  ├─ pruebas/
│  │  │  ├─ unit-tests/report-summary.md
│  │  │  ├─ integration-tests/
│  │  │  └─ qa_checklist.md
│  │  └─ despliegue/
│  │     ├─ deploy-guide.md
│  │     ├─ rollback-plan.md
│  │     ├─ pipeline-config.yaml
│  │     └─ changelog.md
│  └─ SprintXX-.../
│
├─ 02-Shared-Docs/
│  ├─ templates/                      # Plantillas estándar
│  │  ├─ scope-template.md
│  │  ├─ sprint-plan-template.md
│  │  ├─ test-plan-template.md
│  │  └─ deployment-checklist.md
│  ├─ schemas/
│  │  ├─ dbml/
│  │  ├─ openapi/
│  │  └─ kafka-schemas/
│  ├─ diagrams/
│  │  ├─ architecture/
│  │  ├─ sequence-flows/
│  │  ├─ entity-relationships/
│  │  └─ gantt-roadmaps/
│  ├─ runbooks/
│  │  ├─ backup_restore.md
│  │  ├─ incident_response.md
│  │  ├─ drp_strategy.md
│  │  └─ service_checklist.md
│  ├─ legal/
│  │  ├─ compliance_matrix.md
│  │  ├─ regulatory_mapping.md
│  │  └─ privacy_by_design.md
│  └─ observability/
│     ├─ metrics_definitions.md
│     ├─ alert_rules.yaml
│     ├─ dashboards_grafana.json
│     └─ tracing_guidelines.md
│
├─ 03-Deliverables/
│  ├─ pmv_release_notes/
│  ├─ qa_reports/
│  ├─ penetration_tests/
│  ├─ audit_artifacts/
│  └─ certification_packages/
│
└─ 04-Operations/
   ├─ preprod_environment.md
   ├─ production_environment.md
   ├─ service_catalog.md
   ├─ monitoring_guide.md
   ├─ security_incident_register.md
   └─ change_management.md
```

---

## 🧩 Convenciones

* **Niveles documentales**

  * N0: Visión.
  * N1: SAD.
  * N2: SCOPE global.
  * N3: `Scope-[service].md` + OpenAPI + DBML + Test Plan.
  * N4: ADRs.
* **Códigos de artefactos**

  * Documentos: `DOC-*`
  * Servicios: `SRV-<alias>-<port>`
  * QA: `QA-*`
  * Release/Deploy: `REL-*`
* **Mobile-first**: flujos críticos priorizados en móvil (asambleas, reservas, incidencias, notificaciones, QR).
* **Multi-tenant/condominio**: todo lo operativo se contextualiza con `(tenant_id, condominium_id, jurisdiction, policy_version)`.

---

## 📜 Cómo agregar un nuevo servicio

1. Crear `01-Sprints/SprintYY-.../desarrollo/<service-name>/`.
2. Copiar plantilla `02-Shared-Docs/templates/scope-template.md` → `scope-<service>.md`.
3. Añadir `openapi.yaml` y `dbml-schema.dbml` en la carpeta del servicio.
4. Registrar eventos en `02-Shared-Docs/schemas/kafka-schemas/`.
5. Añadir pruebas en `test-plan.md` y checklist QA.
6. Si hay decisiones clave, crear ADR en `00-Governance/adr/`.

---

## 🔁 Flujo de cambio (PR)

1. **Actualizar**: Scope del servicio + OpenAPI + DBML.
2. **Vincular**: ADRs afectados.
3. **CI documental** valida:

   * OpenAPI 3.1 (lint y breaking changes).
   * DBML (schema y relaciones).
   * Enlaces internos y tablas de contenido.
4. **Revisión**: Arquitectura y Seguridad.
5. **Merge** cuando todas las comprobaciones aprueben.

---

## ✅ Definición de Hecho (DoD) documental por servicio

* `scope-<service>.md` actualizado y consistente con SCOPE global.
* `openapi.yaml` y `dbml-schema.dbml` validados en CI.
* Eventos en Schema Registry con *compatibility=BACKWARD*.
* `test-plan.md` con criterios funcionales, seguridad y SLOs.
* Runbook mínimo en `02-Shared-Docs/runbooks/service_checklist.md`.

---

## 🛡️ Seguridad y cumplimiento

* Zero Trust, OIDC/OAuth 2.1, DPoP, PBAC (OPA/Cedar).
* RLS por `(tenant_id, condominium_id)`.
* WORM para evidencias legales.
* DSAR orquestado y auditable.
* Firmas electrónicas **solo** cuando un documento y firmantes lo requieran.

---

## 📈 Observabilidad

* Métricas mínimas por servicio en `02-Shared-Docs/observability/metrics_definitions.md`.
* Reglas de alertas en `alert_rules.yaml`.
* Dashboards base Grafana.

---

## 🤝 Contribuciones

* Estándar de PR: título claro, scope afectado, ADRs relacionados, checklist DoD.
* Issues con etiquetas: `scope`, `openapi`, `dbml`, `adr`, `qa`, `security`, `observability`.
* Propuestas de cambio mayor requieren ADR.

---

## 📬 Contacto

* **CTO / Arquitectura**: [arquitectura@smartedify.global](mailto:arquitectura@smartedify.global)
* **Seguridad**: [security@smartedify.global](mailto:security@smartedify.global)
* **PMO**: [pmo@smartedify.global](mailto:pmo@smartedify.global)

---

## 📝 Licencia

Documentación interna de SmartEdify. Uso sujeto a políticas corporativas.
