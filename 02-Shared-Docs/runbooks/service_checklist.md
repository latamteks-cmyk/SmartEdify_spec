# Service Operations Checklist

## Pre-deployment
- [ ] Verify database schema compatibility
- [ ] Check configuration parameters are properly set
- [ ] Validate secrets are available in Secrets Manager
- [ ] Confirm dependency services are available (Kafka, Redis, PostgreSQL)
- [ ] Verify monitoring endpoint is accessible

## Post-deployment
- [ ] Confirm service health endpoint returns 200 OK
- [ ] Verify new version metrics are being reported
- [ ] Check logs for errors or warnings
- [ ] Validate API endpoints are responding correctly
- [ ] Confirm integration with other services is working

## Daily Operations
- [ ] Monitor service health
- [ ] Check for alert notifications
- [ ] Review error logs for anomalies
- [ ] Verify backup jobs completed successfully
- [ ] Monitor system resource utilization

## Incident Response
- [ ] Acknowledge alert immediately
- [ ] Assess impact and scope
- [ ] Follow specific incident runbook
- [ ] Escalate if needed
- [ ] Document incident resolution

## Weekly Tasks
- [ ] Review performance metrics
- [ ] Check for security updates
- [ ] Validate data retention policies
- [ ] Review audit logs for anomalies
- [ ] Update operational documentation if needed

## Monthly Tasks
- [ ] Review SLO compliance
- [ ] Perform capacity planning
- [ ] Rotate service credentials if applicable
- [ ] Review disaster recovery procedures
- [ ] Update runbooks based on learnings

## Critical Service Specific Checks

### Identity Service
- [ ] WebAuthn registration/login is functioning
- [ ] DPoP token generation is working
- [ ] JWKS cache is being updated
- [ ] Session management is operating correctly

### Compliance Service
- [ ] Policy evaluation is fast and accurate
- [ ] Cache hit rates are acceptable (>85%)
- [ ] Policy updates are propagating correctly
- [ ] Emergency mode is properly configured

### Governance Service
- [ ] Assembly creation and management functions
- [ ] QR generation is working for legal events
- [ ] Integration with Identity Service is secure
- [ ] WORM logging is functioning correctly