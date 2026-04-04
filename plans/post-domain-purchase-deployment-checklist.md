# Post-Domain-Purchase Deployment Checklist

**Purpose:** Step-by-step guide to deploy infrastructure after aidatalabs.ai domain is purchased and available.

**Prerequisites:**
- ✅ Domain aidatalabs.ai purchased and registered
- ✅ DigitalOcean API token obtained
- ✅ SSH key pair generated (private key stored locally, public key available)
- ✅ PR #22 (VPS/firewall modules) and PR #23 (DNS module) are merged

---

## Phase 1: Configure Terraform Variables

1. Copy example variables file:
   ```bash
   cd company/infrastructure/terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with actual values:
   ```hcl
   do_token          = "your-digitalocean-api-token"
   ssh_public_key    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... your-key"
   region            = "sgp1"                    # Singapore region
   droplet_size      = "s-4vcpu-8gb-amd"        # or your preferred size
   droplet_count     = 3                         # 1 control-plane + 2 workers
   domain_name       = "aidatalabs.ai"          # add this for DNS module
   ```

3. Optional DNS variables (if configuring DNS through Terraform):
   ```hcl
   # A Records (map of record name to IP)
   a_records = {
     "@"    = "YOUR_VPS_IP"      # apex/root domain
     "www"  = "YOUR_VPS_IP"
     "api"  = "YOUR_VPS_IP"
   }

   # CNAME Records (map of record name to target)
   cname_records = {
     "blog" = "github.com/duet-company.github.io"
   }

   ttl = 1800  # 30 minutes
   ```

---

## Phase 2: Initialize and Apply Terraform

1. Initialize Terraform:
   ```bash
   cd company/infrastructure/terraform
   terraform init
   ```

2. Review the plan:
   ```bash
   terraform plan -out=tfplan
   ```

   **Expected resources:**
   - DigitalOcean droplet(s) (3 total)
   - Firewall rules (SSH, HTTP, HTTPS, Kubernetes API, etc.)
   - DigitalOcean domain (if domain_name set)
   - DNS A/CNAME records (if configured)

3. Apply the plan:
   ```bash
   terraform apply tfplan
   ```

   **Wait for completion.** Record the droplet IPs from Terraform output.

---

## Phase 3: Initial Server Setup via Ansible

1. Get droplet IPs:
   ```bash
   terraform output -json | jq -r '.droplet_ips.value[]'
   ```
   Or check `terraform.tfstate`.

2. Run the setup script:
   ```bash
   cd company/infrastructure/scripts
   ./setup-vps.sh -i <control-plane-ip> -w <worker-1-ip> <worker-2-ip>
   ```

   Or manually run Ansible:
   ```bash
   ansible-playbook -i inventory.ini setup-vps.yml
   ```

   **What this does:**
   - Installs microk8s on all droplets
   - Forms Kubernetes cluster (control-plane + workers)
   - Configures kubectl access locally
   - Deploys NGINX Ingress controller
   - Sets up storage classes
   - Verifies cluster health

3. Verify cluster:
   ```bash
   kubectl get nodes
   kubectl get ns
   ```

   All nodes should be in `Ready` state.

---

## Phase 4: Deploy Platform to Kubernetes

1. Create namespace:
   ```bash
   kubectl apply -f company/infrastructure/kubernetes/namespaces.yaml
   ```

2. Deploy ClickHouse:
   ```bash
   kubectl apply -f company/infrastructure/kubernetes/pvcs.yaml
   kubectl apply -f company/infrastructure/kubernetes/clickhouse.yaml
   ```

   Wait for ClickHouse pods to be ready:
   ```bash
   kubectl wait --for=condition=ready pod -l app=clickhouse -n aidatalabs --timeout=300s
   ```

3. Deploy backend and frontend (once Docker images built and pushed):
   ```bash
   kubectl apply -f company/infrastructure/kubernetes/backend/
   kubectl apply -f company/infrastructure/kubernetes/frontend/
   ```

   **Note:** If using Helm charts (when available):
   ```bash
   helm install backend ./helm/backend
   helm install frontend ./helm/frontend
   ```

---

## Phase 5: Configure DNS and SSL

1. **If DNS configured via Terraform** (done in Phase 2):
   - Terraform already created domain zone and records
   - Wait for DNS propagation (5-30 minutes)
   - Verify: `dig aidatalabs.ai A`

2. **If manual DNS configuration needed** (DigitalOcean console):
   - Add A records pointing to load balancer IP or master node IP
   - Add CNAME for www if desired
   - Set TTL to 300 (5 min) initially

3. **SSL Certificate with Let's Encrypt:**
   - Deploy cert-manager (if not already):
     ```bash
     kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
     ```
   - Create ClusterIssuer for Let's Encrypt (staging first):
     ```yaml
     apiVersion: cert-manager.io/v1
     kind: ClusterIssuer
     metadata:
       name: letsencrypt-staging
     spec:
       acme:
         email: admin@aidatalabs.ai
         server: https://acme-staging-v2.api.letsencrypt.org/directory
         privateKeySecretRef:
           name: letsencrypt-staging-key
         solvers:
         - http01:
             ingress:
               class: nginx
     ```
   - Create Certificate resource for your domain
   - Once validated, create production ClusterIssuer and reissue

---

## Phase 6: Monitoring and Alerts

1. Access Grafana:
   ```bash
   kubectl port-forward -n monitoring svc/grafana 3000:3000
   ```
   Open http://localhost:3000
   - Default credentials: admin/admin (change immediately)

2. Verify Prometheus targets:
   ```bash
   kubectl port-forward -n monitoring svc/prometheus 9090:9090
   ```
   Open http://localhost:9090/targets
   - All targets should be `UP`

3. Test alerting:
   - Check Alertmanager: `kubectl port-forward -n monitoring svc/alertmanager 9093:9093`
   - Review firing alerts in Prometheus UI

---

## Phase 7: Final Verification

1. **Health checks:**
   ```bash
   # Backend API
   curl https://api.aidatalabs.ai/health

   # Frontend
   curl https://aidatalabs.ai

   # ClickHouse
   kubectl exec -n aidatalabs deployment/clickhouse -- clickhouse-client --query "SELECT 1"
   ```

2. **Review all components:**
   ```bash
   kubectl get all -A
   ```

3. **Check logs for errors:**
   ```bash
   kubectl logs -l app=backend -n aidatalabs --tail=100
   kubectl logs -l app=frontend -n aidatalabs --tail=100
   ```

4. **Update kanboard:**
   - Mark issue #3 (Provision VPS) as CLOSED
   - Mark issue #4 (Setup Kubernetes cluster) as CLOSED
   - Mark issue #5 (Deploy ClickHouse) as CLOSED
   - Mark issue #6 (Setup monitoring stack) as CLOSED
   - Update issue #18 (Configure domain) as IN PROGRESS → CLOSED when DNS/SSL complete

---

## Phase 8: Post-Deployment

1. **Create initial admin user** (if needed):
   ```bash
   # Via backend API or direct DB access
   curl -X POST https://api.aidatalabs.ai/api/v1/users/admin \
     -H "Content-Type: application/json" \
     -d '{"email":"admin@aidatalabs.ai","password":"CHANGE_ME"}'
   ```

2. **Secure the cluster:**
   - Review and restrict firewall rules
   - Enable audit logging
   - Implement network policies
   - Rotate all default credentials

3. **Set up backups:**
   - ClickHouse backups (if not automated)
   - PV snapshots
   - Database dumps

4. **Configure CI/CD pipeline** (if not yet):
   - GitHub Actions workflows
   - Automated image builds
   - Automated deployments on main branch push

---

## Emergency Rollback

If something goes wrong:

1. **Terraform:**
   ```bash
   terraform destroy -auto-approve
   ```
   ⚠️ This destroys ALL infrastructure. Use with caution.

2. **Kubernetes:**
   ```bash
   kubectl delete namespace aidatalabs
   kubectl delete namespace monitoring
   ```

---

## Success Criteria

- ✅ All droplets provisioned and accessible via SSH
- ✅ Kubernetes cluster healthy (all nodes Ready)
- ✅ ClickHouse cluster deployed and accepting queries
- ✅ Backend API responding on domain
- ✅ Frontend accessible via domain with valid SSL
- ✅ Monitoring dashboards showing metrics
- ✅ Alerts configured and testing

---

## Common Issues & Troubleshooting

| Issue | Solution |
|-------|----------|
| Terraform plan shows no changes | Ensure PRs #22 and #23 are merged to main |
| DigitalOcean API errors | Verify `do_token` is correct and has proper scopes |
| SSH connection refused | Verify firewall allows your IP, check droplet status |
| kubectl get nodes shows `NotReady` | Wait 5-10 minutes, check microk8s status on nodes |
| ClickHouse pods stuck in `Init` | Check PVC creation, storage class availability |
| DNS not propagating | Check domain registrar settings, use `dig` to verify |
| SSL certificate fails | Ensure HTTP-01 challenge reachable (ingress working) |
| Grafana no data | Check Prometheus service discovery, scrape configs |

---

**Next:** After successful deployment, proceed to **Phase 3: Beta Testing** per ROADMAP.md.

- Recruit first design partner
- Onboard beta users
- Gather feedback
- Iterate on platform

---

**Document Version:** 1.0  
**Last Updated:** 2026-03-26 (by duyetbot daily sync)  
**Related:** Kanboard #2, #3, #4, #5, #6, #18
