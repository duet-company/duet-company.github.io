# CI/CD Quick Start Guide

## Prerequisites

Before setting up CI/CD pipelines, ensure you have:

1. **GitHub Repository Access** - Push access to duet-company repos
2. **Kubernetes Clusters** - Staging and production clusters
3. **Container Registry** - GitHub Container Registry (GHCR) access
4. **Secrets Configured** - See Secrets Configuration below

---

## Setup Steps

### 1. Enable GitHub Actions

```bash
# Navigate to repository
cd company

# Enable GitHub Actions (via UI or API)
# Settings → Actions → General → Allow all actions
```

### 2. Configure GitHub Secrets

Go to repository settings → Secrets and variables → Actions → New repository secret

#### Required Secrets for All Pipelines

| Secret Name | Description | Example |
|------------|-------------|---------|
| `SNYK_TOKEN` | Snyk API token for dependency scanning | `abc123...` |
| `CODECOV_TOKEN` | Codecov token for coverage reporting | `abc123...` |
| `SENTRY_DSN` | Sentry DSN for error tracking | `https://...` |

#### Backend-Specific Secrets

| Secret Name | Description | Example |
|------------|-------------|---------|
| `KUBE_CONFIG_STAGING` | Base64-encoded kubeconfig for staging | `...` |
| `KUBE_CONFIG_PRODUCTION` | Base64-encoded kubeconfig for production | `...` |
| `DATABASE_URL` | Production database connection string | `postgresql://...` |
| `OPENAI_API_KEY` | OpenAI API key | `sk-...` |
| `ANTHROPIC_API_KEY` | Anthropic API key | `sk-ant-...` |

#### Frontend-Specific Secrets

| Secret Name | Description | Example |
|------------|-------------|---------|
| `KUBE_CONFIG_STAGING` | Base64-encoded kubeconfig for staging | `...` |
| `KUBE_CONFIG_PRODUCTION` | Base64-encoded kubeconfig for production | `...` |

#### Infrastructure-Specific Secrets

| Secret Name | Description | Example |
|------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS access key for Terraform | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for Terraform | `...` |
| `INFRACOST_API_KEY` | Infracost API key for cost estimation | `...` |

#### Documentation-Specific Secrets

| Secret Name | Description | Example |
|------------|-------------|---------|
| `NETLIFY_AUTH_TOKEN` | Netlify auth token | `...` |
| `NETLIFY_SITE_ID_STAGING` | Netlify site ID for staging | `...` |
| `NETLIFY_SITE_ID_PRODUCTION` | Netlify site ID for production | `...` |

### 3. Generate Base64-Encoded Kubeconfig

```bash
# Encode kubeconfig for staging
cat ~/.kube/config-staging | base64 -w 0

# Encode kubeconfig for production
cat ~/.kube/config-production | base64 -w 0
```

### 4. Copy Workflow Files

```bash
# Copy workflow files to repository
cp -r .github/workflows/* <repository>/.github/workflows/

# Commit and push
git add .github/workflows/
git commit -m "feat: add CI/CD pipelines"
git push
```

### 5. Test Pipelines

```bash
# Create a test branch
git checkout -b test/ci-cd

# Make a small change
echo "# Test" > test.md
git add test.md
git commit -m "test: CI/CD pipeline test"

# Push and check workflows
git push origin test/ci-cd

# Monitor: https://github.com/duet-company/<repo>/actions
```

---

## Verification Checklist

- [ ] GitHub Actions enabled
- [ ] All secrets configured
- [ ] Workflow files committed
- [ ] Test branch created and pushed
- [ ] CI pipeline runs successfully (lint, test, security-scan)
- [ ] Docker image builds successfully
- [ ] Staging deployment works
- [ ] Production deployment works (main branch only)
- [ ] Rollback test successful
- [ ] Monitoring and alerts configured

---

## Common Issues

### Issue: "kubeconfig secret not found"

**Solution:**
```bash
# Verify secret exists
gh secret list --repo duet-company/company

# Re-add secret if missing
echo "<base64-kubeconfig>" | gh secret set KUBE_CONFIG_PRODUCTION --repo duet-company/company
```

### Issue: "Docker build fails with permission denied"

**Solution:**
- Verify GHCR permissions in GitHub organization settings
- Check package registry access tokens
- Ensure image name format is correct: `ghcr.io/duet-company/<repo>`

### Issue: "Tests pass locally but fail in CI"

**Solution:**
- Check for environment-specific configuration
- Verify test data is committed
- Check for time-sensitive tests
- Review CI environment logs

### Issue: "Canary deployment not promoting to production"

**Solution:**
- Check error rate monitoring configuration
- Verify Prometheus query syntax
- Review canary monitoring logs
- Manually promote if needed:
  ```bash
  kubectl set image deployment/backend backend=<image-tag> -n production
  ```

---

## Monitoring Pipelines

### View Workflow Runs

```bash
# List recent workflow runs
gh run list --repo duet-company/company

# View specific run
gh run view <run-id> --repo duet-company/company

# View logs for specific job
gh run view <run-id> --repo duet-company/company --log
```

### Failed Workflow Investigation

1. **Check Workflow Logs:** `gh run view <run-id> --log`
2. **Check Application Logs:** `kubectl logs deployment/backend -n production`
3. **Check Kubernetes Events:** `kubectl get events -n production --sort-by=.metadata.creationTimestamp`
4. **Check Health Status:** `kubectl get pods -n production`

---

## Rollback Procedures

### Automatic Rollback

Rollback automatically triggers on:
- Health check failure (> 3 attempts)
- Error rate > 1%
- Response time > 5s
- Critical alert triggered

### Manual Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/backend -n production

# Rollback to specific revision
kubectl rollout undo deployment/backend --to-revision=5 -n production

# Check rollback status
kubectl rollout status deployment/backend -n production

# View revision history
kubectl rollout history deployment/backend -n production
```

### Rollback Verification

```bash
# Health check
curl -f https://api.aidatalabs.ai/health

# Check error rate
curl -s 'http://prometheus.aidatalabs.ai/api/v1/query?query=rate(http_requests_total{job="backend",status=~"5.."}[5m])'
```

---

## Performance Optimization

### Reduce Pipeline Duration

1. **Enable Caching:**
   - Docker layer caching (enabled by default)
   - pip/npm caching (configured in workflows)
   - Terraform remote state (use S3 or Terraform Cloud)

2. **Parallel Execution:**
   - Lint and security-scan run in parallel
   - Test and security-scan run in parallel after lint

3. **Optimized Build:**
   - Use multi-stage Docker builds
   - Minimize image layers
   - Use .dockerignore files

### Cost Optimization

1. **Infrastructure Costs:**
   - Use Infracost to estimate changes
   - Review cost estimates in PR comments
   - Set cost budgets and alerts

2. **CI/CD Costs:**
   - Use self-hosted runners for large builds
   - Limit artifact retention (7 days default)
   - Optimize Docker image sizes

---

## Best Practices

### Code Quality

- **Always run linting before committing**
- **Maintain >80% test coverage**
- **Write integration tests for critical paths**
- **Document API changes in PRs**

### Deployment

- **Use feature branches for new work**
- **Merge to develop for staging**
- **Cherry-pick or merge to main for production**
- **Monitor deployments closely after rollout**

### Security

- **Review security scan results**
- **Update dependencies regularly**
- **Use secret scanning**
- **Enable branch protection rules**

### Monitoring

- **Set up alerts for critical metrics**
- **Review dashboards regularly**
- **Investigate anomalies quickly**
- **Document incidents and resolutions**

---

## Next Steps

1. **Configure additional pipelines:**
   - Load testing pipeline
   - Chaos engineering pipeline
   - Compliance scanning pipeline

2. **Set up monitoring:**
   - Grafana dashboards
   - Prometheus alerts
   - PagerDuty integration

3. **Automate further:**
   - Automated dependency updates (Dependabot)
   - Automated security updates (Renovate)
   - Automated changelog generation

---

## Support

For issues or questions:
- Check workflow logs: `gh run view <run-id> --log`
- Review documentation: `README.md`
- Create issue: https://github.com/duet-company/company/issues

---

**Last Updated:** 2026-02-26
**Version:** 1.0.0
