# 🔐 Seguridad en Frontend — Identity Service

Este documento define las prácticas de seguridad obligatorias para todos los frontends que interactúan con el `identity-service` (Web, Mobile, BFF), alineadas con los criterios de aceptación, matriz de riesgos y especificación técnica v3.6.

---

## 1. Almacenamiento Seguro de Tokens

- ❌ **Prohibido** almacenar `access_token` o `refresh_token` en `localStorage`, `sessionStorage` o variables JS globales.
- ✅ **Recomendado**:
  - Uso de **cookies HTTPOnly + Secure** para `access_token` (con `SameSite=Lax` o `Strict`).
  - Uso de **BFF (Backend-for-Frontend)** para encapsular tokens y evitar exposición en cliente.
- 🔍 Validación automatizada:
  - Prueba: `frontend-token-storage.spec.ts`
  - Métrica: `storage_validation_passed` en tabla `sessions`

---

## 2. Validación de Feature Flags

- Todos los frontends deben sincronizar los flags activos del tenant antes de renderizar flujos sensibles.
- Endpoint: `GET /feature-flags`
- Flags críticos:
  - `enable_passkey`
  - `mfa_required`
  - `use_compliance_gate`
- Validaciones:
  - Fallback por defecto si el flag no está presente.
  - Métrica: `feature_flag_mismatch_detected_total`

---

## 3. Protección contra XSS y CSRF

- ✅ Escapado de contenido dinámico (`innerHTML`, `dangerouslySetInnerHTML`) con sanitización.
- ✅ Uso de `Content-Security-Policy` (CSP) con `script-src 'self'` y `object-src 'none'`.
- ✅ Cookies con `SameSite=Strict` para operaciones sensibles.
- ✅ Tokens CSRF en formularios si no se usa BFF.

---

## 4. Seguridad en WebAuthn y QR

- Validar que el navegador soporte WebAuthn antes de iniciar flujo.
- Verificar `signCount` y `origin` en credenciales.
- QR:
  - TTL ≤ 300s
  - Validación de firma y `jti` anti-replay

---

## 5. Pruebas Automatizadas de Seguridad

- Pruebas obligatorias en CI/CD:
  - `frontend-token-storage.spec.ts`
  - `feature-flag-sync.spec.ts`
  - `xss-protection.spec.ts`
  - `qr-validation.spec.ts`
- Herramientas:
  - OWASP ZAP (DAST)
  - Snyk (SCA)
  - ESLint + eslint-plugin-security

---

## 6. Auditoría y Trazabilidad

- Todos los eventos de login, logout, error de validación y lectura de QR deben registrarse en Kafka (`frontend.events`) con:
  - `user_id`, `tenant_id`, `auth_method`, `device_id`
- Logs en formato JSON, sin PII.

---

## 7. Owner y Revisión

- Owner: **Frontend Tech Lead**
- Revisión: Cada sprint en conjunto con QA y Security Champion
- Última actualización: 2025-10-10

****
