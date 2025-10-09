# System Scope Document - SmartEdify Platform

## Document Information
| Field | Value |
|-------|-------|
| **Document ID** | SCOPE-SYS-SMARTEDIFY-1.2 |
| **Project** | SmartEdify |
| **Version** | 1.2 |
| **Status** | Approved |
| **Authors** | Product Team, Architecture Team |
| **Reviewers** | CTO / Software Architect / Product Manager |
| **Created** | 2025-09-01 |
| **Last Updated** | 2025-10-08 |

---

## 1. Document Overview

### 1.1 Purpose
This document defines the comprehensive scope of the SmartEdify platform, outlining all components, boundaries, and interfaces that constitute the complete system.

### 1.2 Scope of This Document
This document covers the entire SmartEdify ecosystem including all services, frontend applications, infrastructure components, and third-party integrations as defined in the vision document.

### 1.3 Definitions and Acronyms
- **Tenant**: An organization (e.g., property management company) that manages multiple condominiums
- **Condominium**: A residential or commercial property managed as a single entity
- **Unit**: Individual apartment, office, or property within a condominium
- **WORM**: Write Once, Read Many - for immutable audit logs
- **DPoP**: Demonstration of Proof-of-Possession - for secure token usage
- **RLS**: Row Level Security - for data isolation
- **PBAC**: Policy-Based Access Control
- **Data Residency**: The practice of storing data in a specific geographic location or region to comply with local regulations and legal requirements
- **Degraded Mode**: A system operational state where certain non-critical functions are disabled to maintain core functionality during service unavailability
- **Identity-QR**: Cryptographically signed QR codes for legal assembly access with temporal validity (TTL ≤ 300s)
- **Asset-QR**: Simple identifiers without encryption for physical asset identification and tracking
- **Policy Version Skew**: Difference between latest policy version and cached version in distributed systems

---

## 2. System Overview

### 2.1 System Purpose
SmartEdify is a SaaS platform designed for comprehensive community and condominium management, featuring:
- Digital governance with legal validity
- Real-time compliance with transnational regulations
- Mobile-first experience
- Zero Trust security architecture
- End-to-end observability

### 2.2 System Boundaries
**In Scope:**
- Identity and access management system
- Multi-tenant architecture with condominium support
- Governance and assembly management
- Financial and payroll systems
- Asset management and maintenance
- Reservation systems for common spaces
- Notification and communication platforms
- Analytics and reporting
- Marketplace for service providers
- Compliance validation and monitoring

**Out of Scope:**
- Physical security hardware (cameras, access control readers)
- External utility management systems (unless integrated via API)
- Legal advisory services (system supports legal processes but doesn't provide legal advice)

---

## 3. Functional Scope

### 3.1 Core Functional Areas

#### 3.1.1 Identity and Access Management
- Strong authentication (WebAuthn/Passkeys)
- Session management with DPoP
- User provisioning and deprovisioning
- Role and permission management
- Multi-factor authentication
- OIDC discovery per tenant: `https://auth.smartedify.global/{tenant_id}/.well-known/openid-configuration`
- JWKS rotation: 90-day rotation with 7-day rollover window
- JWKS cache: TTL ≤1 hour with background refresh
- DPoP validation requirements: `htu`, `htm`, `jti`, `ath` claims validation
- Distributed anti-replay protection using client_jkt cache
- Device attestation: FIDO2 for WebAuthn, SafetyNet/DeviceCheck for mobile AAL3
- Blocking of root/jailbroken devices for sensitive operations

#### 3.1.2 Tenant and Condominium Management
- Tenant onboarding and configuration
- Condominium structure definition
- Multi-jurisdiction support
- Billing and subscription management
- Unit and space definition

#### 3.1.3 Digital Governance
- Assembly planning and execution
- Voting and polling systems
- Meeting minutes and act generation
- Official document signing
- Hybrid (in-person/remote) assembly support
- Identity-QR generation (COSE/JWS signed, TTL≤300s) for legal assembly access
- Asset-QR generation (simple identifiers, no encryption) for physical asset tracking
- Google Meet integration as transport mechanism only, not source of truth
- Attendance/timestamp registration through Governance/Streaming services, not Meet
- Quorum verification through Identity-QR access control

#### 3.1.4 Financial Management
- Fee and assessment collection
- Accounts receivable and payable
- General ledger management
- Multi-currency support
- Financial reporting and compliance

#### 3.1.5 Asset and Maintenance Management
- Asset cataloging and tracking
- Work order management
- Preventive maintenance scheduling
- Vendor management
- Inspection tracking

#### 3.1.6 Reservation Systems
- Common area booking
- Real-time availability checking
- Rule-based eligibility validation
- Calendar integration
- Payment processing for reservations

#### 3.1.7 Communications and Notifications
- Multi-channel messaging (email, SMS, push)
- Document sharing
- Announcement broadcasting
- Task assignment and tracking
- Automated workflow notifications

### 3.2 User Types and Functionalities
- **Tenant Administrators**: Manage multiple condominiums, global policies
- **Condominium Managers**: Manage individual condominium operations
- **Board Members**: Participate in governance, sign documents
- **Residents**: Participate in assemblies, make reservations, pay fees
- **Service Providers**: Provide maintenance and other services
- **Auditors**: Review compliance and financial records
- **Support Staff**: Provide customer support with audit-trail

---

## 4. Non-Functional Scope

### 4.1 Performance Requirements
- **Global Availability**: ≥ 99.95% uptime
- **Authentication Response Time**: ≤ 3 seconds (P95)
- **Session Revocation Time**: ≤ 30 seconds
- **Audit Compliance**: 100%
- **WebAuthn Adoption**: ≥ 80%

### 4.2 Security Requirements
- **Zero Trust Architecture**: No implicit trust model
- **Data Encryption**: AES-256 at rest, TLS 1.3 in transit
- **DPoP Implementation**: Mandatory for token replay protection
- **WORM Compliance**: Immutable legal evidence storage
- **Regulatory Compliance**: GDPR, LGPD, eIDAS, local regulations

### 4.3 Scalability Requirements
- **Multi-Tenancy Support**: Thousands of tenants with multiple condominiums each
- **Horizontal Scaling**: Services must scale independently
- **Data Partitioning**: By tenant and condominium
- **Geographic Distribution**: Multi-region deployment capability

### 4.4 Reliability Requirements
- **Disaster Recovery**: RTO ≤ 4 hours, RPO ≤ 1 hour
- **Rollback Capability**: Safe deployment with quick rollback
- **Circuit Breakers**: Protection against cascading failures
- **Monitoring**: 24/7 system health monitoring

---

## 5. System Architecture Overview

### 5.1 High-Level Architecture
The system follows a microservices architecture with the following main components:

#### Frontend Layer
- Web Admin Interface (Port 4000)
- Web User Interface (Port 3000)
- Mobile Application (Port 8081)

#### API Layer
- API Gateway (Port 8080)
- Backend for Frontend (BFF) layer (Ports 4001, 4002, 8082)

#### Service Layer
- **Core Services**: Identity (3001), User Profiles (3002), Tenancy (3003), etc.
- **Governance Services**: Governance (3011), Compliance (3012), Reservations (3013), etc.
- **Operations Services**: Asset Mgmt (3010), Finance (3007), Payroll (3008), etc.
- **Business Services**: Marketplace (3015), Analytics (3016)

#### Data Layer
- PostgreSQL with Row Level Security
- Redis caching layers
- S3 object storage
- WORM storage for legal evidence

#### Platform Layer
- Apache Kafka for messaging
- Schema Registry
- Monitoring and observability tools

### 5.2 Infrastructure Components
- **Edge Security**: WAF and DDoS protection
- **API Gateway**: Authentication, rate limiting, routing
- **Caching**: Multiple layers for performance
- **Monitoring**: Complete observability stack
- **Security**: HSM, Secrets Manager, PKI

---

## 6. Integration Scope

### 6.1 External Integrations
- **Regulatory APIs**: 
  - SUNAT (Peru): Tax and fiscal compliance
  - DIAN (Colombia): Tax and customs regulations
  - IVSS (Venezuela): Social security and labor regulations
  - SII (Chile): Tax and customs compliance
  - Other country-specific fiscal systems
- **Payment Processors**: For financial transactions
- **Communication Services**: Email, SMS, push notification providers
- **Identity Providers**: For B2B integrations (Google, Microsoft, etc.)
- **Security Systems**: Physical access control (future)
- **Video Conferencing**: Google Meet integration for hybrid assemblies (transport only, not source of truth)

### 6.2 Internal Service Integrations
- **Event-Driven Architecture**: All services communicate via Kafka
- **Synchronous APIs**: For real-time operations requiring immediate response
- **Data Consistency**: Eventual consistency where appropriate
- **Cross-Service Workflows**: Coordinated operations across services

---

## 7. Cross-Cutting Concerns

### 7.1 Cache Strategy
- **JWKS Cache**: Regional Redis clusters with ≤1 hour TTL, 7-day rollover window, and webhook invalidation
- **Compliance Policy Cache**: Regional Redis with 5-minute TTL, event-driven updates via Kafka
- **Tenant Context Cache**: Local memory with 10-minute TTL and distributed Redis sharing
- **DPoP Anti-Replay Cache**: Distributed cache with client_jkt for replay protection
- **QR Pre-compute Cache**: Regional Redis with 24-hour TTL and event cancellation invalidation

### 7.2 Policy Delivery
- **CDN Distribution**: Regional CDN for OPA policy bundle distribution with geographic proximity routing
- **Client Validation**: Cryptographic verification of signed bundles before application
- **Staged Rollout**: Gradual policy deployment with A/B testing capabilities
- **Policy Pinning**: Cryptographic verification with rollback protection
- **TTL Management**: 5-minute cache with event-driven updates
- **Bundle Invalidation**: Event-driven invalidation via Kafka for expired bundles
- **Regional Failover**: Automatic failover between regional CDNs on failure
- **Bundle Integrity**: Hash verification and digital signature validation (Ed25519/ES256) for all bundles

### 8.1 Data Scope

### 8.1.1 Data Entities
- **User Data**: Profiles, credentials, preferences
- **Tenant Data**: Organization information, settings
- **Condominium Data**: Property details, regulations
- **Financial Data**: Transactions, accounts, reports
- **Governance Data**: Assemblies, votes, actas
- **Asset Data**: Equipment, maintenance records
- **Audit Data**: Complete immutable logs

### 8.2 Data Flow Patterns
- **Event Sourcing**: Main data flow through Kafka events
- **CQRS**: Separate read and write models where appropriate
- **Data Replication**: For availability and performance
- **Backup and Archival**: Automated data lifecycle management

### 8.3 Data Governance
- **Privacy by Design**: Implementation of privacy from the ground up
- **Consent Management**: User consent tracking and management
- **Data Minimization**: Only necessary data is collected and stored
- **Right to Erasure**: Automated data deletion when required
- **Data Portability**: User data export capabilities

---

## 9. Compliance Scope

### 9.1 Regulatory Compliance
- **GDPR**: For EU-based tenants and users
- **LGPD**: For Brazilian tenants and users  
- **eIDAS**: For electronic identification in EU
- **Local Regulations**: Country-specific requirements
- **Industry Standards**: ISO 27001, SOC 2, etc.

### 9.2 Compliance Mechanisms
- **Real-time Validation**: Compliance Service validates operations
- **Policy Engine**: Dynamic policy distribution and enforcement
- **Audit Trail**: Complete WORM-based audit logs
- **Digital Signatures**: ES256/EdDSA for legal documents when applicable with official position verification
- **Data Residency**: Data stored in appropriate jurisdictions with `data_residency={region}` metadata
- **OPA Bundle Signing**: Ed25519/ES256 for policy bundle signing with CDN distribution
- **Policy Pinning**: Cryptographic verification with rollback protection
- **Fail-Closed Policy**: Compliance decisions default to deny on validation failure
- **Compliance Degraded Mode**: SLA ≤24h recovery with `compliance_mode=degraded` markers
- **Irreversible Operation Blocks**: Preventing critical operations during compliance service unavailability
- **DSAR Support**: Data Subject Access Request processing ≤72h
- **Policy Version Skew Monitoring**: Tracking difference between latest and cached policy versions

---

## 10. Security Scope

### 10.1 Authentication and Authorization
- **WebAuthn/Passkeys**: Strong authentication for all users
- **DPoP**: Proof-of-Possession tokens to prevent replay
- **PBAC**: Policy-Based Access Control using OPA
- **RLS**: Row Level Security for data isolation
- **MFA**: Multi-factor authentication for privileged accounts
- **OIDC Discovery**: Tenant-specific endpoints at `https://auth.smartedify.global/{tenant_id}/.well-known/openid-configuration`
- **DPoP Validation**: Requiring `htu`, `htm`, `jti`, `ath` claims validation
- **Distributed Anti-Replay**: Client_jkt cache for DPoP replay protection
- **FIDO2 Attestation**: For AAL3 authentication requirements
- **SafetyNet/DeviceCheck**: For mobile device integrity validation
- **Root/Jailbreak Detection**: Blocking of compromised devices for sensitive operations

### 10.2 Data Protection
- **Encryption at Rest**: AES-256 for all stored data
- **Encryption in Transit**: TLS 1.3 for all communications
- **Key Management**: HSM with 90-day rotation and 7-day rollover window
- **Key Hierarchy**: Region → Tenant → kid hierarchy with proper key lifecycle management
- **PII Protection**: Special handling for personally identifiable information
- **WORM Storage**: Immutable storage for legal evidence
- **Digital Signatures**: ES256/EdDSA for legal documents when applicable
- **Legal Signature Requirements**: Signatures only for documents requiring legal validity, with official position verification
- **JWKS Cache Strategy**: TTL ≤1 hour with background refresh and rollover window
- **Data Residency**: Declarative policies with `data_residency={region}` metadata tags

### 10.3 Threat Mitigation
- **Input Validation**: Protection against injection attacks
- **Rate Limiting**: Per-IP and per-tenant rate limiting with optional proof-of-work for high-risk operations; formalized in ADR-017 "Proof-of-Work Rate Limiting and Anti-Enumeration"
- **Adaptive Rate Limiting**: Dynamic adjustment of limits based on traffic patterns and threat detection
- **Secure Defaults**: Security-first configuration
- **Regular Security Assessments**: Continuous security evaluation
- **Federated Identity**: Support for external IdP integration (Google/Microsoft) with claim mapping
- **Claim Mapping**: Standardized mapping of external IdP claims to SmartEdify user profiles and roles
- **Logout Propagation**: Synchronized logout across all federated identity providers
- **External IdP Validation**: Certificate pinning, token audience validation, and clock skew tolerance
- **Session Revocation**: ≤30s with Redis regional clusters and Kafka events

---

## 11. Technology Scope

### 11.1 Technology Stack
- **Backend Services**: Java Spring Boot with Kotlin (for performance and JVM stability)
- **Database**: PostgreSQL with advanced security features and RLS
- **Message Queue**: Apache Kafka for event-driven architecture
- **Cache**: Redis with regional clusters, multi-layer caching and anti-replay protection
- **File Storage**: AWS S3 with object lock and WORM support
- **Security**: Hardware Security Modules (HSM) for key management
- **Service Mesh**: Istio for mTLS, traffic management, retries and circuit breakers
- **API Gateway**: Kong or AWS API Gateway with PBAC enforcement
- **Federated Identity**: Support for external IdP integration (Google/Microsoft)
- **Zero Trust at Gateway**: PBAC enforcement in PEP, rate-limits by tenant_id and IP/ASN, optional proof-of-work anti-enumeration

### 11.2 Development Tools and Frameworks
- **API Specification**: OpenAPI 3.1
- **Database Modeling**: DBML
- **Infrastructure**: Infrastructure as Code (Terraform)
- **CI/CD**: Automated pipelines with security scanning and compliance validation
- **Monitoring**: OpenTelemetry ecosystem with Prometheus, Grafana and Jaeger/Tempo
- **Security Testing**: OWASP ZAP, Snyk, SonarQube
- **Chaos Engineering**: Gremlin framework for controlled failure testing

---

## 12. Operational Scope

### 12.1 Deployment Requirements
- **Multi-Region**: Deployments in multiple geographic regions
- **Auto-Scaling**: Automatic scaling based on demand
- **Blue-Green Deployments**: Zero-downtime deployments
- **Canary Releases**: Gradual rollout of new features

### 12.2 Monitoring and Observability
- **Metrics Collection**: Business and technical metrics
- **Distributed Tracing**: End-to-end request tracing
- **Structured Logging**: Comprehensive logging strategy
- **Alerting**: Proactive alerting based on SLOs
- **Required SLO/SI Metrics**:
  - `token_validation_error_rate`: Token validation error rate
  - `jwks_refresh_latency_p95`: JWKS refresh latency (P95)
  - `policy_version_skew`: Difference between latest policy version and cached version
  - `revocation_latency_p95`: Session/device revocation latency (P95)
  - `device_attestation_failure_rate`: Device attestation failure rate
- **Observability Tools**:
  - **Grafana Dashboards**: Real-time visualization of SLO/SI metrics, service health, and business KPIs
  - **Tempo**: Distributed tracing for request flow analysis and performance troubleshooting
  - **Jaeger**: Alternative distributed tracing for cross-service request analysis
  - **OpenSearch/ELK**: Log aggregation and analysis for security and operational events
  - **Prometheus**: Metrics collection and alerting based on defined SLOs

### 12.3 Backup and Recovery
- **Data Backup**: Automated backup of all critical data
- **Disaster Recovery**: Multi-region backup and recovery procedures
- **Data Lifecycle**: Automated data archival and deletion
- **Business Continuity**: Procedures for maintaining operations
- **RTO/RPO by Service**:
  - Identity Service: RTO ≤ 5 min, RPO ≤ 1 min
  - Governance Service: RTO ≤ 15 min, RPO ≤ 5 min
  - Other services: RTO ≤ 30 min, RPO ≤ 10 min
- **Recovery Testing**: Quarterly DR validation exercises
- **Chaos Engineering**: Regular failure testing and resilience validation using Gremlin framework
- **Chaos Scenarios**: Cross-region latency testing, Compliance service failure, DR failover automation
- **Kafka Failure Scenarios**: Broker unavailability, topic partition unavailability, consumer lag simulation
- **Inter-regional Latency Scenarios**: Network partitioning, increased cross-region latency, WAN link degradation
- **Compliance Service Failure**: Complete service unavailability, partial functionality degradation, policy cache poisoning
- **Database Connection Scenarios**: Connection pool exhaustion, read replica failures, primary database failover
- **Cache Failure Scenarios**: Redis cluster partitioning, cache eviction anomalies, session data loss

---

## 13. Quality Assurance Scope

### 13.1 Testing Requirements
- **Unit Testing**: Comprehensive unit test coverage
- **Integration Testing**: Testing of service interactions
- **Performance Testing**: Load and stress testing
- **Security Testing**: Regular security assessments
- **Compliance Testing**: Verification of regulatory compliance

### 13.2 Quality Gates
- **Code Quality**: Automated code quality checks
- **Security Scanning**: Vulnerability assessments in CI/CD
- **Performance Benchmarks**: Automated performance validation
- **Compliance Verification**: Automated compliance checks

---

## 14. Risk Scope

### 14.1 Technical Risks
- **Scalability**: Ensuring the system handles growth
- **Security**: Managing security in a complex distributed system
- **Compliance**: Maintaining compliance across jurisdictions
- **Performance**: Managing performance across microservices

### 14.2 Business Risks
- **Regulatory Changes**: Adapting to changing legal requirements
- **User Adoption**: Ensuring user acceptance of new processes
- **Data Privacy**: Managing privacy requirements across regions
- **Integration Complexity**: Managing third-party integrations

---

## 15. Implementation Scope

### 15.1 Phased Implementation
- **Phase 1**: Core backbone (Identity, Profiles, Tenancy, Compliance)
- **Phase 2**: Governance and operations (Governance, Reservations, Asset Mgmt)
- **Phase 3**: Finance and payroll modules
- **Phase 4**: Business and analytics services
- **Phase 5**: Stabilization and global release

### 15.2 Service Dependencies
- **Critical Path**: Identity Service as foundation
- **Parallel Development**: Services with minimal dependencies
- **Incremental Integration**: Gradual service integration
- **Backward Compatibility**: Maintaining compatibility during evolution

---

## 16. Success Criteria

### 16.1 Business Success Metrics
- **User Adoption**: Number of active tenants and users
- **Compliance Rate**: 100% compliance with regulations
- **User Satisfaction**: High satisfaction scores
- **Time to Value**: Quick time to first value for new tenants

### 16.2 Technical Success Metrics
- **System Availability**: ≥99.95% uptime
- **Performance**: Meeting all defined SLOs
- **Security**: Zero security incidents
- **Scalability**: Supporting planned growth

---

## 17. Appendices

### 17.1 Glossary
- **Data Residency**: The practice of storing data in a specific geographic location or region to comply with local regulations and legal requirements. In SmartEdify, data residency is enforced through metadata tags and region-specific storage policies.
- **Degraded Mode**: A system operational state where certain non-critical functions are disabled to maintain core functionality during service unavailability. In SmartEdify, compliance service degraded mode allows read operations while blocking legal operations requiring real-time compliance validation, with recovery required within 24 hours.
- **Identity-QR**: Cryptographically signed QR codes (COSE/JWS, TTL≤300s) used for legal assembly access with official position verification.
- **Asset-QR**: Simple identifiers without encryption used for physical asset identification and tracking.
- **Policy Version Skew**: The difference between the latest policy version and the cached version in distributed systems.
- **OpenAPI Contracts**: Standardized API specifications (OpenAPI 3.1) defining endpoints for each service domain including OIDC discovery, QR contextual generation, DSAR processing, reservations, and legal document endpoints.
[Detailed definitions of other terms used throughout this document]

### 17.2 Architecture Diagrams
[Detailed architecture diagrams showing all system components and their relationships]

### 17.3 External References
- SmartEdify Vision Document
- Software Architecture Document
- Compliance Framework Document
- Security Policies Document
- Development Standards Document

---

## 18. Document Change History

| Version | Date | Author | Description of Changes |
|---------|-------|--------|------------------------|
| 1.0 | [Date] | [Author] | Initial version |
| [Next] | [Date] | [Author] | [Changes] |