<div align="center">
  <img src="../branding/Logo_smartedify.jpg" width="200" height="200" alt="Logo SmartEdify" />
  <p><em>Gestión integral de condominios</em></p>
</div>

---
# 📘 Documento de Visión — SmartEdify

**Versión:** 0  
**Fecha:** 2025-10-08  
**Estado:** Aprobado  
**Autor:** Equipo de Producto y Arquitectura SmartEdify  
**Revisión:** CTO / Software Architect / Product Manager  

---

## 🧭 1. Visión General

SmartEdify es una plataforma SaaS multi-tenant diseñada para la gestión integral de comunidades y condominios, con enfoque mobile-first, Zero Trust, cumplimiento normativo transnacional y observabilidad end-to-end.
Su propósito es **transformar la gobernanza, administración, seguridad y prestación de servicios comunes en entornos residenciales y comerciales mediante una solución digital unificada, segura y escalable.**
La visión estratégica se centra en convertir a SmartEdify en el sistema operativo digital para comunidades, garantizando:
Transparencia operativa con trazabilidad inmutable (logs WORM, firma electrónica y actas con respaldo jurídico).
Cumplimiento legal adaptativo mediante un 'Compliance-Service' que valida en tiempo real regulaciones locales e internacionales (GDPR, LGPD, eIDAS, SUNAT, etc.).
Participación comunitaria inteligente, con asambleas digitales híbridas, votaciones seguras y reservas automatizadas.
Experiencia de usuario unificada para propietarios, administradores, trabajadores y auditores, accesible por web y móvil.
Cada tenant puede administrar múltiples condominios, con reglas de cumplimiento y políticas jurídicas independientes.
La arquitectura se basa en microservicios modulares bajo principios de Clean Architecture, API-First y Privacy by Design, priorizando resiliencia, seguridad criptográfica (WebAuthn, DPoP, ES256/EdDSA), eficiencia en costos y despliegue multi-región.
SmartEdify no solo digitaliza la gestión condominial, sino que redefine la gobernanza comunitaria con estándares de seguridad, legalidad y usabilidad comparables a las infraestructuras críticas modernas.
En su madurez plena, cada acción dentro de SmartEdify será auditable, legalmente defendible y medible en términos de confianza, eficiencia y cumplimiento.

---

## 🏗️ 2. Arquitectura Global del Sistema

```mermaid



%% SmartEdify — Arquitectura Global del Sistema (mmd)
%% Layout recomendado: elk
%% Nota: Identity-QR (COSE/JWS, TTL corto, firmado) vs Asset-QR (no cifrado, identificación de activos/áreas)

---
config:
  layout: elk
---

flowchart TB

%% ========= Frontends =========
subgraph FE["Frontend Applications (Mobile-First)"]
  WA["Web Admin :4000"]
  WU["Web User :3000"]
  MA["Mobile App :8081"]
end

%% ========= BFF =========
subgraph BFF["BFF Layer"]
  BFF_A["BFF Admin :4001"]
  BFF_U["BFF User :3007"]
  BFF_M["BFF Mobile :8082"]
end

%% ========= Edge/Gateway =========
subgraph EDGE["Edge Security"]
  WAF["WAF / DDoS Shield"]
end
subgraph GWY["API Gateway :8080"]
  GW["Gateway Service + PEP (DPoP/JWT/JWKS Cache)"]
end

%% ========= Core =========
subgraph CORE["Core Services"]
  IS["Identity Service :3001\nOIDC/OAuth2.1 • WebAuthn • DPoP\nIssuer: https://auth.smartedify.global/{tenant_id}"]
  UPS["User Profiles Service :3002\nAtributos • Grupos • Cargos oficiales"]
  TS["Tenancy Service :3003\nTenants • Condominiums • Jurisdicciones"]
  NS["Notifications Service :3005\nEmail/SMS/Push • Plantillas"]
  DS["Documents Service :3006\nPDF • WORM • Firma electrónica (cuando aplica)"]
end

%% ========= Governance =========
subgraph GOV["Governance Services"]
  GS["Governance Service :3011\nConvocatorias • Quórum • Votos • Actas"]
  CS["Compliance Service :3012\nModo Consulta (runtime) • Boletines (updates)"]
  RS["Reservation Service :3013\nEspacios • Reglas • Tarifas efectivas"]
  SS["Streaming Service :3014\nAsambleas híbridas • Presencia/Marcas de tiempo"]
end

%% ========= Operations =========
subgraph OPS["Operations Services"]
  AMS["Asset Mgmt Service :3010\nActivos • Incidencias • OT • Asset-QR (no cifrado)"]
  FS["Finance Service :3007\nGL • AR/AP • FX • NIC + Fiscal"]
  PS["Payroll Service :3008\nCálculo • Payslips • Exportes regulatorios"]
  HCS["HR Compliance Service :3009\nReglas laborales por país • Elegibilidad"]
  PSS["Physical Security (Futuro) :3004\nACS • Visión por computador"]
end

%% ========= Business =========
subgraph BUS["Business Services"]
  MS["Marketplace Service :3015\nProveedores • Pagos integrados"]
  AS["Analytics Service :3016\nKPIs • Dashboards • Anonimización"]
end

%% ========= Platform / Data / Obs =========
subgraph PLT["Platform Layer"]
  subgraph MSG["Messaging & Streaming"]
    KAFKA["Apache Kafka :9092"]
    SR["Schema Registry"]
    KC["Kafka Connect / CDC"]
    DLQ["Dead Letter Queue"]
    REDIS["Redis (Regional) :6379\nJWKS • DPoP-Nonce • Antireplay • Caches políticas"]
  end
  subgraph DATA["Storage & Crypto"]
    PG[("PostgreSQL :5432\nRLS {tenant, condominium}")]
    S3[("S3 Object Storage")]
    WORM[("S3 Object Lock / WORM\nHash-chain / Evidencias")]
    KMS[("KMS / HSM\nRotación 90d + Rollover 7d")]
    SEC[("Secrets Manager")]
  end
  subgraph POLI["Policy Distribution"]
    POL["Policy CDN (OPA bundles firmados)"]
  end
  subgraph OBS["Observability"]
    OTEL["OTel Collector :4317"]
    TRC["Tracing Backend (Tempo/Jaeger)"]
    LOGS["Logs Backend (OpenSearch/ELK)"]
    PROM["Prometheus :9090"]
    GRAF["Grafana :3000"]
  end
end

%% ========= Wiring: Front → BFF → WAF/GW =========
WA --> BFF_A --> WAF --> GW
WU --> BFF_U --> WAF
MA --> BFF_M --> WAF
WAF --> GW

%% ========= Gateway → Microservicios =========
GW --> IS & UPS & TS & NS & DS & GS & CS & RS & SS & AMS & FS & PS & HCS & MS & AS

%% ========= Core/Data/Messaging Links =========
IS --> PG
IS --> REDIS
IS -.-> KAFKA
IS -.-> OTEL
IS --- KMS
IS --- POL

UPS --> PG
TS --> PG
GS --> PG
FS --> PG
RS --> PG
AMS --> PG

DS --> S3
DS --- WORM

KAFKA --- SR
KAFKA --- DLQ
KC -.-> KAFKA
TS -.-> KC

OTEL --- TRC
OTEL --- LOGS
PROM --- GRAF

GW -.-> PROM
GW --- SEC

%% ========= Governance / Compliance Dynamics =========
CS -. "Boletines: RoleUpdate / TariffSchedule / EligibilityRule" .-> KAFKA
KAFKA -.-> GS
KAFKA -.-> RS
KAFKA -.-> FS
KAFKA -.-> HCS
KAFKA -.-> AMS

%% ========= Identity-QR vs Asset-QR =========
GS -. "Solicita Identity-QR (COSE/JWS, TTL≤300s, kid)" .-> IS
AMS -. "Escanea Asset-QR (no cifrado)" .-> AMS

%% ========= Classes =========
classDef frontend fill:#e1f5fe,stroke:#01579b,color:#000
classDef bff fill:#f3e5f5,stroke:#4a148c,color:#000
classDef edge fill:#fff8e1,stroke:#ef6c00,color:#000
classDef gateway fill:#e8f5e8,stroke:#1b5e20,color:#000
classDef core fill:#fff3e0,stroke:#e65100,color:#000
classDef governance fill:#fce4ec,stroke:#880e4f,color:#000
classDef operations fill:#f1f8e9,stroke:#33691e,color:#000
classDef business fill:#e0f2f1,stroke:#004d40,color:#000
classDef platform fill:#f5f5f5,stroke:#424242,color:#000

class WA,WU,MA frontend
class BFF_A,BFF_U,BFF_M bff
class WAF edge
class GW gateway
class IS,UPS,TS,NS,DS core
class GS,CS,RS,SS governance
class AMS,FS,PS,HCS,PSS operations
class MS,AS business
class KAFKA,SR,KC,DLQ,REDIS,PG,S3,WORM,KMS,SEC,POL,OTEL,TRC,LOGS,PROM,GRAF platform



```

---

## 👥 3. Usuarios y Personas

| Rol | Descripción | Acceso principal |
|-----|--------------|------------------|
| Propietario | Miembro de asamblea con derechos de voto | App móvil / Web User |
| Administrador | Representante legal del condominio | Web Admin |
| Trabajador / Proveedor | Ejecuta servicios o tareas | App móvil |
| Auditor / Legal | Supervisa cumplimiento normativo | Web Admin |
| Sistema externo | Consume APIs autorizadas | OAuth2.1 + mTLS |

---

## 📦 4. Microservicios y Alcance Funcional

### 4.1. Identity Service (3001)
Proveedor central de identidad, autenticación y sesiones con cumplimiento normativo y soporte biométrico.  
Incluye autenticación WebAuthn, DPoP, MFA adaptativo y generación de QR seguros para asambleas.

### 4.2. User Profiles (3002)
Gestión de atributos, roles, relaciones jerárquicas y asociaciones con tenants y unidades residenciales.

### 4.3. Tenancy Service (3003)
Define condominios, unidades, espacios y relación entre tenants y jurisdicciones legales.  
Soporta residencia por país y RLS criptográfico.

### 4.4. Governance Service (3011)
Gestión de asambleas, actas, quórum, votaciones, mandatos y resoluciones con respaldo jurídico.  
Integrado con Compliance para validación legal en tiempo de ejecución.

### 4.5. Compliance Service (3012)
Valida políticas legales, roles vigentes y parámetros normativos.  
Opera en dos modos: **consulta bajo demanda** y **emisión de boletines de actualización** (ej. nombramientos o tarifas).

### 4.6. Reservations Service (3013)
Gestión de reservas de espacios comunes, calendario compartido y cobro automatizado según reglas del Governance Service.

### 4.7. Asset Management Service (3010)
Gestión de activos, incidencias, mantenimiento y trazabilidad mediante QR no encriptados.  
Permite asociar inspecciones y órdenes de trabajo a ubicaciones físicas.

### 4.8. Finance Service (3007)
Contabilidad, flujo de caja, tarifas, cuotas, conciliaciones y reportes fiscales bajo estándares NIC y normativa nacional.

### 4.9. Payroll Service (3008)
Gestión de nóminas, beneficios y obligaciones laborales. Genera recibos de pago y se integra con APIs fiscales (SUNAT, IVSS, etc.).

### 4.10. HR Compliance Service (3009)
Validación de cumplimiento laboral, contratos y normativas por país. Monitoreo continuo de obligaciones legales del empleador.

### 4.11. Notifications Service (3005)
Orquestador de notificaciones push, correo y mensajería interna por tenant.

### 4.12. Documents Service (3006)
Gestión documental con firma electrónica, versionado, cifrado y almacenamiento WORM.  
Firma válida solo en documentos con requerimientos legales.

### 4.13. Streaming Service (3014)
Transmisión en vivo de asambleas híbridas con registro legal de participación y timestamp certificado.

---

## ⚙️ 5. Flujos Principales

### CU-01 — Registro y Activación Delegada
1. Administrador registra usuario en User Profiles.  
2. Se envía enlace de activación vía Notifications.  
3. Identity valida y completa el registro.  
4. Compliance audita consentimiento.

### CU-02 — Autenticación Segura
1. Usuario inicia sesión (WebAuthn o Passkey).  
2. Identity genera JWT + DPoP.  
3. Sesión válida 10 min, asociada al dispositivo.

### CU-03 — Asamblea Digital
1. Governance crea evento con roles firmantes.  
2. Identity genera QR firmado para acceso.  
3. Compliance valida legalidad.  
4. Streaming registra asistencia y votos.

---

## 🛡️ 6. Seguridad y Cumplimiento

| Mecanismo | Descripción |
|------------|-------------|
| TLS 1.3 + mTLS | Canal seguro interservicios. |
| AES-256 at rest | Cifrado en base de datos y backups. |
| DPoP obligatorio | Prevención de replay attacks. |
| JWKS rotación 90d | Claves firmantes actualizadas periódicamente. |
| Logs WORM | Evidencia inmutable de auditoría. |
| GDPR / LGPD / eIDAS | Cumplimiento normativo multinacional. |

---

## 📊 7. Métricas Clave

| Indicador | Objetivo |
|------------|----------|
| Disponibilidad global | ≥ 99.95% |
| Latencia autenticación | ≤ 3 s (P95) |
| Tiempo revocación sesión | ≤ 30 s |
| Cumplimiento auditorías | 100% |
| Adopción WebAuthn | ≥ 80% |

---

## 🗓️ 8. Roadmap Estratégico

```mermaid
gantt
    title Roadmap de Implementación SmartEdify
    dateFormat YYYY-MM-DD
    section Fase 1: Fundacional
    Identity / Profiles / Tenancy  :done, 2025-01-01, 2025-03-31
    section Fase 2: Gobernanza y Cumplimiento
    Governance / Compliance / Documents :active, 2025-04-01, 2025-07-31
    section Fase 3: Operaciones
    Finance / Payroll / Asset Mgmt :2025-08-01, 2025-11-30
    section Fase 4: Expansión
    Marketplace / Analytics / Streaming :2025-12-01, 2026-03-31
```

---

## 🧩 9. Relación entre Microservicios y Dominios

| Dominio | Servicios Asociados |
|----------|--------------------|
| Core | Identity, User Profiles, Tenancy, Notifications, Documents |
| Governance | Governance, Compliance, Reservations, Streaming |
| Operations | Asset Management, Finance, Payroll, HR Compliance |
| Business | Marketplace, Analytics |
| Platform | Kafka, PostgreSQL, Redis, Prometheus, Grafana, S3 |

---

## 🧾 10. Historial de Cambios

| Versión | Fecha | Descripción |
|----------|--------|-------------|
| 1.0 | 2025-08-01 | Versión inicial del documento de visión. |
| 1.1 | 2025-10-08 | Versión revisada, ampliada y actualizada según arquitectura integral. |

