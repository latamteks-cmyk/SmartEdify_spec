# ⚠️ Matriz de Riesgos: Fase 1 – Core Backbone (Actualizada)

Este documento identifica los riesgos más significativos para la planificación y ejecución de la Fase 1 (Core Backbone) y establece estrategias de mitigación alineadas con las acciones del CTO y el backlog técnico.

| ID | Riesgo | Impacto | Probabilidad | Nivel de Riesgo | Estrategia de Mitigación |
|----|--------|---------|--------------|------------------|----------------------------|
| **R-01** | **Inconsistencia `kid` ↔ JWKS**<br>Los tokens emitidos contienen un `kid` no presente en el JWKS activo, causando fallos de validación en servicios consumidores. | Crítico | Media | Alto | • Implementar **CI check automático** (H-06) que valide que todo token emitido tiene `kid` en JWKS.<br>• Alertar en tiempo real si `kid_mismatch_detected_total > 0`.<br>• Usar **rollover de 7 días** y TTL ≤1h en caché JWKS. |
| **R-02** | **Complejidad o latencia en anti-replay DPoP**<br>El mecanismo de nonce global introduce cuellos de botella o falla bajo alta carga (≥10k TPS). | Alto | Media | Alto | • Implementar **Redis regional con TTL ≤60s** y operación `SETNX` (H-04).<br>• **Evitar sincronización cross-región** en Fase 1.<br>• Ejecutar **perfil de carga sintético** (10k TPS) como parte de QA. |
| **R-03** | **KMS/HSM indisponible en CI/CD**<br>El pipeline de integración se bloquea por dependencia de infraestructura criptográfica externa. | Alto | Alta | Alto | • Implementar **modo mock KMS en CI** (H-05) con claves efímeras.<br>• Usar **feature flags** para habilitar KMS real solo en staging/prod.<br>• Documentar en `team_roles.md` al **Security Champion** como responsable. |
| **R-04** | **Fallo silencioso del modo fail-closed en Compliance**<br>Ante caída del `Compliance Service`, el sistema no deniega operaciones críticas, generando decisiones legalmente inválidas. | Crítico | Baja | Alto | • Ejecutar **chaos test específico** (H-02): matar pod Compliance → verificar 403 + log WORM.<br>• Exponer métrica `compliance_fail_closed_trigger_count`.<br>• Validar en PR que el circuit breaker está configurado (3 fallos → open → 30s timeout). |
| **R-05** | **Baja adopción o fallos de UX con Passkey en móviles**<br>Los usuarios no completan el registro/login por problemas de compatibilidad o flujo confuso. | Medio | Alta | Medio | • Realizar **pruebas de usabilidad con usuarios reales** en iOS/Android (H-06).<br>• Registrar tasas de éxito y tiempos por plataforma.<br>• Ofrecer **flujo de recuperación claro** (TOTP como fallback temporal). |
| **R-06** | **Falta de trazabilidad por ausencia de eventos de Identity**<br>No se registran eventos clave (`AuthSuccess`, `SessionRevoked`), impidiendo auditoría forense y correlación. | Alto | Media | Alto | • Publicar eventos en **Schema Registry** con contratos versionados (H-07).<br>• Validar en CI que los esquemas están registrados.<br>• Incluir `tenant_id` y `user_role` en atributos del evento. |
| **R-07** | **Interoperabilidad fallida con JWKS federados**<br>El sistema no consume correctamente JWKS de IdPs externos o durante rotación forzada. | Alto | Media | Alto | • Desarrollar **suite de pruebas de interoperabilidad** (H-01) con JWKS simulado.<br>• Validar rollover de 7 días y caché TTL ≤5m.<br>• Exponer métrica `jwks_interop_rollover_success_rate`. |
| **R-08** | **Latencia inaceptable en flujos WebAuthn**<br>El P95 de registro/assertion supera los 3s, afectando la experiencia mobile-first. | Medio | Media | Medio | • Medir y reportar `webauthn_registration_latency_p95` y `webauthn_assertion_latency_p95` por plataforma (H-03).<br>• Establecer SLOs diferenciados por iOS/Android/Web.<br>• Optimizar con **pre-generación de claves** y caché local. |
| **R-09** | **Gestión incorrecta de PII en User Profiles**<br>Atributos sensibles (DNI, etc.) se almacenan en texto claro o sin cifrado por tenant. | Crítico | Baja | Alto | • Aplicar **cifrado con clave KMS por tenant** (UP-10).<br>• Revisar código por **Security Champion** en cada PR que toque PII.<br>• Validar con escáneres estáticos (Snyk, SonarQube). |
| **R-10** | **Propagación incompleta de contexto de tenant**<br>El `tenant_id` no se inyecta en trazas/logs, impidiendo observabilidad por tenant. | Alto | Media | Alto | • Implementar **interceptor centralizado** que enriquezca contexto OTel (PLT-03).<br>• Validar en CI que todos los spans incluyen `tenant_id` y `condominium_id`.<br>• Incluir en **dashboard de métricas** por tenant. |

---

## ✅ Notas de Gestión

- **Riesgos R-01 a R-08** están directamente vinculados a las **acciones H-01 a H-07** del CTO Review.
- **R-09 y R-10** derivan de las **historias técnicas faltantes** identificadas en el análisis del backlog.
- Todos los riesgos de **nivel Alto** deben tener al menos **una métrica asociada** y un **owner explícito** (Tech Lead, Security Champion o QA Lead).
- Esta matriz debe actualizarse al inicio de cada sprint y revisarse en la retrospectiva.
