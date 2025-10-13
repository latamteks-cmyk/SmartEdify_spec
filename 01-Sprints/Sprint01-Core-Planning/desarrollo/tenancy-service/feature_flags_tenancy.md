
# 🚩 Feature Flags — Tenancy Service (3003)

## 📌 Propósito
Este documento define las banderas de características (`feature_flags`) utilizadas por el servicio `tenancy-service` para habilitar o deshabilitar funcionalidades específicas por `tenant`, `condominium` o `jurisdicción`, siguiendo las buenas prácticas de arquitectura modular, despliegue progresivo y cumplimiento normativo adaptativo.

---

## 🧩 Modelo de Datos

```sql
CREATE TABLE feature_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    condominium_id UUID REFERENCES condominiums(id),
    feature_name TEXT NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT false,
    configuration JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (tenant_id, condominium_id, feature_name)
);
```

---

## 🧪 Ejemplos de Flags

| Flag | Descripción | Scope | Default |
|------|-------------|-------|---------|
| `enable_condo_timezone_override` | Permite definir zona horaria específica por condominio | `condominium_id` | `false` |
| `allow_subunit_reassignment` | Permite reasignar subunidades entre unidades | `tenant_id` | `false` |
| `jurisdiction_PE_address_validation_v2` | Activa validación avanzada de direcciones en Perú | `jurisdiction` | `true` |
| `unit_type_parking_enabled` | Habilita tipo de unidad 'PARKING' | `tenant_id` | `true` |
| `building_floors_max_override` | Permite override de número máximo de pisos | `condominium_id` | `false` |

---

## 🔐 Seguridad y Gobernanza

- Todas las operaciones sobre `feature_flags` están protegidas por RLS (`tenant_id`).
- Solo usuarios con rol `TENANT_ADMIN` o `COMPLIANCE_OFFICER` pueden modificar flags.
- Cambios se registran en `audit_log` con firma digital y hash-chain.

---

## 🔄 Integración

- **Redis Cache**: Flags se cachean por `tenant_id` y `condominium_id` con TTL de 5 minutos.
- **Kafka Events**: Cambios en flags publican eventos `FeatureFlagUpdated`, `FeatureFlagDisabled`, `FeatureFlagEnabled`.
- **Compliance Service**: Algunas flags son activadas automáticamente por boletines normativos (`BulletinPublished`).

---

## 📅 Última Actualización
2025-10-13
