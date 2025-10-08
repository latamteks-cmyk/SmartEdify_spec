<div style="text-align: center;">
  <img 
    src="../branding/Logo_smartedify.jpg" 
    width="300" 
    height="300" 
    alt="Logo de SmartEdify" 
    style="display: block; margin: 0 auto;"
  />
  <h3>Gestión integral de condominios</h3>
</div>

---

# 📘 **SmartEdify — Documento de Visión**

## 1. Propósito

Definir la dirección estratégica, alcance funcional y marco de valor del ecosistema **SmartEdify**, una plataforma integral para la gestión de comunidades residenciales, administración de condominios y operaciones asociadas, centrada en **eficiencia, cumplimiento legal y experiencia digital unificada**.

---

## 2. Contexto y Problema

Los condominios y comunidades gestionan múltiples sistemas desconectados (asambleas, finanzas, mantenimiento, nómina, comunicación).
Esto genera:

* Falta de trazabilidad legal (actas, votos, decisiones).
* Descoordinación entre áreas operativas y administrativas.
* Escasa visibilidad financiera y de cumplimiento normativo.
* Baja participación de los residentes por interfaces no móviles.

---

## 3. Solución Propuesta

**SmartEdify** centraliza la gestión mediante una arquitectura de microservicios interoperables, con soporte a:

* Autenticación y gobierno digital (OIDC/OAuth2, Zero Trust).
* Cumplimiento legal automatizado y multi-jurisdiccional.
* Trazabilidad auditable e inmutable (WORM + Kafka).
* Experiencia **mobile-first** con Web y App híbrida.

---

## 4. Objetivos Estratégicos

| Código | Objetivo                                         | Métrica de éxito                    |
| ------ | ------------------------------------------------ | ----------------------------------- |
| O1     | Gestionar identidad y acceso seguro multi-tenant | 99.9% uptime en Auth                |
| O2     | Digitalizar asambleas y decisiones               | 90% actas firmadas electrónicamente |
| O3     | Automatizar operaciones financieras y RRHH       | 95% conciliación sin error          |
| O4     | Mejorar comunicación y trazabilidad              | 80% adopción app móvil              |
| O5     | Cumplimiento legal multi-país                    | Certificación ISO 27001 / SOC2      |

---

## 5. Usuarios y Personas

| Tipo                                 | Descripción                               | Interacción Principal   |
| ------------------------------------ | ----------------------------------------- | ----------------------- |
| **Administrador General**            | Administra múltiples condominios (tenant) | Web Admin               |
| **Administrador Local / Condominio** | Gestiona un edificio o comunidad          | Web Admin / Mobile      |
| **Residente / Propietario**          | Participa en asambleas, reservas, pagos   | Mobile-first            |
| **Trabajador / Contratista**         | Registra asistencia y tareas              | Mobile / Asset Mgmt     |
| **Proveedor / Prestador**            | Factura y ejecuta servicios               | Web / Mobile            |
| **Autoridad Legal / Notario**        | Valida documentos y firmas                | Compliance / Governance |
| **Auditor / Fiscalizador**           | Supervisa cumplimiento legal              | Compliance / Finance    |

---

## 6. Alcance Funcional (Macro)

| Dominio        | Microservicios Clave                          | Descripción                                                               |
| -------------- | --------------------------------------------- | ------------------------------------------------------------------------- |
| **Core**       | Identity, User Profiles, Tenancy, Compliance  | Núcleo de autenticación, gestión de usuarios, inquilinos y cumplimiento.  |
| **Governance** | Governance, Reservation, Streaming, Documents | Administración de asambleas, reservas, sesiones híbridas y actas legales. |
| **Operations** | Asset Mgmt, Payroll, Finance, HR Compliance   | Mantenimiento, finanzas, nómina y obligaciones regulatorias.              |
| **Business**   | Marketplace, Analytics                        | Servicios comerciales, estadísticas y proyección.                         |
| **Platform**   | Observability, Policy CDN, Messaging, Storage | Infraestructura común, seguridad y monitoreo.                             |

---

## 7. Arquitectura Técnica

* **Frontend:** Web Admin, Web User, Mobile App (React + Capacitor).
* **BFF Layer:** separación por cliente (Admin/User/Mobile).
* **Gateway:** API Gateway con WAF, DPoP, PEP y rate limiting.
* **Servicios Core:** gestión de identidad, perfiles, tenancy y cumplimiento.
* **Interoperabilidad:** eventos Kafka + OPA Policy CDN + Redis regional.
* **Almacenamiento:** PostgreSQL (multi-tenant), S3 (documentos), WORM (auditoría).
* **Seguridad:** Zero Trust, TLS 1.3, ES256/EdDSA, logs inmutables.
* **Observabilidad:** OTEL, Grafana, Prometheus, tracing (Tempo/Jaeger).

---

## 8. Flujos Principales

1. **Autenticación y acceso** (Identity + Profiles + Tenancy).
2. **Gestión de Asambleas** (Governance + Streaming).
3. **Reservas y activos** (Reservation + Asset Mgmt).
4. **Gestión financiera y nómina** (Finance + Payroll).
5. **Cumplimiento legal y auditoría** (Compliance + Documents).

---

## 9. Requisitos No Funcionales

| Categoría             | Descripción                                            |
| --------------------- | ------------------------------------------------------ |
| **Seguridad**         | Autenticación fuerte (AAL2/AAL3), DPoP, logs WORM.     |
| **Escalabilidad**     | Horizontal, multi-región, Redis regional.              |
| **Disponibilidad**    | SLO ≥ 99.9% core, ≥ 99.5% operaciones.                 |
| **Legalidad**         | Cumple con GDPR, LGPD, leyes locales (PE, CL, CO, VE). |
| **Observabilidad**    | Métricas, trazas, logs distribuidos y auditable.       |
| **Interoperabilidad** | APIs REST/OIDC/OAuth2 + Kafka CDC + OPA policies.      |

---

## 10. Estrategia de Despliegue

* Despliegue progresivo por dominio:

  1. Core (seguridad)
  2. Governance / Operations (PMV)
  3. Finance / Payroll
  4. Business / Observabilidad
* CI/CD automatizado, validación con pruebas E2E y seguridad antes de producción.

---

## 11. Métricas de Éxito

* `auth_success_rate ≥ 99.5%`
* `revocation_latency_p95 ≤ 60s`
* `dsar_completion ≤ 48h`
* `governance_act_signed ≥ 90%`
* `mobile_usage ≥ 80%`
* `incident_detection_time ≤ 24h`

---

## 12. Riesgos y Supuestos

| Riesgo                                   | Mitigación                                        |
| ---------------------------------------- | ------------------------------------------------- |
| Dependencia cross-region (latencia alta) | Caches locales + replicación Redis                |
| Riesgo jurídico multi-país               | Compliance runtime + validación DSAR              |
| Device binding bypass (móvil)            | Attestation FIDO2 + SafetyNet + bloqueo en root   |
| Phishing vía fallback TOTP               | Vinculación biométrica / autenticador certificado |

---

## 13. Conclusión

SmartEdify consolida la gestión de comunidades bajo una visión de **interoperabilidad segura, cumplimiento jurídico, eficiencia operativa y experiencia móvil**.
El enfoque modular y evolutivo permite escalar de un PMV legal-operativo a una plataforma integral regional.

---
