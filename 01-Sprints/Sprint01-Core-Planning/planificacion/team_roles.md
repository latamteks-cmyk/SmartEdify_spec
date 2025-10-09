# 👥 Roles y Responsabilidades: Fase 1 - Core Backbone

Este documento define la estructura del equipo y las responsabilidades clave para la ejecución de la Fase 1 del proyecto SmartEdify, que abarca la planificación y el desarrollo de los servicios del Core.

---

## 1. Liderazgo y Estrategia

| Rol | Persona (Placeholder) | Responsabilidades Clave |
|---|---|---|
| **CTO (Chief Technology Officer)** | `Asignado` | - Definir y comunicar la visión técnica global.<br>- Aprobar decisiones arquitectónicas críticas (ADRs) y especificaciones de servicio.<br>- Desbloquear impedimentos estratégicos. |
| **Principal Architect** | `Asignado` | - Diseñar y mantener la arquitectura de software global (SAD).<br>- Garantizar la coherencia y las buenas prácticas en todos los servicios.<br>- Liderar la revisión de diseños técnicos. |
| **Security Lead** | `Asignado` | - Definir y supervisar la implementación de las políticas de seguridad.<br>- Aprobar el modelo de amenazas y las estrategias de mitigación.<br>- Liderar las pruebas de seguridad y la respuesta a incidentes. |

---

## 2. Equipo de Ejecución: Core Services Squad ("The Guardians")

Este equipo es responsable de la implementación de los servicios `identity`, `user-profiles` y `tenancy`.

| Rol | Persona (Placeholder) | Responsabilidades Clave en Fase 1 |
|---|---|---|
| **Tech Lead / Engineering Manager** | `Asignado` | - Liderar técnicamente al equipo de desarrollo.<br>- Facilitar las ceremonias de sprint (planning, daily, review).<br>- Asegurar la calidad del código y el cumplimiento de las especificaciones.<br>- Coordinar con otros equipos y stakeholders. |
| **Backend Engineer (Senior)** | `Asignado` (x2) | - Diseñar e implementar las funcionalidades complejas de los servicios core.<br>- Mentorizar a otros ingenieros.<br>- Liderar la implementación de patrones de seguridad y resiliencia. |
| **Backend Engineer (Mid)** | `Asignado` (x3) | - Desarrollar las historias de usuario del backlog.<br>- Escribir pruebas unitarias y de integración.<br>- Participar activamente en las revisiones de código. |
| **DevSecOps Engineer** | `Asignado` | - Implementar y mantener los pipelines de CI/CD.<br>- Configurar la infraestructura como código (Terraform).<br>- Gestionar la configuración de seguridad (KMS, Istio, WAF).<br>- Automatizar los despliegues y el monitoreo. |
| **Quality Engineer (QE)** | `Asignado` | - Diseñar y automatizar el plan de pruebas de integración.<br>- Desarrollar pruebas de rendimiento y carga para los SLOs definidos.<br>- Integrar herramientas de análisis de seguridad estático (SAST) y dinámico (DAST) en el pipeline. |

---

## 3. Stakeholders Clave

| Rol | Persona (Placeholder) | Responsabilidades Clave |
|---|---|---|
| **Product Manager** | `Asignado` | - Ser el dueño del backlog del producto.<br>- Priorizar las funcionalidades en base al valor de negocio.<br>- Aclarar los requisitos funcionales y los criterios de aceptación. |
| **Compliance Officer** | `Asignado` | - Validar que las especificaciones y la implementación cumplan con los requisitos legales y normativos (GDPR, LGPD, etc.).<br>- Proveer los catálogos de roles y políticas por jurisdicción. |
