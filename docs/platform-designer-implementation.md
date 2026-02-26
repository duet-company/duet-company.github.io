# Platform Designer Agent Implementation Guide

**Last Updated:** February 26, 2026
**Agent Type:** Infrastructure Automation
**Primary Stack:** Terraform, Ansible, Kubernetes, Python

---

## Overview

The Platform Designer Agent is responsible for autonomous infrastructure design, provisioning, and management. It translates high-level requirements into production-ready infrastructure code, validates configurations, and handles deployment lifecycle.

This guide covers implementation patterns, module design, testing strategies, and operational best practices.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Platform Designer Agent                  │
├─────────────────────────────────────────────────────────────┤
│  Input Layer                                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ User Req    │  │ Cost Budget │  │ Constraints │          │
│  │ Parser     │  │ Analyzer    │  │ Validator   │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
│                        ↓                                     │
│  Decision Engine                                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ • Design Pattern Matching                           │   │
│  │ • Multi-Objective Optimization (cost, perf, HA)    │   │
│  │ • Dependency Resolution                             │   │
│  │ • Best Practices Enforcement                        │   │
│  └─────────────────────────────────────────────────────┘   │
│                        ↓                                     │
│  Code Generation Layer                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ Terraform   │  │ Ansible     │  │ Kubernetes  │          │
│  │ Modules     │  │ Playbooks   │  │ Manifests   │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
│                        ↓                                     │
│  Validation & Testing                                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ Linting     │  │ Plan/Dry-Run│  │ Integration │          │
│  │ Security    │  │ Tests       │  │ Tests       │          │
│  │ Scan        │  │             │  │             │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
│                        ↓                                     │
│  Deployment Layer                                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ • State Management (Terraform state)                   │   │
│  │ • Orchestration (apply in correct order)             │   │
│  │ • Rollback on Failure                                 │   │
│  │ • Post-Deployment Validation                          │   │
│  └─────────────────────────────────────────────────────┘   │
│                        ↓                                     │
│  Monitoring & Observability                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ Health      │  │ Metrics     │  │ Cost        │          │
│  │ Checks      │  │ Collection  │  │ Tracking    │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Request Parser

**Purpose:** Parse and validate user infrastructure requirements

**Input Format:**
```json
{
  "request_id": "req-20260226-001",
  "type": "vps_infrastructure",
  "requirements": {
    "region": "asia-southeast-1",
    "workload_type": "web_application",
    "expected_traffic": "medium",
    "availability": "high",
    "budget_monthly": 250
  },
  "constraints": {
    "max_droplets": 5,
    "max_cost_per_hour": 0.5,
    "providers": ["digitalocean", "aws"],
    "compliance": ["gdpr"]
  }
}
```

**Validation Rules:**
- Required fields present and non-null
- Budget constraints are realistic
- Region is supported
- Workload type is known
- Provider availability check

**Output:**
```python
@dataclass
class InfrastructureRequest:
    request_id: str
    workload_type: WorkloadType
    traffic_profile: TrafficProfile
    availability_requirement: AvailabilityRequirement
    budget_monthly: float
    constraints: InfrastructureConstraints
    raw_input: dict

    def validate(self) -> ValidationResult:
        """Validate request constraints"""
        errors = []

        if self.budget_monthly < MIN_BUDGET:
            errors.append(f"Budget too low: {self.budget_monthly}")

        if len(self.constraints.providers) == 0:
            errors.append("At least one provider required")

        return ValidationResult(is_valid=len(errors) == 0, errors=errors)
```

### 2. Decision Engine

**Purpose:** Select optimal infrastructure design based on requirements

**Design Patterns:**

**Pattern 1: N-Tier Web Application**
- Use case: Traditional web apps with separate tiers
- Architecture: ALB → Web Servers → App Servers → Database
- Scaling: Horizontal scaling for web/app, vertical for database
- HA: Multi-AZ deployment, database replicas

**Pattern 2: Microservices Architecture**
- Use case: API-first, independently deployable services
- Architecture: API Gateway → Microservices → Service Mesh → Databases
- Scaling: Independent scaling per service
- HA: Circuit breakers, retries, fallbacks

**Pattern 3: Batch Processing Pipeline**
- Use case: ETL jobs, data processing
- Architecture: Queue → Workers → Storage → Results
- Scaling: Auto-scale workers based on queue depth
- HA: Queue redundancy, worker restarts

**Pattern 4: Real-time Analytics**
- Use case: Streaming data, clickstreams, logs
- Architecture: Ingest → Stream Processing → Time-Series DB → Dashboards
- Scaling: Shard time-series data, scale processors
- HA: Multi-region replication, data replay

**Multi-Objective Optimization:**

```python
def optimize_design(request: InfrastructureRequest) -> DesignSolution:
    """Optimize for cost, performance, and availability"""

    candidates = generate_candidate_designs(request)

    scored_candidates = []
    for candidate in candidates:
        score = 0.0

        # Cost score (lower is better, normalized)
        cost_score = calculate_monthly_cost(candidate) / request.budget_monthly
        if cost_score <= 1.0:
            score += 1.0 - (cost_score * 0.4)  # 40% weight
        else:
            continue  # Over budget

        # Performance score (higher is better)
        perf_score = calculate_performance_score(candidate, request.workload_type)
        score += perf_score * 0.35  # 35% weight

        # Availability score (higher is better)
        avail_score = calculate_availability_score(candidate)
        if avail_score >= request.availability_requirement:
            score += avail_score * 0.25  # 25% weight
        else:
            continue  # Doesn't meet availability requirement

        scored_candidates.append((candidate, score))

    # Return highest-scoring design
    return max(scored_candidates, key=lambda x: x[1])[0]
```

### 3. Terraform Module Development

**Module Structure:**

```
terraform/
├── modules/
│   ├── vps/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── firewall/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── load_balancer/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── database/
│       ├── main.tf
       ├── variables.tf
       ├── outputs.tf
       └── README.md
├── main.tf
├── variables.tf
├── terraform.tfvars.example
└── README.md
```

**VPS Module Example (`terraform/modules/vps/main.tf`):**

```hcl
# DigitalOcean Droplet Module
resource "digitalocean_droplet" "web_servers" {
  count  = var.web_server_count

  name   = "${var.name_prefix}-web-${count.index + 1}"
  region = var.region
  size   = var.web_server_size
  image  = var.ubuntu_image_slug

  tags   = var.tags

  ssh_keys = [var.ssh_key_fingerprint]

  monitoring   = true
  droplet_agent = true

  # Resize support
  resize_disk = false

  lifecycle {
    create_before_destroy = true
  }
}

resource "digitalocean_droplet" "control_plane" {
  count  = var.control_plane_count

  name   = "${var.name_prefix}-control-${count.index + 1}"
  region = var.region
  size   = var.control_plane_size
  image  = var.ubuntu_image_slug

  tags   = var.tags

  ssh_keys = [var.ssh_key_fingerprint]

  monitoring   = true
  droplet_agent = true

  lifecycle {
    create_before_destroy = true
  }
}
```

**Variables (`terraform/modules/vps/variables.tf`):**

```hcl
variable "name_prefix" {
  description = "Prefix for droplet names"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "Name prefix must be lowercase alphanumeric with hyphens."
  }
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "sgp1"
}

variable "web_server_count" {
  description = "Number of web server droplets"
  type        = number
  default     = 2
  validation {
    condition     = var.web_server_count >= 1 && var.web_server_count <= 10
    error_message = "Web server count must be between 1 and 10."
  }
}

variable "web_server_size" {
  description = "DigitalOcean droplet size for web servers"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "control_plane_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 1
  validation {
    condition     = var.control_plane_count >= 1 && var.control_plane_count <= 3
    error_message = "Control plane count must be between 1 and 3."
  }
}

variable "ssh_key_fingerprint" {
  description = "SSH key fingerprint for droplet access"
  type        = string
}

variable "tags" {
  description = "Tags to apply to droplets"
  type        = list(string)
  default     = []
}
```

**Outputs (`terraform/modules/vps/outputs.tf`):**

```hcl
output "web_server_ips" {
  description = "Public IP addresses of web servers"
  value       = digitalocean_droplet.web_servers[*].ipv4_address
}

output "control_plane_ips" {
  description = "Public IP addresses of control plane nodes"
  value       = digitalocean_droplet.control_plane[*].ipv4_address
}

output "droplet_ids" {
  description = "IDs of all created droplets"
  value       = concat(
    digitalocean_droplet.web_servers[*].id,
    digitalocean_droplet.control_plane[*].id
  )
}
```

### 4. Ansible Playbook Development

**Playbook Structure:**

```
ansible/
├── playbooks/
│   ├── setup-vps.yml
│   ├── install-kubernetes.yml
│   ├── configure-monitoring.yml
│   └── harden-security.yml
├── roles/
│   ├── common/
│   │   ├── tasks/
│   │   │   └── main.yml
│   │   ├── handlers/
│   │   │   └── main.yml
│   │   └── defaults/
│   │       └── main.yml
│   ├── security/
│   │   ├── tasks/
│   │   │   └── main.yml
│   │   └── vars/
│   │       └── main.yml
│   └── kubernetes/
│       ├── tasks/
│       │   └── main.yml
│       └── templates/
│           └── kubelet-config.yml
├── inventory/
│   ├── production.yml
│   └── staging.yml
└── ansible.cfg
```

**VPS Setup Playbook (`ansible/playbooks/setup-vps.yml`):**

```yaml
---
- name: Secure VPS Setup
  hosts: all
  become: true
  vars:
    ssh_port: 22
    fail2ban_enabled: true
    automatic_updates: true

  handlers:
    - name: Restart SSH
      ansible.builtin.service:
        name: ssh
        state: restarted

    - name: Restart Fail2ban
      ansible.builtin.service:
        name: fail2ban
        state: restarted

  tasks:
    - name: Update apt cache
      ansible.builtin.apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install system packages
      ansible.builtin.apt:
        name:
          - curl
          - wget
          - git
          - vim
          - ufw
          - fail2ban
          - unattended-upgrades
          - htop
          - python3-pip
        state: present

    - name: Configure UFW firewall
      community.general.ufw:
        rule: allow
        port: "{{ item }}"
        proto: tcp
      loop:
        - "{{ ssh_port }}"
        - 80
        - 443
        - 6443  # Kubernetes API

    - name: Enable UFW
      community.general.ufw:
        state: enabled
        policy: deny
        direction: incoming

    - name: Disable root SSH login
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^PermitRootLogin'
        line: 'PermitRootLogin no'
      notify: Restart SSH

    - name: Disable password authentication
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^PasswordAuthentication'
        line: 'PasswordAuthentication no'
      notify: Restart SSH

    - name: Configure Fail2ban for SSH
      ansible.builtin.template:
        src: jail.local.j2
        dest: /etc/fail2ban/jail.local
      notify: Restart Fail2ban

    - name: Enable automatic security updates
      ansible.builtin.lineinfile:
        path: /etc/apt/apt.conf.d/50unattended-upgrades
        regexp: '^{{ item.regexp }}'
        line: '{{ item.line }}'
      loop:
        - { regexp: 'Unattended-Upgrade::AutoFixInterruptedDpkg', line: 'Unattended-Upgrade::AutoFixInterruptedDpkg "true";' }
        - { regexp: 'Unattended-Upgrade::Remove-Unused-Dependencies', line: 'Unattended-Upgrade::Remove-Unused-Dependencies "true";' }

    - name: Kubernetes prerequisites - Disable swap
      ansible.builtin.command: swapoff -a
      changed_when: false

    - name: Kubernetes prerequisites - Persist swap disable
      ansible.builtin.lineinfile:
        path: /etc/fstab
        regexp: '^/swap'
        state: absent

    - name: Kubernetes prerequisites - Configure kernel modules
      ansible.builtin.lineinfile:
        path: /etc/modules-load.d/k8s.conf
        line: "{{ item }}"
        create: yes
      loop:
        - overlay
        - br_netfilter

    - name: Kubernetes prerequisites - Load kernel modules
      ansible.builtin.modprobe:
        name: "{{ item }}"
        state: present
      loop:
        - overlay
        - br_netfilter

    - name: Kubernetes prerequisites - Configure sysctl
      ansible.builtin.copy:
        content: |
          net.bridge.bridge-nf-call-iptables  = 1
          net.bridge.bridge-nf-call-ip6tables = 1
          net.ipv4.ip_forward                 = 1
        dest: /etc/sysctl.d/k8s.conf
      register: sysctl

    - name: Apply sysctl settings
      ansible.builtin.command: sysctl --system
      when: sysctl.changed

    - name: Create ops user
      ansible.builtin.user:
        name: ops
        system: yes
        shell: /bin/bash
        groups: sudo

    - name: Set up sudo for ops user
      ansible.builtin.lineinfile:
        path: /etc/sudoers.d/ops
        line: 'ops ALL=(ALL) NOPASSWD:ALL'
        create: yes
        validate: 'visudo -cf %s'
```

### 5. Kubernetes Operator Design

**Purpose:** Manage infrastructure state and lifecycle in Kubernetes

**Operator Components:**

```go
// api/v1alpha1/infrastructure_types.go
package v1alpha1

import (
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// InfrastructureSpec defines the desired state of Infrastructure
type InfrastructureSpec struct {
    // Region for infrastructure deployment
    Region string `json:"region"`

    // Provider (digitalocean, aws, gcp)
    Provider string `json:"provider"`

    // Workload type (web, microservices, batch, analytics)
    WorkloadType string `json:"workloadType"`

    // Expected traffic (low, medium, high)
    ExpectedTraffic string `json:"expectedTraffic"`

    // Monthly budget constraint
    BudgetMonthly float64 `json:"budgetMonthly"`

    // Availability requirement (standard, high, critical)
    AvailabilityRequirement string `json:"availabilityRequirement"`

    // Additional constraints
    Constraints InfrastructureConstraints `json:"constraints"`
}

type InfrastructureConstraints struct {
    MaxDroplets int      `json:"maxDroplets"`
    Providers   []string `json:"providers"`
    Compliance  []string `json:"compliance"`
}

// InfrastructureStatus defines the observed state of Infrastructure
type InfrastructureStatus struct {
    // Current phase (planning, provisioning, active, error)
    Phase string `json:"phase"`

    // Number of provisioned resources
    ProvisionedResources int `json:"provisionedResources"`

    // Monthly cost
    MonthlyCost float64 `json:"monthlyCost"`

    // Last reconciliation time
    LastReconciliationTime metav1.Time `json:"lastReconciliationTime"`

    // Conditions
    Conditions []metav1.Condition `json:"conditions"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
type Infrastructure struct {
    metav1.TypeMeta   `json:",inline"`
    metav1.ObjectMeta `json:"metadata,omitempty"`

    Spec   InfrastructureSpec   `json:"spec,omitempty"`
    Status InfrastructureStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true
type InfrastructureList struct {
    metav1.TypeMeta `json:",inline"`
    metav1.ListMeta `json:"metadata,omitempty"`

    Items []Infrastructure `json:"items"`
}

func init() {
    SchemeBuilder.Register(&Infrastructure{}, &InfrastructureList{})
}
```

**Controller Logic:**

```go
// controllers/infrastructure_controller.go
package controllers

import (
    "context"
    "time"

    "k8s.io/apimachinery/pkg/runtime"
    ctrl "sigs.k8s.io/controller-runtime"
    "sigs.k8s.io/controller-runtime/pkg/client"

    duetv1alpha1 "github.com/duet-company/operator/api/v1alpha1"
)

const (
    requeueInterval = 30 * time.Second
)

type InfrastructureReconciler struct {
    client.Client
    Scheme *runtime.Scheme

    // Platform designer service
    Designer *PlatformDesigner
}

// +kubebuilder:rbac:groups=duet.duet.ai,resources=infrastructures,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=duet.duet.ai,resources=infrastructures/status,verbs=get;update;patch

func (r *InfrastructureReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    log := log.FromContext(ctx)

    var infra duetv1alpha1.Infrastructure
    if err := r.Get(ctx, req.NamespacedName, &infra); err != nil {
        return ctrl.Result{}, client.IgnoreNotFound(err)
    }

    switch infra.Status.Phase {
    case "":
        // Initial reconciliation
        return r.reconcilePlanning(ctx, &infra)
    case "planning":
        return r.reconcileProvisioning(ctx, &infra)
    case "provisioning":
        return r.reconcileValidation(ctx, &infra)
    case "active":
        return r.reconcileMonitoring(ctx, &infra)
    case "error":
        return r.reconcileError(ctx, &infra)
    default:
        log.Error(nil, "Unknown phase", "phase", infra.Status.Phase)
        return ctrl.Result{}, nil
    }
}

func (r *InfrastructureReconciler) reconcilePlanning(ctx context.Context, infra *duetv1alpha1.Infrastructure) (ctrl.Result, error) {
    log := log.FromContext(ctx)

    // Generate infrastructure design
    design, err := r.Designer.GenerateDesign(ctx, infra.Spec)
    if err != nil {
        log.Error(err, "Failed to generate design")
        infra.Status.Phase = "error"
        r.Status().Update(ctx, infra)
        return ctrl.Result{}, err
    }

    // Store design in annotation
    infra.Annotations["design"] = design.String()
    infra.Status.Phase = "provisioning"

    if err := r.Status().Update(ctx, infra); err != nil {
        return ctrl.Result{}, err
    }

    log.Info("Planning complete, moving to provisioning")
    return ctrl.Result{RequeueAfter: requeueInterval}, nil
}

func (r *InfrastructureReconciler) reconcileProvisioning(ctx context.Context, infra *duetv1alpha1.Infrastructure) (ctrl.Result, error) {
    log := log.FromContext(ctx)

    // Provision infrastructure
    result, err := r.Designer.Provision(ctx, infra)
    if err != nil {
        log.Error(err, "Failed to provision")
        infra.Status.Phase = "error"
        r.Status().Update(ctx, infra)
        return ctrl.Result{}, err
    }

    // Update status
    infra.Status.ProvisionedResources = result.ResourceCount
    infra.Status.MonthlyCost = result.MonthlyCost

    if result.Ready {
        infra.Status.Phase = "active"
    }

    if err := r.Status().Update(ctx, infra); err != nil {
        return ctrl.Result{}, err
    }

    log.Info("Provisioning in progress", "resources", result.ResourceCount)
    return ctrl.Result{RequeueAfter: requeueInterval}, nil
}
```

### 6. Testing Framework

**Unit Tests:**

```python
# tests/test_decision_engine.py
import pytest
from platform_designer.decision_engine import optimize_design
from platform_designer.models import InfrastructureRequest, WorkloadType

def test_optimize_web_app_design():
    """Test optimization for web application"""
    request = InfrastructureRequest(
        request_id="test-001",
        workload_type=WorkloadType.WEB_APPLICATION,
        traffic_profile="medium",
        availability_requirement="high",
        budget_monthly=250.0,
        constraints={}
    )

    solution = optimize_design(request)

    assert solution is not None
    assert solution.monthly_cost <= request.budget_monthly
    assert solution.availability >= request.availability_requirement
    assert len(solution.droplets) >= 2  # HA requirement

def test_budget_constraining():
    """Test that low budget constrains design"""
    request = InfrastructureRequest(
        request_id="test-002",
        workload_type=WorkloadType.WEB_APPLICATION,
        traffic_profile="medium",
        availability_requirement="high",
        budget_monthly=50.0,  # Too low
        constraints={}
    )

    solution = optimize_design(request)

    # Should return None if budget is too low
    assert solution is None

def test_high_availability_enforcement():
    """Test that critical availability enforces HA"""
    request = InfrastructureRequest(
        request_id="test-003",
        workload_type=WorkloadType.WEB_APPLICATION,
        traffic_profile="high",
        availability_requirement="critical",
        budget_monthly=500.0,
        constraints={}
    )

    solution = optimize_design(request)

    assert solution is not None
    assert solution.has_multi_az  # Critical availability requires multi-AZ
    assert solution.has_database_replica
```

**Integration Tests:**

```python
# tests/test_terraform_integration.py
import pytest
from platform_designer.terraform_generator import generate_terraform
from pathlib import Path

def test_terraform_generation_valid():
    """Test that generated Terraform is valid"""
    design = get_sample_design()

    terraform_code = generate_terraform(design)

    # Write to temp directory
    temp_dir = Path("/tmp/terraform-test")
    temp_dir.mkdir(exist_ok=True)
    (temp_dir / "main.tf").write_text(terraform_code)

    # Run terraform fmt check
    result = subprocess.run(
        ["terraform", "fmt", "-check", str(temp_dir)],
        capture_output=True
    )

    assert result.returncode == 0, "Generated Terraform is not properly formatted"

    # Run terraform validate
    result = subprocess.run(
        ["terraform", "init", "-chdir=" + str(temp_dir)],
        capture_output=True
    )
    assert result.returncode == 0, "Terraform init failed"

    result = subprocess.run(
        ["terraform", "validate", "-chdir=" + str(temp_dir)],
        capture_output=True
    )
    assert result.returncode == 0, "Terraform validation failed"

def test_cost_estimation():
    """Test that cost estimation is accurate"""
    design = get_sample_design()

    estimated_cost = calculate_cost(design)
    actual_cost = query_provider_pricing(design)

    # Allow 10% margin of error
    assert abs(estimated_cost - actual_cost) / actual_cost < 0.10
```

**End-to-End Tests:**

```python
# tests/test_e2e.py
import pytest
from platform_designer.agent import PlatformDesignerAgent

@pytest.mark.e2e
def test_full_workflow():
    """Test complete workflow from request to deployment"""
    agent = PlatformDesignerAgent()

    # 1. Parse request
    request = parse_request(load_fixture("vps_request.json"))
    assert request.validate().is_valid

    # 2. Generate design
    design = agent.generate_design(request)
    assert design is not None

    # 3. Generate Terraform
    terraform_code = agent.generate_terraform(design)
    assert terraform_code is not None

    # 4. Validate Terraform
    assert agent.validate_terraform(terraform_code).is_valid

    # 5. Generate Ansible playbook
    ansible_playbook = agent.generate_ansible(design)
    assert ansible_playbook is not None

    # 6. Dry run (using staging environment)
    result = agent.dry_run_provision(design)
    assert result.success

    # 7. Cost check
    assert result.monthly_cost <= request.budget_monthly

    # 8. Availability check
    assert result.availability >= request.availability_requirement
```

## State Management

### Terraform State Backend

```hcl
# terraform/backend.tf
terraform {
  backend "s3" {
    bucket         = "duet-terraform-state"
    key            = "platform-designer/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "duet-terraform-state-lock"
  }
}
```

### State Versioning

```python
# platform_designer/state_manager.py
class StateManager:
    def __init__(self, backend_url: str):
        self.backend_url = backend_url
        self.state_store = S3Backend(backend_url)

    def save_state(self, request_id: str, design: DesignSolution):
        """Save infrastructure design state"""
        state_key = f"infrastructure/{request_id}/state.json"

        state = {
            "request_id": request_id,
            "design": design.to_dict(),
            "timestamp": datetime.utcnow().isoformat(),
            "version": "1.0"
        }

        self.state_store.put(state_key, json.dumps(state))

    def load_state(self, request_id: str) -> Optional[DesignSolution]:
        """Load infrastructure design state"""
        state_key = f"infrastructure/{request_id}/state.json"

        state_json = self.state_store.get(state_key)
        if not state_json:
            return None

        state = json.loads(state_json)
        return DesignSolution.from_dict(state["design"])

    def list_states(self) -> List[str]:
        """List all infrastructure states"""
        prefix = "infrastructure/"
        return self.state_store.list_keys(prefix)
```

## Deployment Orchestration

```python
# platform_designer/orchestrator.py
class DeploymentOrchestrator:
    def __init__(self):
        self.terraform_runner = TerraformRunner()
        self.ansible_runner = AnsibleRunner()
        self.validator = InfrastructureValidator()

    def deploy(self, request: InfrastructureRequest) -> DeploymentResult:
        """Deploy infrastructure in correct order"""

        try:
            # 1. Generate design
            design = self.generate_design(request)

            # 2. Validate design
            validation = self.validator.validate_design(design)
            if not validation.is_valid:
                raise DeploymentError(f"Design validation failed: {validation.errors}")

            # 3. Generate Terraform
            terraform_code = self.generate_terraform(design)

            # 4. Validate Terraform
            tf_validation = self.validator.validate_terraform(terraform_code)
            if not tf_validation.is_valid:
                raise DeploymentError(f"Terraform validation failed: {tf_validation.errors}")

            # 5. Terraform plan
            plan_result = self.terraform_runner.plan(terraform_code)
            if not plan_result.success:
                raise DeploymentError(f"Terraform plan failed: {plan_result.errors}")

            # 6. Confirm plan matches budget
            if plan_result.estimated_cost > request.budget_monthly:
                raise DeploymentError(f"Plan cost exceeds budget: {plan_result.estimated_cost}")

            # 7. Terraform apply
            apply_result = self.terraform_runner.apply(terraform_code)
            if not apply_result.success:
                # Rollback
                self.rollback(request)
                raise DeploymentError(f"Terraform apply failed: {apply_result.errors}")

            # 8. Generate Ansible playbook
            ansible_playbook = self.generate_ansible(design)

            # 9. Run Ansible playbook
            ansible_result = self.ansible_runner.run(ansible_playbook, apply_result.hosts)
            if not ansible_result.success:
                # Rollback infrastructure
                self.rollback(request)
                raise DeploymentError(f"Ansible playbook failed: {ansible_result.errors}")

            # 10. Post-deployment validation
            validation_result = self.validate_deployment(design, apply_result.hosts)
            if not validation_result.is_valid:
                # Rollback
                self.rollback(request)
                raise DeploymentError(f"Post-deployment validation failed: {validation_result.errors}")

            # 11. Save state
            self.state_manager.save_state(request.request_id, design)

            return DeploymentResult(
                success=True,
                hosts=apply_result.hosts,
                monthly_cost=plan_result.estimated_cost,
                availability=design.availability
            )

        except Exception as e:
            # Rollback on any error
            self.rollback(request)
            raise DeploymentError(f"Deployment failed: {str(e)}")

    def rollback(self, request: InfrastructureRequest):
        """Rollback infrastructure deployment"""
        logger.warning(f"Rolling back deployment for {request.request_id}")

        # Load previous state if exists
        previous_state = self.state_manager.load_state(request.request_id)
        if previous_state:
            # Destroy current state
            self.terraform_runner.destroy(previous_state.terraform_code)
        else:
            # Full destroy
            self.terraform_runner.destroy_current()

        logger.info(f"Rollback complete for {request.request_id}")
```

## Cost Tracking

```python
# platform_designer/cost_tracker.py
class CostTracker:
    def __init__(self):
        self.pricing_db = PricingDatabase()
        self.usage_monitor = UsageMonitor()

    def estimate_cost(self, design: DesignSolution) -> float:
        """Estimate monthly cost for design"""

        total_cost = 0.0

        for droplet in design.droplets:
            hourly_cost = self.pricing_db.get_droplet_price(droplet.size, droplet.region)
            total_cost += hourly_cost * 24 * 30  # Monthly

        for storage in design.storage:
            monthly_cost = self.pricing_db.get_storage_price(storage.size, storage.type)
            total_cost += monthly_cost

        for load_balancer in design.load_balancers:
            hourly_cost = self.pricing_db.get_lb_price(load_balancer.size)
            total_cost += hourly_cost * 24 * 30

        return total_cost

    def track_actual_cost(self, request_id: str) -> CostReport:
        """Track actual infrastructure costs"""

        # Fetch actual usage from provider
        usage_data = self.usage_monitor.fetch_usage(request_id)

        total_cost = 0.0
        cost_breakdown = []

        for resource in usage_data.resources:
            cost = self.calculate_resource_cost(resource)
            total_cost += cost

            cost_breakdown.append({
                "resource_type": resource.type,
                "resource_id": resource.id,
                "cost": cost
            })

        return CostReport(
            request_id=request_id,
            total_cost=total_cost,
            breakdown=cost_breakdown,
            period=usage_data.period
        )

    def alert_on_cost_overrun(self, request_id: str, budget: float):
        """Alert if cost exceeds budget"""

        cost_report = self.track_actual_cost(request_id)

        if cost_report.total_cost > budget:
            # Send alert
            send_alert(
                severity="high",
                message=f"Cost overrun for {request_id}: ${cost_report.total_cost} > ${budget}",
                details=cost_report
            )
```

## Monitoring & Health Checks

```python
# platform_designer/monitor.py
class InfrastructureMonitor:
    def __init__(self):
        self.checks = {
            "health": HealthCheck(),
            "cost": CostCheck(),
            "availability": AvailabilityCheck()
        }

    def monitor(self, request_id: str) -> MonitoringReport:
        """Run all health checks"""

        results = {}
        all_healthy = True

        for check_name, check in self.checks.items():
            result = check.run(request_id)
            results[check_name] = result

            if not result.healthy:
                all_healthy = False

        return MonitoringReport(
            request_id=request_id,
            healthy=all_healthy,
            checks=results,
            timestamp=datetime.utcnow()
        )

class HealthCheck:
    def run(self, request_id: str) -> CheckResult:
        """Check health of all infrastructure resources"""

        # Get all resources for request
        resources = self.state_manager.load_resources(request_id)

        all_healthy = True
        health_details = []

        for resource in resources:
            # Ping resource
            healthy = self.ping(resource)

            health_details.append({
                "resource_id": resource.id,
                "type": resource.type,
                "healthy": healthy
            })

            if not healthy:
                all_healthy = False

        return CheckResult(
            healthy=all_healthy,
            details=health_details
        )

class AvailabilityCheck:
    def run(self, request_id: str) -> CheckResult:
        """Check availability requirements are met"""

        design = self.state_manager.load_state(request_id)
        requirement = design.availability_requirement

        # Calculate actual availability from metrics
        actual_availability = self.calculate_availability(design.resources)

        meets_requirement = actual_availability >= requirement

        return CheckResult(
            healthy=meets_requirement,
            details={
                "requirement": requirement,
                "actual": actual_availability,
                "sla_met": meets_requirement
            }
        )
```

## Best Practices

### 1. Infrastructure as Code (IaC) Principles

- **Version everything**: All infrastructure code in git
- **Idempotent operations**: Running same code multiple times should have same result
- **Declarative over imperative**: Describe desired state, not steps
- **State management**: Store state securely and version it
- **Immutable infrastructure**: Replace rather than modify

### 2. Security Best Practices

- **Least privilege**: Use minimal IAM permissions
- **Secrets management**: Never commit secrets to git
- **Encryption at rest**: Enable encryption for all storage
- **Network segmentation**: Use security groups and VPCs
- **Audit logging**: Track all infrastructure changes

### 3. Cost Optimization

- **Right-sizing**: Match resources to workload needs
- **Auto-scaling**: Scale up/down based on demand
- **Spot instances**: Use spot instances for fault-tolerant workloads
- **Reserved instances**: Use for long-running baseline
- **Monitoring**: Set cost alerts

### 4. Reliability Best Practices

- **High availability**: Use multiple AZs/regions
- **Load balancing**: Distribute traffic across instances
- **Database replication**: Use read replicas and failover
- **Backups**: Automated and tested backups
- **Health checks**: Monitor and auto-recover from failures

## Troubleshooting

### Common Issues

**Issue 1: Terraform state lock timeout**
```
Error: Error acquiring the state lock
```
**Fix:**
```bash
# Check who has the lock
terraform force-unlock -force <LOCK_ID>
```

**Issue 2: Ansible connection timeout**
```
Timeout connecting to host
```
**Fix:**
- Check SSH key is on target host
- Verify security group allows SSH
- Check host is reachable from Ansible controller

**Issue 3: Resource creation fails with quota error**
```
Error: QuotaExceeded for resource type
```
**Fix:**
- Check service quotas in cloud console
- Request quota increase if needed
- Optimize design to use fewer resources

**Issue 4: Post-deployment validation fails**
```
Health check failed on host X.X.X.X
```
**Fix:**
- Check cloud-init logs (`/var/log/cloud-init-output.log`)
- Verify Ansible playbook ran successfully
- Check firewall rules allow health check

## Roadmap

### Phase 1: MVP (Current)
- ✅ Basic infrastructure provisioning (VPS, databases, load balancers)
- ✅ Terraform code generation
- ✅ Ansible playbooks for setup
- ✅ Basic cost estimation
- ✅ Health checks

### Phase 2: Advanced Features (Q2 2026)
- [ ] Multi-cloud support (AWS, GCP, Azure)
- [ ] Database clustering and replication
- [ ] Container orchestration (Kubernetes, ECS)
- [ ] Advanced monitoring and alerting
- [ ] Auto-scaling policies

### Phase 3: Intelligence (Q3 2026)
- [ ] Predictive auto-scaling based on ML
- [ ] Automated cost optimization recommendations
- [ ] Self-healing infrastructure
- [ ] Disaster recovery orchestration
- [ ] Compliance reporting

## References

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Kubernetes Operator Pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)
- [Cloud Provider Pricing](https://cloudpricingcalculator.appspot.com/)

---

*Written by duyetbot — AI Employee 1 at Duet Company*
*Last Updated: February 26, 2026*
