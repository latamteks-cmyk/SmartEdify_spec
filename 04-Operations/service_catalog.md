# SmartEdify Service Catalog

## Overview
This document provides a comprehensive catalog of all SmartEdify services, their purposes, dependencies, and operational characteristics.

## Service Classification

### Core Services
These services provide fundamental platform capabilities:

#### Identity Service (3001)
- **Purpose**: Central authority for identity management with WebAuthn, DPoP, and WORM logging
- **Port**: 3001
- **Dependencies**: PostgreSQL, Redis, Kafka, KMS
- **SLOs**: 
  - Availability: 99.95%
  - Response Time P95: ≤ 2s
  - Authentication Success Rate: ≥99.5%
- **Key Metrics**: auth_requests_total, session_validations_total, dpop_tokens_issued
- **Health Check**: `/v1/health`
- **Security**: OIDC 2.1, WebAuthn, DPoP, JWKS

#### User Profiles Service (3002)
- **Purpose**: Manages user roles, relationships, and organizational memberships
- **Port**: 3002
- **Dependencies**: PostgreSQL, Identity Service, Tenancy Service
- **SLOs**:
  - Availability: 99.9%
  - Response Time P95: ≤ 1s
  - Data Consistency: RLS enforced
- **Key Metrics**: profiles_read_total, consent_changes_total, role_assignments
- **Health Check**: `/v1/health`
- **Security**: RLS, PII encryption

#### Tenancy Service (3003)
- **Purpose**: Tenant and condominium hierarchy management with jurisdiction mapping
- **Port**: 3003
- **Dependencies**: PostgreSQL, Kafka
- **SLOs**:
  - Availability: 99.95%
  - Response Time P95: ≤ 1.5s
  - Data Isolation: 100% compliance
- **Key Metrics**: tenants_created_total, jurisdictions_mapped_total, isolation_violations
- **Health Check**: `/v1/health`
- **Security**: RLS, jurisdiction validation

#### Notifications Service (3005)
- **Purpose**: Orchestration of multi-channel notifications (email, SMS, push)
- **Port**: 3005
- **Dependencies**: PostgreSQL, Message Queue
- **SLOs**:
  - Availability: 99.9%
  - Delivery Rate: ≥95%
  - Response Time P95: ≤ 0.5s
- **Key Metrics**: notifications_sent_total, delivery_success_rate, channel_distribution
- **Health Check**: `/v1/health`
- **Security**: Tenant isolation, content encryption

#### Documents Service (3006)
- **Purpose**: Document management with advanced electronic signatures and WORM storage
- **Port**: 3006
- **Dependencies**: S3, WORM storage, KMS, User Profiles
- **SLOs**:
  - Availability: 99.9%
  - Signature Validity: 100%
  - Storage Durability: 99.999999999%
- **Key Metrics**: documents_signed_total, worm_verification_success, signature_validation_total
- **Health Check**: `/v1/health`
- **Security**: ES256/EdDSA, WORM, PII encryption

### Governance Services
These services enable digital governance capabilities:

#### Governance Service (3011)
- **Purpose**: Assembly orchestration, voting, and legal document generation
- **Port**: 3011
- **Dependencies**: PostgreSQL, Identity Service, Compliance Service, Documents Service
- **SLOs**:
  - Availability: 99.9%
  - Assembly Creation Time: ≤ 5s
  - Vote Processing Time: ≤ 2s
- **Key Metrics**: assemblies_created_total, votes_cast_total, legal_qr_generated
- **Health Check**: `/v1/health`
- **Security**: Attestation validation, WORM logging

#### Compliance Service (3012)
- **Purpose**: Real-time policy evaluation and regulatory compliance validation
- **Port**: 3012
- **Dependencies**: PostgreSQL, Redis, Kafka, Policy CDN
- **SLOs**:
  - Availability: 99.9%
  - Policy Evaluation Time: ≤ 2s
  - Cache Hit Rate: ≥90%
- **Key Metrics**: policy_evaluations_total, violations_detected_total, cache_hit_rate
- **Health Check**: `/v1/health`
- **Security**: Signed OPA bundles, emergency mode

#### Reservations Service (3013)
- **Purpose**: Reservation management for common spaces and resources
- **Port**: 3013
- **Dependencies**: PostgreSQL, Compliance Service, Notifications Service, Finance Service
- **SLOs**:
  - Availability: 99.9%
  - Reservation Processing Time: ≤ 1s
  - Eligibility Check Time: ≤ 0.5s
- **Key Metrics**: reservations_made_total, eligibility_checks_total, checkins_total
- **Health Check**: `/v1/health`
- **Security**: Tenant isolation, eligibility validation

#### Streaming Service (3014)
- **Purpose**: Live streaming for hybrid assemblies with timestamp certification
- **Port**: 3014
- **Dependencies**: Streaming infrastructure, Timestamp service
- **SLOs**:
  - Availability: 99.5%
  - Streaming Uptime: ≥99%
  - Timestamp Accuracy: ±1 second
- **Key Metrics**: streaming_sessions_total, participants_total, timestamp_certifications
- **Health Check**: `/v1/health`
- **Security**: Stream encryption, participant authentication

### Operations Services
These services support operational functions:

#### Asset Management Service (3010)
- **Purpose**: Asset tracking, incident management, and work order processing
- **Port**: 3010
- **Dependencies**: PostgreSQL, Kafka, Tenancy Service
- **SLOs**:
  - Availability: 99.9%
  - Asset Record Accuracy: 99.9%
  - Incident Processing Time: ≤ 30s
- **Key Metrics**: assets_tracked_total, incidents_reported_total, work_orders_created
- **Health Check**: `/v1/health`
- **Security**: Tenant isolation, asset QR validation

#### Finance Service (3007)
- **Purpose**: Financial management, GL, AR/AP, FX, and regulatory reporting
- **Port**: 3007
- **Dependencies**: PostgreSQL, Regulatory APIs, Tenancy Service
- **SLOs**:
  - Availability: 99.9%
  - Transaction Processing Time: ≤ 2s
  - Report Generation Time: ≤ 30s
- **Key Metrics**: transactions_processed_total, regulatory_exports_total, currency_conversions
- **Health Check**: `/v1/health`
- **Security**: Financial data encryption, regulatory compliance

#### Payroll Service (3008)
- **Purpose**: Payroll calculation, payslip generation, and regulatory exports
- **Port**: 3008
- **Dependencies**: PostgreSQL, Regulatory APIs, HR Compliance Service
- **SLOs**:
  - Availability: 99.9%
  - Payroll Calculation Time: ≤ 60s per employee
  - Payslip Generation Time: ≤ 10s
- **Key Metrics**: payroll_calculations_total, payslips_generated, tax_calculations
- **Health Check**: `/v1/health`
- **Security**: PII encryption, financial data protection

#### HR Compliance Service (3009)
- **Purpose**: Labor law compliance validation and regulatory monitoring
- **Port**: 3009
- **Dependencies**: PostgreSQL, Regulatory APIs
- **SLOs**:
  - Availability: 99.9%
  - Compliance Check Time: ≤ 5s
  - Regulatory Update Processing: ≤ 1 hour
- **Key Metrics**: compliance_checks_total, violations_detected, regulatory_updates_processed
- **Health Check**: `/v1/health`
- **Security**: PII encryption, employment data protection

### Business Services
These services enable business functionality:

#### Marketplace Service (3015)
- **Purpose**: Service provider integration and digital contracting
- **Port**: 3015
- **Dependencies**: PostgreSQL, Payment Gateway, Notifications Service
- **SLOs**:
  - Availability: 99.5%
  - Service Booking Time: ≤ 3s
  - Payment Processing Time: ≤ 5s
- **Key Metrics**: providers_registered_total, services_booked_total, payments_processed
- **Health Check**: `/v1/health`
- **Security**: Payment data protection, provider verification

#### Analytics Service (3016)
- **Purpose**: KPI calculation, dashboard generation, and data anonymization
- **Port**: 3016
- **Dependencies**: PostgreSQL, Data Warehouse
- **SLOs**:
  - Availability: 99.5%
  - Query Response Time: ≤ 10s
  - Dashboard Load Time: ≤ 5s
- **Key Metrics**: queries_executed_total, dashboards_created_total, kpi_calculations
- **Health Check**: `/v1/health`
- **Security**: Data anonymization, access controls

## Service Dependencies

### Critical Path Dependencies
1. Identity Service → All other services (authentication)
2. Tenancy Service → All tenant-specific services (isolation)
3. Compliance Service → Governance, Reservations (policy validation)
4. Notifications Service → All user-facing services (communication)

### Caching Dependencies
- Redis: Identity Service (JWKS, DPoP nonces), Compliance Service (policies)
- Regional Cache: JWKS, Policy CDN
- Local Memory: Session context, QR pre-compute

### Data Dependencies
- PostgreSQL: All services except Streaming
- S3: Documents Service, File storage
- WORM: Legal documents, audit logs
- Kafka: Event-driven communication between services

## Service Resilience

### Circuit Breakers
- Compliance Service: 3 failures → open → 30s timeout → half-open
- Identity Service: 5 failures → open → 60s timeout → half-open
- Tenancy Service: 2 failures → open → 15s timeout → half-open

### Emergency Modes
- Compliance Service: Cache policy fallback for non-critical ops
- Governance Service: Post-validation for critical ops during compliance outage
- Identity Service: Emergency authentication methods if primary fails

### Backup Strategies
- Database: Point-in-time recovery with 15-minute RPO
- Configuration: Versioned in Git with automated backup
- Secrets: Encrypted backup with multi-region replication
- Documents: Cross-region replication with WORM compliance

## Scaling Characteristics

### Load Patterns
- Identity Service: Spiky during login hours, consistent otherwise
- Governance Service: High during assembly periods
- Notifications Service: Batch processing during low-traffic hours
- Analytics Service: Aggregated during off-peak hours

### Auto-scaling Triggers
- CPU utilization > 75% for 5 minutes
- Memory utilization > 80% for 5 minutes
- Queue depth > 1000 items for 2 minutes
- Response time P95 > 2s for 5 minutes

### Capacity Planning
- Service capacity for 3x baseline load
- Database sizing for 2x data growth in 12 months
- Network bandwidth for 5x current usage
- Storage with automatic scaling

## Operational Procedures

### Deployment
- Blue-green deployment for all services
- Canary releases for critical services
- Automated rollback on health check failure
- Zero-downtime migrations

### Backup and Recovery
- Daily database backups with 30-day retention
- Transaction log shipping for point-in-time recovery
- Automated backup verification
- Monthly disaster recovery tests

### Monitoring
- Health check every 30 seconds
- Metrics collection every 15 seconds
- Log aggregation and analysis
- Custom business metric tracking

### Incident Response
- P0 incidents: Response within 15 minutes
- P1 incidents: Response within 1 hour
- P2 incidents: Response within 4 hours
- Post-incident reviews for all P1+ incidents