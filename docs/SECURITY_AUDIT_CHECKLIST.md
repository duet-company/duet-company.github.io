# Production Security Audit Checklist - Duet Company

*Prepared: 2026-03-25*
*Status: Draft - Ready for Review*

## Overview

This checklist ensures the AI Data Labs platform meets production-grade security standards before public launch. It complements the security testing guide (docs/SECURITY_TESTING.md).

---

## 🔒 Pre-Launch Security Verification

### Infrastructure Security

- [ ] **Network Security**
  - [ ] All services firewalled (only necessary ports open)
  - [ ] No default credentials in any service
  - [ ] TLS 1.2+ enforced for all external traffic
  - [ ] Internal service communication encrypted (mTLS if possible)
  - [ ] DDoS protection enabled (Cloudflare/WAF)

- [ ] **Kubernetes Security**
  - [ ] Pod Security Policies / OPA Gatekeeper enforced
  - [ ] No privileged containers
  - [ ] Read-only root filesystem where possible
  - [ ] Non-root users for all containers
  - [ ] Resource limits set (CPU, memory)
  - [ ] Network Policies restrict pod-to-pod communication
  - [ ] Secrets stored in Kubernetes Secrets (not ConfigMaps)
  - [ ] Image provenance: only signed images from trusted registry

- [ ] **Database Security**
  - [ ] ClickHouse: no default passwords changed
  - [ ] Database access restricted to application pods only
  - [ ] SSL/TLS for database connections
  - [ ] Regular backups encrypted at rest
  - [ ] Backup access logged and audited
  - [ ] Principle of least privilege for database users
  - [ ] Query logging enabled for audit
  - [ ] Data retention policies defined

### Application Security

- [ ] **Authentication & Authorization**
  - [ ] Multi-factor authentication (MFA) required for admin accounts
  - [ ] Password policy: minimum length, complexity, expiration
  - [ ] Rate limiting on authentication endpoints (prevent brute force)
  - [ ] Session management: secure cookies, proper expiration
  - [ ] JWT tokens signed with strong algorithm (RS256/ES256)
  - [ ] Token revocation mechanism implemented
  - [ ] Role-based access control (RBAC) fully implemented
  - [ ] Principle of least privilege enforced

- [ ] **Input Validation & Sanitization**
  - [ ] All user inputs validated (server-side)
  - [ ] SQL injection prevention (parameterized queries)
  - [ ] XSS prevention: output encoding, CSP headers
  - [ ] File upload restrictions: type, size, content scanning
  - [ ] Command injection prevention (no shell execution with user input)
  - [ ] XML external entity (XXE) protection
  - [ ] Deserialization security (avoid or use safe methods)

- [ ] **API Security**
  - [ ] API rate limiting per user/IP
  - [ ] API keys/tokens properly secured
  - [ ] CORS policy: only allowed origins
  - [ ] No sensitive data in API responses (unless authorized)
  - [ ] API versioning strategy in place
  - [ ] Deprecation warnings for old API versions
  - [ ] API request/response logging for audit
  - [ ] GraphQL query depth/size limits (if applicable)

- [ ] **Logging & Monitoring**
  - [ ] Security event logging: authentication, authorization, errors
  - [ ] Logs centralized and protected from tampering
  - [ ] Log retention policy (minimum 90 days)
  - [ ] Alerting on suspicious patterns (failed logins, unusual queries)
  - [ ] Audit trails for all admin actions
  - [ ] Log sanitization: no secrets/PII in logs

### Data Security

- [ ] **Encryption**
  - [ ] Data at rest encrypted (database, file storage)
  - [ ] Data in transit encrypted (TLS 1.2+)
  - [ ] Encryption keys stored in secure vault (HashiCorp Vault/AWS Secrets Manager)
  - [ ] Key rotation policy defined
  - [ ] Certificate management: automated renewal (Let's Encrypt)
  - [ ] No hardcoded secrets in code or config files

- [ ] **Data Privacy**
  - [ ] GDPR compliance verified (if EU users)
  - [ ] Data minimization: only collect necessary data
  - [ ] User data deletion endpoint implemented
  - [ ] Data export functionality for users (data portability)
  - [ ] Privacy policy clearly stated
  - [ ] Cookie consent mechanism (if applicable)
  - [ ] Third-party data sharing disclosed

### Agent Security (AI-specific)

- [ ] **LLM Provider Security**
  - [ ] API keys stored securely (environment variables/secret manager)
  - [ ] LLM provider access scoped to minimal permissions
  - [ ] No prompt injection vulnerabilities tested
  - [ ] LLM output sanitized before use
  - [ ] Token limits enforced to prevent excessive costs
  - [ ] Provider fallback and error handling

- [ ] **Agent Communication**
  - [ ] Inter-agent communication authenticated
  - [ ] Agent commands validated and sandboxed
  - [ ] No arbitrary code execution from agent suggestions
  - [ ] Agent tool usage logged and audited
  - [ ] Rate limiting per agent/user
  - [ ] Agent capabilities properly scoped

### CI/CD & Supply Chain Security

- [ ] **Pipeline Security**
  - [ ] CI/CD secrets stored in vault, not in repo
  - [ ] Pipeline access restricted (least privilege)
  - [ ] Build artifacts signed
  - [ ] Dependency scanning (Snyk, Dependabot,GitHub Security)
  - [ ] SAST (Static Application Security Testing) integrated
  - [ ] Container image scanning (Trivy, Clair)
  - [ ] Infrastructure as Code scanning (Checkov, tfsec)
  - [ ] No credentials in build logs

- [ ] **Dependency Management**
  - [ ] All dependencies from trusted sources
  - [ ] Regular dependency updates (automated PRs)
  - [ ] Vulnerability scanning on dependencies
  - [ ] No known critical CVEs in dependencies
  - [ ] Software Bill of Materials (SBOM) generated
  - [ ] License compliance verified

### Compliance & Legal

- [ ] **Terms of Service & Privacy Policy**
  - [ ] ToS drafted and reviewed by legal counsel
  - [ ] Privacy policy compliant with applicable laws (GDPR, CCPA, etc.)
  - [ ] Data processing agreement (DPA) available for enterprise
  - [ ] Cookie policy if using tracking cookies
  - [ ] Acceptable use policy defined

- [ ] **Data Residency & Sovereignty**
  - [ ] Data storage location disclosed to users
  - [ ] Compliance with local regulations (GDPR, PDPA, etc.)
  - [ ] Cross-border data transfer mechanisms documented

---

## 🧪 Penetration Testing Scope

### External Testing
- [ ] Web application (OWASP Top 10)
- [ ] API endpoints (authentication, rate limiting, injection)
- [ ] Network services (exposed ports)
- [ ] Mobile app if applicable

### Internal Testing
- [ ] Lateral movement from compromised pod
- [ ] Kubernetes cluster misconfigurations
- [ ] Database access from within cluster
- [ ] Secret leakage in pod environment

### Social Engineering
- [ ] Phishing simulation for team members
- [ ] Physical security assessment (if office)

---

## 📊 Security Metrics to Track

- Mean time to patch critical vulnerabilities
- Number of open critical/high vulnerabilities
- Security incident count and response time
- Failed login attempts and brute force attempts
- SSL/TLS certificate expiration monitoring
- Secret scanning findings in code
- Dependency vulnerability age

---

## 🚨 Incident Response Checklist

- [ ] Incident response plan documented and team trained
- [ ] Severity classification defined ( Sev 1-4 )
- [ ] Communication plan (internal + external)
- [ ] Escalation procedures clear
- [ ] Post-incident review process (blameless)
- [ ] Runbooks for common incidents (data breach, DDoS, ransomware)
- [ ] Contact list: legal, PR, security team
- [ ] Backup restoration procedure tested

---

## ✅ Final Sign-off

| Area | Owner | Status | Notes |
|------|-------|--------|-------|
| Infrastructure Security | | | |
| Application Security | | | |
| Data Security | | | |
| Agent Security | | | |
| CI/CD Security | | | |
| Compliance & Legal | | | |
| Penetration Testing | | | |
| Incident Response | | | |

**Security Lead Sign-off:** _________________ Date: _______

**CTO Sign-off:** _________________ Date: _______

---

## References

- Security Testing Guide: `docs/SECURITY_TESTING.md`
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- Kubernetes Security Best Practices: https://kubernetes.io/docs/concepts/security/
- ClickHouse Security: https://clickhouse.com/docs/en/operations/security/
- NIST Cybersecurity Framework: https://www.nist.gov/cyberframework

---

**Next Steps:**
1. Distribute to security team for review
2. Schedule security audit meeting
3. Assign owners for each section
4. Set timeline for completion (target: before beta launch)
5. Revisit after each major release
