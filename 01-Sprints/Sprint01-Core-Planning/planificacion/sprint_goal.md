# 🎯 Sprint Goal: Sprint 01 - Core Planning

**Período:** 2025-09-15 – 2025-09-29

## 1. Objetivo Principal

Establecer las bases técnicas, arquitectónicas y operativas para construir un **Core Backbone production-ready**, alineado con los principios de **Zero Trust, Privacy by Design, Observabilidad y Cumplimiento Normativo**.  
Este sprint se enfoca exclusivamente en **planificación, especificación y diseño**, no en desarrollo de código de producción.  
Al finalizar, el equipo contará con un **contrato técnico ejecutable** que guíe la implementación en los sprints siguientes.

Al final de este sprint, el equipo tendrá una comprensión inequívoca del "qué", el "porqué" y el "cómo" de los servicios que forman el núcleo de nuestra plataforma.

## 2. Objetivos Clave (Key Objectives)

### ✅ 2.1 Finalizar y Aprobar Especificaciones Técnicas de Alto Nivel  
- Revisar y alinear las especificaciones de los tres servicios con:
  - El [Documento de Visión](./00-Governance/vision_document.md)
  - El [Software Architecture Document](./00-Governance/software_architecture.md)
  - Los **ADR aprobados** (ADR-001 a ADR-017)
  - Las **acciones de hardening del CTO** (H-01 a H-07)
  - Asegurar que cada servicio defina explícitamente:
  - Contratos de API (OpenAPI 3.1)
  - Modelo de datos (DBML con RLS)
  - Métricas RED y SLOs
  - Estrategia de observabilidad (OTel attributes)
  - Modo de degradación y fallback

### ✅ 2.2 Construir un Backlog Técnico y Funcional Priorizado  
- Desglosar las especificaciones en **historias de usuario funcionales** y **historias técnicas transversales** (seguridad, observabilidad, resiliencia).
- Incluir explícitamente las historias derivadas de las **acciones H-01 a H-07** del CTO Review.
- Priorizar para lograr un **MVP técnicamente sólido** en Sprint 2–4, con capacidad de pasar a **Release Candidate (RC)** tras el hardening.

### ✅ 2.3 Definir la Estrategia de Calidad y Observabilidad desde el Día 0  
- Establecer los **artefactos obligatorios de calidad** por servicio:
  - Plan de pruebas de caos (Compliance fail-closed, JWKS rotación)
  - Suite de pruebas de interoperabilidad (JWKS externos, DPoP anti-replay)
  - Benchmarks de latencia WebAuthn por plataforma
  - Esquemas de eventos en Schema Registry (`AuthSuccess.v1`, `SessionRevoked.v1`)
- Definir el **dashboard mínimo de métricas** para RC (incluyendo `kid_mismatch_detected_total`, `compliance_fail_closed_trigger_count`, `webauthn_*_latency_p95`).

### ✅ 2.4 Formalizar Roles, Responsabilidades y Flujo de Trabajo  
- Asignar responsables claros para:
  - Arquitectura y ADRs (Tech Lead / Software Architect)
  - Calidad y pruebas (QA Lead)
  - Seguridad y cumplimiento (Security Champion)
  - Observabilidad y SRE (DevEx / SRE Engineer)
- Definir el **flujo de validación de cambios**: PR → revisión de ADR → CI con validación de `kid`/JWKS → merge.

### ✅ 2.5 Identificar y Mitigar Riesgos Técnicos Críticos  
- Documentar riesgos clave:
  - Complejidad del anti-replay DPoP
  - Disponibilidad del KMS en CI
  - Inconsistencia `kid` ↔ JWKS
  - Baja adopción de Passkey en móviles
- Establecer mitigaciones concretas:
  - Mock KMS en CI (H-05)
  - TTL ≤60s en Redis regional (H-04)
  - Test automático en pipeline (H-06)
  - Pruebas de usabilidad real (H-06)

## 3. Definición de Hecho (Definition of Done)

El Sprint 01 se considerará completado **solo cuando todos los siguientes artefactos estén aprobados y disponibles en el repositorio del proyecto**:

- [x] `sprint_goal.md` (este documento) actualizado y aprobado por CTO y Product Manager.  
- [x] `backlog.md` actualizado con **historias funcionales y técnicas**, priorizadas y vinculadas a las acciones H-01…H-07.  
- [x] `team_roles.md` definido con roles explícitos (Tech Lead, Security Champion, QA Lead, etc.).  
- [x] `risk_matrix.md` con riesgos técnicos y plan de mitigación aprobado.  
- [x] Especificaciones técnicas de los tres servicios (`identity`, `user-profiles`, `tenancy`) en estado **✅ Aprobado** por el CTO.  
- [x] **Plantillas base** para los artefactos críticos:
  - `ADR-template.md`
  - `openapi-template.yaml`
  - `dbml-model-template.dbml`
  - `chaos-test-plan-template.md`
  - `metrics-dashboard-spec.md`

> **Nota del CTO**:  
> Este sprint no entrega valor de usuario directo, pero **entrega la confianza técnica necesaria** para construir una infraestructura crítica.  
> La calidad de la planificación aquí determinará la velocidad, seguridad y cumplimiento de toda la Fase 1.
