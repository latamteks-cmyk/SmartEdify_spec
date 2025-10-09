# Metrics Definitions for SmartEdify Services

## Overview
This document defines the standard metrics that each SmartEdify service should expose to ensure consistent observability across the platform.

## Standard Service Metrics

### Availability Metrics
All services must track:
- `service_availability_percent` - Percentage of time service is available
- `service_uptime_seconds` - Total uptime in seconds
- `service_downtime_seconds` - Total downtime in seconds

### Performance Metrics
All services must track:
- `service_response_time_seconds` - Response time histogram
- `service_requests_total` - Total number of requests
- `service_requests_by_status` - Requests by HTTP status code
- `service_errors_total` - Total number of errors

### Resource Utilization
All services must track:
- `service_cpu_usage_percent` - CPU usage percentage
- `service_memory_usage_bytes` - Memory usage in bytes
- `service_disk_usage_bytes` - Disk space usage in bytes
- `service_network_io_bytes` - Network I/O in bytes

## Service-Specific Metrics

### Identity Service (3001)
- `identity_authentications_total` - Total authentication requests
- `identity_authentications_by_method` - Authentications by method (WebAuthn, TOTP, etc.)
- `identity_auth_success_rate` - Authentication success rate
- `identity_session_creations_total` - Total session creations
- `identity_session_validations_total` - Total session validations
- `identity_dpop_token_issuance_total` - Total DPoP token issuances
- `identity_jwks_cache_hit_rate` - JWKS cache hit rate
- `identity_qr_generation_seconds` - Time to generate legal QR codes
- `identity_webauthn_registration_seconds` - Time to complete WebAuthn registration

### User Profiles Service (3002)
- `user_profiles_reads_total` - Total profile read operations
- `user_profiles_writes_total` - Total profile write operations
- `user_profiles_consent_changes_total` - Total consent changes
- `user_profiles_role_assignments_total` - Total role assignments
- `user_profiles_organizations_linked_total` - Total organization links created

### Tenancy Service (3003)
- `tenancy_requests_total` - Total tenancy-related requests
- `tenants_created_total` - Total tenants created
- `condominiums_created_total` - Total condominiums created
- `tenancy_data_isolation_violations_total` - Data isolation violations detected
- `tenancy_jurisdiction_changes_total` - Jurisdiction changes

### Notifications Service (3005)
- `notifications_sent_total` - Total notifications sent
- `notifications_by_channel` - Notifications by channel (email, SMS, push)
- `notifications_delivery_rate` - Notification delivery success rate
- `notifications_click_rate` - Notification click-through rate

### Documents Service (3006)
- `documents_processed_total` - Total documents processed
- `documents_signed_total` - Total documents with digital signatures
- `documents_storage_bytes` - Total storage used for documents
- `documents_worm_verification_total` - Total WORM verification checks
- `documents_signature_validation_total` - Total signature validations

### Governance Service (3011)
- `governance_assemblies_created_total` - Total assemblies created
- `governance_votes_cast_total` - Total votes cast
- `governance_resolutions_passed_total` - Total resolutions passed
- `governance_legal_qr_generations_total` - Legal QR code generations
- `governance_attestation_validations_total` - Attestation validations

### Compliance Service (3012)
- `compliance_policy_evaluations_total` - Total policy evaluations
- `compliance_violations_detected_total` - Total violations detected
- `compliance_policy_cache_hit_rate` - Policy cache hit rate
- `compliance_emergency_mode_activations_total` - Emergency mode activations
- `compliance_policy_updates_received_total` - Policy updates received

### Reservations Service (3013)
- `reservations_made_total` - Total reservations made
- `reservations_confirmed_total` - Total reservations confirmed
- `reservations_canceled_total` - Total reservations canceled
- `reservations_checkins_total` - Total check-ins
- `reservations_eligibility_checks_total` - Eligibility checks performed

### Asset Management Service (3010)
- `assets_tracked_total` - Total assets being tracked
- `incidents_reported_total` - Total incidents reported
- `work_orders_created_total` - Total work orders created
- `asset_qr_scans_total` - Total asset QR code scans

### Finance Service (3007)
- `finance_transactions_processed_total` - Total transactions processed
- `finance_reports_generated_total` - Total reports generated
- `finance_regulatory_exports_total` - Total regulatory exports
- `finance_currency_conversions_total` - Total currency conversions

### Payroll Service (3008)
- `payroll_calculations_performed_total` - Total payroll calculations
- `payroll_slips_generated_total` - Total payroll slips generated
- `payroll_tax_calculations_total` - Total tax calculations
- `payroll_regulatory_reports_total` - Total regulatory reports

### HR Compliance Service (3009)
- `hr_compliance_checks_total` - Total compliance checks
- `hr_policy_violations_total` - Total policy violations detected
- `hr_regulatory_updates_processed_total` - Total regulatory updates processed

### Streaming Service (3014)
- `streaming_sessions_total` - Total streaming sessions
- `streaming_participants_total` - Total participants in streams
- `streaming_recording_seconds_total` - Total recording time in seconds
- `streaming_timestamp_certifications_total` - Total timestamp certifications

### Marketplace Service (3015)
- `marketplace_providers_registered_total` - Total providers registered
- `marketplace_services_booked_total` - Total services booked
- `marketplace_payments_processed_total` - Total payments processed

### Analytics Service (3016)
- `analytics_queries_executed_total` - Total analytics queries
- `analytics_dashboards_created_total` - Total dashboards created
- `analytics_reports_generated_total` - Total reports generated
- `analytics_kpi_calculations_total` - Total KPI calculations

## SLO-Specific Metrics

### Global SLOs
- `global_availability_percent` - Overall platform availability
- `global_auth_response_time_p95` - P95 authentication response time
- `global_session_revocation_time` - Session revocation time
- `global_compliance_validation_time` - Compliance validation time
- `global_audit_trail_completeness` - Audit trail completeness percentage

### Error Budget Tracking
- `error_budget_remaining_percent` - Remaining error budget
- `error_budget_burn_rate` - Rate of error budget consumption
- `error_budget_alert_threshold` - Threshold for error budget alerts

## Alert Definitions

### Critical Alerts (P0)
- Service availability < 99%
- Authentication failure rate > 5%
- Data isolation violation detected
- Security breach indicators

### High Priority Alerts (P1)
- Response time P95 > 3 seconds
- Error rate > 1%
- Resource utilization > 90%
- Compliance validation timeout

### Medium Priority Alerts (P2)
- Cache hit rate < 85%
- Batch job failure
- Metric threshold approaching SLO
- Unusual access pattern

## Metrics Collection Standards

### Labels
All metrics should include these standard labels:
- `service_name` - Name of the service
- `service_version` - Version of the service
- `environment` - Environment (dev, preprod, prod)
- `region` - Geographic region
- `tenant_id` - Tenant identifier (when applicable)
- `condominium_id` - Condominium identifier (when applicable)

### Histogram Buckets
Use these standard buckets for response time histograms:
- `0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0, 7.5, 10.0`

### Collection Intervals
- Counter metrics: Updated per request
- Gauge metrics: Updated every 15 seconds
- Histogram metrics: Updated per request
- Summary metrics: Updated per request with 0.5, 0.9, 0.95, 0.99 quantiles

## Dashboard Recommendations

### Service Health Dashboard
- Service availability (current, 7-day, 30-day)
- Request rate and error rate
- Response time percentiles
- Resource utilization

### Business Metrics Dashboard
- User authentication rate
- Document signing volume
- Assembly participation rates
- Reservation completion rates

### Security Dashboard
- Authentication methods usage
- Failed authentication attempts
- Policy violation incidents
- Audit log completeness

### Compliance Dashboard
- Compliance validation success rate
- Policy update distribution
- Emergency mode usage
- Jurisdiction coverage