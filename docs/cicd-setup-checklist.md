# CI/CD Setup Checklist

Use this checklist to set up CI/CD pipelines for Duet Company repositories.

---

## Phase 1: Pre-Setup (15 minutes)

### Repository Preparation
- [ ] Verify repository is not archived
- [ ] Enable GitHub Actions in repository settings
- [ ] Configure branch protection rules:
  - [ ] Require pull request before merge
  - [ ] Require status checks to pass
  - [ ] Require branches to be up to date
- [ ] Add CODEOWNERS file for code review assignments

### Container Registry Setup
- [ ] Verify GitHub Container Registry (GHCR) access
- [ ] Test registry authentication:
  ```bash
  echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
  ```
- [ ] Create repository in GHCR if needed

---

## Phase 2: Secrets Configuration (30 minutes)

### Generate and Add Secrets

#### Common Secrets
- [ ] `SNYK_TOKEN`: Get from https://snyk.io/account
- [ ] `CODECOV_TOKEN`: Get from https://codecov.io/gh/duet-company
- [ ] `SENTRY_DSN`: Get from https://sentry.io

#### Backend Secrets
- [ ] `KUBE_CONFIG_STAGING`: `cat ~/.kube/config-staging | base64 -w 0`
- [ ] `KUBE_CONFIG_PRODUCTION`: `cat ~/.kube/config-production | base64 -w 0`
- [ ] `DATABASE_URL`: Production database connection string
- [ ] `OPENAI_API_KEY`: Get from https://platform.openai.com
- [ ] `ANTHROPIC_API_KEY`: Get from https://console.anthropic.com

#### Frontend Secrets
- [ ] `KUBE_CONFIG_STAGING`: Same as backend or separate
- [ ] `KUBE_CONFIG_PRODUCTION`: Same as backend or separate

#### Infrastructure Secrets
- [ ] `AWS_ACCESS_KEY_ID`: Get from AWS IAM console
- [ ] `AWS_SECRET_ACCESS_KEY`: Get from AWS IAM console
- [ ] `INFRACOST_API_KEY`: Get from https://infracost.io

#### Documentation Secrets
- [ ] `NETLIFY_AUTH_TOKEN`: Get from Netlify app settings
- [ ] `NETLIFY_SITE_ID_STAGING`: Get from Netlify site settings
- [ ] `NETLIFY_SITE_ID_PRODUCTION`: Get from Netlify site settings

---

## Phase 3: Pipeline Deployment (20 minutes)

### Workflow Files
- [ ] Copy backend-ci.yml to `.github/workflows/`
- [ ] Copy frontend-ci.yml to `.github/workflows/`
- [ ] Copy infrastructure-ci.yml to `.github/workflows/`
- [ ] Copy docs-ci.yml to `.github/workflows/`

### Commit and Push
- [ ] Review workflow files for customizations
- [ ] Update environment URLs if needed
- [ ] Commit workflow files
- [ ] Push to repository
- [ ] Verify workflows appear in Actions tab

---

## Phase 4: Testing (30 minutes)

### Test CI Pipeline
- [ ] Create test branch: `git checkout -b test/ci-cd`
- [ ] Make minor change: `echo "# Test" > test.md`
- [ ] Commit: `git commit -am "test: CI/CD pipeline test"`
- [ ] Push: `git push origin test/ci-cd`
- [ ] Verify CI pipeline runs successfully
- [ ] Check lint, test, security-scan jobs

### Test Build Pipeline
- [ ] Verify Docker image builds
- [ ] Check image is pushed to GHCR
- [ ] Verify SBOM is generated

### Test Staging Deployment
- [ ] Merge to develop branch
- [ ] Verify staging deployment triggers
- [ ] Monitor rollout: `kubectl rollout status deployment/backend -n staging`
- [ ] Check health: `curl -f https://staging.aidatalabs.ai/health`
- [ ] Run smoke tests

### Test Production Deployment
- [ ] Create PR to main branch
- [ ] Merge PR to trigger production deployment
- [ ] Verify canary deployment
- [ ] Monitor for 5 minutes
- [ ] Verify full rollout
- [ ] Check health: `curl -f https://api.aidatalabs.ai/health`

---

## Phase 5: Monitoring & Alerting (20 minutes)

### Set Up Monitoring
- [ ] Configure Grafana dashboards
- [ ] Set up Prometheus alerts
- [ ] Configure PagerDuty integration (if applicable)
- [ ] Test alert notifications

### Verify Rollback
- [ ] Trigger rollback: `kubectl rollout undo deployment/backend -n production`
- [ ] Verify rollback succeeds
- [ ] Re-deploy latest version
- [ ] Document rollback procedure

---

## Phase 6: Documentation (15 minutes)

### Update Documentation
- [ ] Update README.md with CI/CD info
- [ ] Document deployment procedures
- [ ] Add troubleshooting guide
- [ ] Create runbook for common issues

### Team Training
- [ ] Share quick start guide with team
- [ ] Conduct CI/CD training session
- [ ] Create onboarding checklist
- [ ] Document best practices

---

## Phase 7: Optimization (Ongoing)

### Performance Tuning
- [ ] Monitor pipeline duration
- [ ] Optimize build times
- [ ] Reduce artifact retention if needed
- [ ] Tune caching strategies

### Cost Optimization
- [ ] Review Infracost estimates
- [ ] Set cost budgets
- [ ] Optimize infrastructure costs
- [ ] Review CI/CD runner costs

### Security
- [ ] Review security scan results
- [ ] Update dependencies regularly
- [ ] Enable Dependabot
- [ ] Conduct security audits

---

## Validation Checklist

After completing setup, validate:

- [ ] CI pipeline runs successfully on every commit
- [ ] All linting checks pass
- [ ] Test coverage > 80%
- [ ] Security scans pass (no critical vulnerabilities)
- [ ] Docker images build and push successfully
- [ ] Staging deployment works automatically
- [ ] Production deployment works via PR merge
- [ ] Canary deployment promotes correctly
- [ ] Rollback works when needed
- [ ] Monitoring and alerts are configured
- [ ] Team has access to documentation
- [ ] Onboarding process documented

---

## Troubleshooting

### Pipeline Fails on Lint
- Check linting tool versions
- Review linting rules in .config files
- Fix linting errors locally first

### Pipeline Fails on Tests
- Run tests locally: `pytest`
- Check test environment setup
- Review test logs in CI

### Docker Build Fails
- Check Dockerfile syntax
- Verify base image is accessible
- Check for rate limiting on Docker Hub

### Deployment Fails
- Check kubeconfig secret
- Verify cluster connectivity
- Check Kubernetes events: `kubectl get events`
- Review deployment logs: `kubectl logs deployment/backend`

### Rollback Fails
- Check revision history: `kubectl rollout history deployment/backend`
- Manually scale: `kubectl scale deployment/backend --replicas=0 -n production`
- Delete problematic deployment and redeploy

---

## Estimated Time

- **Phase 1:** 15 minutes
- **Phase 2:** 30 minutes
- **Phase 3:** 20 minutes
- **Phase 4:** 30 minutes
- **Phase 5:** 20 minutes
- **Phase 6:** 15 minutes
- **Total Setup:** ~2 hours

---

## Next Steps After Setup

1. **Set up additional pipelines:**
   - Load testing (k6)
   - Chaos engineering (Chaos Mesh)
   - Compliance scanning (SonarQube)

2. **Enhance monitoring:**
   - Distributed tracing (Jaeger)
   - Log aggregation (Loki)
   - Metrics visualization (Grafana)

3. **Automate further:**
   - Automated dependency updates (Dependabot)
   - Automated security updates (Renovate)
   - Automated changelog (Release Drafter)

---

**Last Updated:** 2026-02-26
**Version:** 1.0.0
