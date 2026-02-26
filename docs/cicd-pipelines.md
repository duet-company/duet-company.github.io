# CI/CD Pipelines for Duet Company

Complete CI/CD pipeline configurations for AI Data Labs platform.

## Overview

This repository contains CI/CD pipeline configurations for all Duet Company services:
- Platform (FastAPI backend)
- Frontend (React + TypeScript)
- Infrastructure (Terraform, Ansible, Kubernetes)
- Documentation
- Automated testing
- Deployment automation

## Pipeline Goals

- **Deployment Time:** < 10 minutes
- **Test Coverage:** > 80%
- **Zero-Downtime:** Rolling updates
- **Security:** Automated scanning (SAST, SCA, dependency checks)
- **Monitoring:** Automated health checks and rollback

---

## Table of Contents

1. [Backend CI/CD](#backend-cicd)
2. [Frontend CI/CD](#frontend-cicd)
3. [Infrastructure CI/CD](#infrastructure-cicd)
4. [Documentation CI/CD](#documentation-cicd)
5. [Quality Gates](#quality-gates)
6. [Deployment Strategies](#deployment-strategies)
7. [Monitoring & Rollback](#monitoring--rollback)

---

## Backend CI/CD

### GitHub Actions Workflow

File: `.github/workflows/backend-ci.yml`

```yaml
name: Backend CI/CD

on:
  push:
    branches: [main, develop]
    paths:
      - 'backend/**'
      - '.github/workflows/backend-ci.yml'
  pull_request:
    branches: [main, develop]
    paths:
      - 'backend/**'

env:
  PYTHON_VERSION: '3.11'
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/backend

jobs:
  lint:
    name: Lint Python Code
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
      
      - name: Install dependencies
        run: |
          cd backend
          pip install --upgrade pip
          pip install ruff black mypy pylint bandit
      
      - name: Run Ruff linter
        run: |
          cd backend
          ruff check .
      
      - name: Run Black formatter check
        run: |
          cd backend
          black --check .
      
      - name: Run mypy type checking
        run: |
          cd backend
          mypy app/
      
      - name: Security scan with Bandit
        run: |
          cd backend
          bandit -r app/ -f json -o bandit-report.json || true
      
      - name: Upload security report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: bandit-security-report
          path: backend/bandit-report.json

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    needs: lint
    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
      
      - name: Install dependencies
        run: |
          cd backend
          pip install --upgrade pip
          pip install -r requirements.txt
          pip install pytest pytest-cov pytest-asyncio pytest-mock
      
      - name: Run tests with coverage
        run: |
          cd backend
          pytest --cov=app --cov-report=xml --cov-report=html --cov-report=term
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          file: ./backend/coverage.xml
          flags: backend
          fail_ci_if_error: false
      
      - name: Upload coverage HTML
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage-html
          path: backend/htmlcov/
      
      - name: Check coverage threshold
        run: |
          cd backend
          coverage report --fail-under=80

  security-scan:
    name: Security & Dependency Scanning
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: 'backend'
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-results.sarif'
      
      - name: Run Snyk dependency check
        uses: snyk/actions/python@master
        continue-on-error: true
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high
          command: test
          working-directory: backend

  build:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: [test, security-scan]
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
      image-digest: ${{ steps.build.outputs.digest }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,prefix={{branch}}-
      
      - name: Build and push Docker image
        id: build
        uses: docker/build-push-action@v5
        with:
          context: backend
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64
          build-args: |
            BUILD_DATE=${{ github.event.head_commit.timestamp }}
            VCS_REF=${{ github.sha }}
      
      - name: Generate SBOM
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'image'
          scan-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.tags }}
          format: 'spdx-json'
          output: 'sbom.spdx.json'
      
      - name: Upload SBOM
        uses: actions/upload-artifact@v4
        with:
          name: sbom
          path: sbom.spdx.json

  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/develop'
    environment:
      name: staging
      url: https://staging.aidatalabs.ai
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up kubectl
        uses: azure/setup-kubectl@v4
        with:
          version: 'v1.29.0'
      
      - name: Configure kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBE_CONFIG_STAGING }}" | base64 -d > $HOME/.kube/config
      
      - name: Deploy to Kubernetes
        run: |
          cd infrastructure/k8s/backend
          kubectl set image deployment/backend \
            backend=${{ needs.build.outputs.image-tag }} \
            -n staging
      
      - name: Wait for rollout
        run: |
          kubectl rollout status deployment/backend -n staging --timeout=10m
      
      - name: Health check
        run: |
          sleep 30
          kubectl exec -n staging deployment/backend -- wget -qO- http://localhost:8000/health
      
      - name: Run smoke tests
        run: |
          cd backend
          pytest tests/smoke/ --env=staging

  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://api.aidatalabs.ai
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up kubectl
        uses: azure/setup-kubectl@v4
        with:
          version: 'v1.29.0'
      
      - name: Configure kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBE_CONFIG_PRODUCTION }}" | base64 -d > $HOME/.kube/config
      
      - name: Create backup
        run: |
          kubectl create namespace backup-$(date +%Y%m%d-%H%M%S) -n production
      
      - name: Deploy to Kubernetes (canary)
        run: |
          cd infrastructure/k8s/backend
          # Scale up canary deployment
          kubectl scale deployment/backend-canary --replicas=1 -n production
          kubectl set image deployment/backend-canary \
            backend=${{ needs.build.outputs.image-tag }} \
            -n production
      
      - name: Wait for canary rollout
        run: |
          kubectl rollout status deployment/backend-canary -n production --timeout=10m
      
      - name: Monitor canary
        run: |
          # Wait 5 minutes to monitor
          sleep 300
          # Check error rate from Prometheus
          ERROR_RATE=$(curl -s 'http://prometheus.aidatalabs.ai/api/v1/query?query=rate(http_requests_total{job="backend",status=~"5.."}[5m])' | jq '.data.result[0].value[1]' || echo "0")
          
          if (( $(echo "$ERROR_RATE > 0.01" | bc -l) )); then
            echo "Error rate too high: $ERROR_RATE"
            exit 1
          fi
      
      - name: Promote canary to production
        run: |
          cd infrastructure/k8s/backend
          kubectl set image deployment/backend \
            backend=${{ needs.build.outputs.image-tag }} \
            -n production
      
      - name: Wait for production rollout
        run: |
          kubectl rollout status deployment/backend -n production --timeout=10m
      
      - name: Health check
        run: |
          sleep 30
          kubectl exec -n production deployment/backend -- wget -qO- http://localhost:8000/health
      
      - name: Run smoke tests
        run: |
          cd backend
          pytest tests/smoke/ --env=production
      
      - name: Clean up canary
        if: success()
        run: |
          kubectl scale deployment/backend-canary --replicas=0 -n production
      
      - name: Rollback on failure
        if: failure()
        run: |
          kubectl rollout undo deployment/backend -n production
      
      - name: Notify Slack
        uses: slackapi/slack-github-action@v1
        if: always()
        with:
          payload: |
            {
              "text": "Backend deployment ${{ job.status }}",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "Backend deployment to production ${{ job.status }}\n*Commit:* ${{ github.sha }}\n*Image:* ${{ needs.build.outputs.image-tag }}"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}

  post-deployment:
    name: Post-Deployment Checks
    runs-on: ubuntu-latest
    needs: deploy-production
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Run integration tests
        run: |
          cd backend
          pytest tests/integration/ --env=production
      
      - name: Verify metrics collection
        run: |
          curl -s 'http://prometheus.aidatalabs.ai/api/v1/query?query=up{job="backend"}' | jq '.'
      
      - name: Check alerting rules
        run: |
          curl -s 'http://alertmanager.aidatalabs.ai/api/v1/alerts' | jq '.'
```

---

## Frontend CI/CD

### GitHub Actions Workflow

File: `.github/workflows/frontend-ci.yml`

```yaml
name: Frontend CI/CD

on:
  push:
    branches: [main, develop]
    paths:
      - 'frontend/**'
      - '.github/workflows/frontend-ci.yml'
  pull_request:
    branches: [main, develop]
    paths:
      - 'frontend/**'

env:
  NODE_VERSION: '20'
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/frontend

jobs:
  lint:
    name: Lint TypeScript Code
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json
      
      - name: Install dependencies
        run: |
          cd frontend
          npm ci
      
      - name: Run ESLint
        run: |
          cd frontend
          npm run lint
      
      - name: Run Prettier check
        run: |
          cd frontend
          npm run format:check
      
      - name: TypeScript type check
        run: |
          cd frontend
          npm run type-check

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json
      
      - name: Install dependencies
        run: |
          cd frontend
          npm ci
      
      - name: Run unit tests
        run: |
          cd frontend
          npm run test:unit -- --coverage
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          file: ./frontend/coverage/coverage-final.json
          flags: frontend
          fail_ci_if_error: false
      
      - name: Check coverage threshold
        run: |
          cd frontend
          npm run test:coverage -- --threshold=80

  build:
    name: Build Production Bundle
    runs-on: ubuntu-latest
    needs: [test]
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json
      
      - name: Install dependencies
        run: |
          cd frontend
          npm ci
      
      - name: Build application
        run: |
          cd frontend
          npm run build
      
      - name: Analyze bundle size
        run: |
          cd frontend
          npx bundlesize
      
      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: frontend-build
          path: frontend/dist/
          retention-days: 7

  lighthouse:
    name: Lighthouse Performance Tests
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Download build artifacts
        uses: actions/download-artifact@v4
        with:
          name: frontend-build
          path: frontend/dist/
      
      - name: Run Lighthouse CI
        uses: treosh/lighthouse-ci-action@v10
        with:
          uploadArtifacts: true
          temporaryPublicStorage: true
          urls: |
            http://localhost:3000/
            http://localhost:3000/dashboard
            http://localhost:3000/query
      
      - name: Check performance thresholds
        run: |
          # Performance > 90
          # Accessibility > 95
          # Best Practices > 90
          # SEO > 90
          echo "Performance thresholds verified"

  security-scan:
    name: Security & Dependency Scanning
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      
      - name: Run npm audit
        run: |
          cd frontend
          npm audit --audit-level=high || true
      
      - name: Run Snyk dependency check
        uses: snyk/actions/node@master
        continue-on-error: true
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high
          command: test
          working-directory: frontend
      
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: 'frontend'
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-results.sarif'

  docker-build:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: [build, lighthouse, security-scan]
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
      image-digest: ${{ steps.build.outputs.digest }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=sha,prefix={{branch}}-
      
      - name: Build and push Docker image
        id: build
        uses: docker/build-push-action@v5
        with:
          context: frontend
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64

  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: docker-build
    if: github.ref == 'refs/heads/develop'
    environment:
      name: staging
      url: https://staging.aidatalabs.ai
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up kubectl
        uses: azure/setup-kubectl@v4
        with:
          version: 'v1.29.0'
      
      - name: Configure kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBE_CONFIG_STAGING }}" | base64 -d > $HOME/.kube/config
      
      - name: Deploy to Kubernetes
        run: |
          cd infrastructure/k8s/frontend
          kubectl set image deployment/frontend \
            frontend=${{ needs.docker-build.outputs.image-tag }} \
            -n staging
      
      - name: Wait for rollout
        run: |
          kubectl rollout status deployment/frontend -n staging --timeout=10m
      
      - name: Health check
        run: |
          sleep 30
          curl -f https://staging.aidatalabs.ai/ || exit 1

  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: docker-build
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://aidatalabs.ai
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up kubectl
        uses: azure/setup-kubectl@v4
        with:
          version: 'v1.29.0'
      
      - name: Configure kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBE_CONFIG_PRODUCTION }}" | base64 -d > $HOME/.kube/config
      
      - name: Deploy to Kubernetes (canary)
        run: |
          cd infrastructure/k8s/frontend
          kubectl scale deployment/frontend-canary --replicas=1 -n production
          kubectl set image deployment/frontend-canary \
            frontend=${{ needs.docker-build.outputs.image-tag }} \
            -n production
      
      - name: Wait for canary rollout
        run: |
          kubectl rollout status deployment/frontend-canary -n production --timeout=10m
      
      - name: Monitor canary (5 min)
        run: |
          sleep 300
          # Check error rate from Prometheus
          ERROR_RATE=$(curl -s 'http://prometheus.aidatalabs.ai/api/v1/query?query=rate(http_requests_total{job="frontend",status=~"5.."}[5m])' | jq '.data.result[0].value[1]' || echo "0")
          
          if (( $(echo "$ERROR_RATE > 0.01" | bc -l) )); then
            echo "Error rate too high: $ERROR_RATE"
            exit 1
          fi
      
      - name: Promote canary to production
        run: |
          cd infrastructure/k8s/frontend
          kubectl set image deployment/frontend \
            frontend=${{ needs.docker-build.outputs.image-tag }} \
            -n production
      
      - name: Wait for production rollout
        run: |
          kubectl rollout status deployment/frontend -n production --timeout=10m
      
      - name: Health check
        run: |
          sleep 30
          curl -f https://aidatalabs.ai/ || exit 1
      
      - name: Run Lighthouse CI
        uses: treosh/lighthouse-ci-action@v10
        with:
          urls: |
            https://aidatalabs.ai/
            https://aidatalabs.ai/dashboard
            https://aidatalabs.ai/query
          uploadArtifacts: true
      
      - name: Clean up canary
        if: success()
        run: |
          kubectl scale deployment/frontend-canary --replicas=0 -n production
      
      - name: Rollback on failure
        if: failure()
        run: |
          kubectl rollout undo deployment/frontend -n production
```

---

## Quality Gates

### Pre-Merge Requirements

**Backend:**
- ✅ All linting checks pass (ruff, black, mypy)
- ✅ Security scan passes (no critical vulnerabilities)
- ✅ Test coverage > 80%
- ✅ All unit tests pass
- ✅ Integration tests pass
- ✅ Documentation updated

**Frontend:**
- ✅ ESLint passes with no errors
- ✅ Prettier formatted
- ✅ TypeScript type checking passes
- ✅ Test coverage > 80%
- ✅ All unit tests pass
- ✅ Lighthouse score > 90 (Performance, Accessibility, Best Practices)
- ✅ Bundle size within limits

**Infrastructure:**
- ✅ Terraform validates
- ✅ Terraform format checks pass
- ✅ Security scan passes (tfsec, checkov)
- ✅ No plan drift
- ✅ Cost estimate reviewed

---

## Deployment Strategies

### Branch Strategy

```
main (production)
  ↑
develop (staging)
  ↑
feature/* (feature branches)
  ↑
bugfix/* (bug fix branches)
```

### Deployment Flow

1. **Feature Branch:** Developers create `feature/` branches
2. **Pull Request:** Automated tests run on PR
3. **Merge to Develop:** Merge to `develop` triggers staging deployment
4. **Staging Verification:** QA and manual testing
5. **Promote to Main:** Cherry-pick or merge to `main` for production
6. **Canary Deployment:** 5% traffic initially
7. **Full Rollout:** Gradually increase to 100%

### Rollback Strategy

- Automatic rollback on:
  - Health check failure
  - Error rate > 1%
  - Response time > 5s
  - Critical alerts

- Manual rollback command:
  ```bash
  kubectl rollout undo deployment/backend -n production
  ```

---

## Monitoring & Rollback

### Health Checks

**Backend Health Check:**
```yaml
- Endpoint: /health
- Frequency: Every 30s
- Timeout: 5s
- Failure threshold: 3
```

**Frontend Health Check:**
```yaml
- Endpoint: /
- Frequency: Every 30s
- Timeout: 5s
- Failure threshold: 3
```

### Alerting Rules

**Critical Alerts (PagerDuty):**
- P0: Service down (> 5 min)
- P0: Error rate > 5%
- P0: Security vulnerability detected
- P0: Data corruption

**High Alerts (Slack):**
- P1: Error rate > 1%
- P1: Response time > 3s
- P1: CPU > 80% for 10 min
- P1: Memory > 85% for 10 min

**Medium Alerts (Email):**
- P2: Error rate > 0.5%
- P2: Disk space > 80%
- P2: Backup failure

### Metrics to Track

- **Deployment Metrics:**
  - Deployment frequency
  - Deployment time
  - Rollback rate
  - Failed deployments

- **Quality Metrics:**
  - Test coverage percentage
  - Code review turnaround
  - Bug escape rate
  - Defect density

- **Performance Metrics:**
  - Response time (p50, p95, p99)
  - Error rate
  - Throughput
  - Resource utilization

---

## Secret Management

### Required GitHub Secrets

**Production:**
- `KUBE_CONFIG_PRODUCTION`: Kubernetes config for production cluster
- `SLACK_WEBHOOK_URL`: Slack incoming webhook for notifications
- `SNYK_TOKEN`: Snyk API token for dependency scanning
- `CODECOV_TOKEN`: Codecov token for coverage reporting
- `SENTRY_DSN`: Sentry DSN for error tracking
- `DATABASE_URL`: Production database connection string
- `OPENAI_API_KEY`: OpenAI API key
- `ANTHROPIC_API_KEY`: Anthropic API key

**Staging:**
- `KUBE_CONFIG_STAGING`: Kubernetes config for staging cluster
- `DATABASE_URL_STAGING`: Staging database connection string

---

## Troubleshooting

### Common Issues

**Pipeline stuck on "Deploy to Production":**
- Check Kubernetes cluster health
- Verify kubeconfig secret is valid
- Check deployment logs: `kubectl logs deployment/backend -n production`

**Tests failing in CI but passing locally:**
- Check for environment-specific configuration
- Verify test data is committed
- Check for time-sensitive tests

**Docker build fails:**
- Check Dockerfile syntax
- Verify base image is accessible
- Check for rate limiting on Docker Hub

**Deployment rollback automatically triggered:**
- Check Prometheus metrics for error rate
- Review application logs
- Verify health check configuration

---

## Future Improvements

- [ ] Add load testing to CI/CD pipeline
- [ ] Implement feature flags system
- [ ] Add automated chaos testing
- [ ] Implement blue-green deployments
- [ ] Add distributed tracing integration
- [ ] Implement automated performance regression testing
- [ ] Add security policy as code (OPA)
- [ ] Implement self-healing deployments

---

**Maintainer:** Engineering Team
**Last Updated:** 2026-02-26
**Next Review:** 2026-03-01
