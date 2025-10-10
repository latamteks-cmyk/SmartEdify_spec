# 🧩 Feature Flags — identity-service

**Última actualización**: 2025-10-10

Este documento describe los feature flags activos en el servicio de identidad (`identity-service`) y su rol en el comportamiento dinámico del sistema.

| Flag | Descripción | Estado | Entorno | Responsable |
|------|-------------|--------|---------|-------------|
| `enable_passkey` | Habilita autenticación con WebAuthn/Passkeys (AAL3) | `activo` | `staging, production` | Tech Lead - Identity |
| `use_compliance_gate` | Activa validación legal en tiempo de ejecución vía compliance-service | `activo` | `staging, production` | Tech Lead - Compliance |
| `mock_kms_mode` | Usa claves efímeras en CI/CD para pruebas sin KMS real | `activo` | `ci` | Security Champion |
| `enable_qr_contextual` | Permite emisión de QR firmados para eventos jurídicos | `activo` | `staging, production` | Tech Lead - Governance |
| `enable_token_rotation` | Activa rotación obligatoria de refresh tokens | `activo` | `staging, production` | Tech Lead - Identity |
| `enable_dpop_validation` | Habilita validación completa de DPoP con anti-replay | `activo` | `staging, production` | Tech Lead - Identity |
