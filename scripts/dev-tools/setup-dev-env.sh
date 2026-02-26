#!/usr/bin/env bash
#
# One-Command Development Environment Setup
# ----------------------------------------
# Sets up complete local development environment for AI Data Labs
# Usage: ./setup-dev-env.sh [--skip-deps] [--skip-services]
#
# Author: duyetbot (AI Employee 1)
# Created: Feb 28, 2026
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default options
SKIP_DEPS=false
SKIP_SERVICES=false
SERVICES_ONLY=false
VERBOSE=false

# Print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Setup complete local development environment for AI Data Labs.

OPTIONS:
    --skip-deps      Skip installing system dependencies
    --skip-services  Skip starting Docker services
    --services-only  Only start services (skip setup)
    -v, --verbose    Enable verbose output
    -h, --help       Show this help message

EXAMPLES:
    $0                              # Full setup
    $0 --skip-deps                  # Skip dependency installation
    $0 --services-only              # Only start services
    $0 -v                           # Verbose setup

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --skip-services)
            SKIP_SERVICES=true
            shift
            ;;
        --services-only)
            SERVICES_ONLY=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            set -x
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            ;;
    esac
done

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            echo "debian"
        elif [ -f /etc/redhat-release ]; then
            echo "redhat"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Install system dependencies
install_dependencies() {
    log_info "Installing system dependencies..."

    OS=$(detect_os)

    case $OS in
        debian)
            log_info "Detected Debian/Ubuntu-based system"
            sudo apt-get update

            # Core dependencies
            sudo apt-get install -y \
                curl \
                wget \
                git \
                vim \
                htop \
                jq \
                tree \
                build-essential \
                pkg-config \
                libssl-dev \
                python3 \
                python3-pip \
                python3-venv \
                nodejs \
                npm

            # Install Docker if not present
            if ! command_exists docker; then
                log_info "Installing Docker..."
                curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
                sudo sh /tmp/get-docker.sh
                sudo usermod -aG docker $USER
                log_success "Docker installed (log out and back in for group changes)"
            fi

            # Install Docker Compose if not present
            if ! command_exists docker-compose; then
                log_info "Installing Docker Compose..."
                sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
            fi
            ;;

        macos)
            log_info "Detected macOS system"
            if ! command_exists brew; then
                log_error "Homebrew not found. Please install from https://brew.sh"
                exit 1
            fi

            brew install \
                curl \
                git \
                vim \
                htop \
                jq \
                tree \
                node \
                docker \
                docker-compose
            ;;

        *)
            log_warning "Unknown OS: $OS. Skipping system dependency installation."
            log_warning "Please manually install: curl, git, docker, docker-compose, node, python3"
            ;;
    esac

    log_success "System dependencies installed"
}

# Install Python dependencies
install_python_deps() {
    log_info "Setting up Python virtual environment..."

    VENV_DIR="$WORKSPACE_ROOT/.venv"

    if [ ! -d "$VENV_DIR" ]; then
        python3 -m venv "$VENV_DIR"
        log_success "Virtual environment created at $VENV_DIR"
    else
        log_info "Virtual environment already exists"
    fi

    # Activate and install requirements if requirements.txt exists
    if [ -f "$WORKSPACE_ROOT/requirements.txt" ]; then
        source "$VENV_DIR/bin/activate"
        pip install --upgrade pip
        pip install -r "$WORKSPACE_ROOT/requirements.txt"
        log_success "Python packages installed"
    fi

    # Create activation script
    cat > "$WORKSPACE_ROOT/scripts/activate-dev" << 'EOF'
#!/bin/bash
# Activate development environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$WORKSPACE_ROOT/.venv/bin/activate"
export PATH="$WORKSPACE_ROOT/scripts:$PATH"
export WORKSPACE_ROOT="$WORKSPACE_ROOT"

echo "Development environment activated"
echo "Workspace: $WORKSPACE_ROOT"
echo "Python: $(which python)"
echo "Node: $(which node)"
EOF
    chmod +x "$WORKSPACE_ROOT/scripts/activate-dev"
    log_success "Created activation script: scripts/activate-dev"
}

# Install Node.js dependencies
install_node_deps() {
    log_info "Setting up Node.js dependencies..."

    if [ -f "$WORKSPACE_ROOT/package.json" ]; then
        cd "$WORKSPACE_ROOT"
        npm install
        log_success "Node.js packages installed"
    else
        log_info "No package.json found, skipping Node.js dependencies"
    fi
}

# Create Docker Compose configuration
create_docker_compose() {
    log_info "Creating Docker Compose configuration..."

    COMPOSE_FILE="$SCRIPT_DIR/docker-compose.dev.yml"

    cat > "$COMPOSE_FILE" << 'EOF'
version: '3.8'

services:
  # ClickHouse Database
  clickhouse:
    image: clickhouse/clickhouse-server:24.3
    container_name: clickhouse-dev
    ports:
      - "8123:8123"  # HTTP interface
      - "9000:9000"  # Native interface
    environment:
      CLICKHOUSE_DB: aidadb_dev
      CLICKHOUSE_USER: dev_user
      CLICKHOUSE_PASSWORD: dev_password
      CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT: 1
    volumes:
      - clickhouse_data:/var/lib/clickhouse
      - clickhouse_logs:/var/log/clickhouse-server
    networks:
      - dev-network
    healthcheck:
      test: ["CMD", "clickhouse-client", "--query", "SELECT 1"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: redis-dev
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - dev-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Mock API Server
  mock-api:
    image: mockserver/mockserver:5.15.0
    container_name: mock-api-dev
    ports:
      - "1080:1080"
    environment:
      MOCKSERVER_INITIALIZATION_JSON_PATH: /config/expectations.json
    volumes:
      - ./mock-api-config:/config
    networks:
      - dev-network
    depends_on:
      - clickhouse
      - redis

  # PostgreSQL (for comparison/testing)
  postgres:
    image: postgres:16-alpine
    container_name: postgres-dev
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: aidadb_dev
      POSTGRES_USER: dev_user
      POSTGRES_PASSWORD: dev_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - dev-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dev_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  # pgAdmin (PostgreSQL management UI)
  pgadmin:
    image: dpage/pgadmin4:8
    container_name: pgadmin-dev
    ports:
      - "5050:80"
    environment:
      PGADMIN_DEFAULT_EMAIL: dev@aidatalabs.ai
      PGADMIN_DEFAULT_PASSWORD: dev_password
    networks:
      - dev-network
    depends_on:
      - postgres

  # Grafana (Monitoring dashboard)
  grafana:
    image: grafana/grafana:10.2.0
    container_name: grafana-dev
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    networks:
      - dev-network
    depends_on:
      - clickhouse

networks:
  dev-network:
    driver: bridge

volumes:
  clickhouse_data:
  clickhouse_logs:
  redis_data:
  postgres_data:
  grafana_data:
EOF

    log_success "Docker Compose configuration created: $COMPOSE_FILE"
}

# Create mock API configuration
create_mock_api_config() {
    log_info "Creating mock API configuration..."

    MOCK_DIR="$WORKSPACE_ROOT/mock-api-config"
    mkdir -p "$MOCK_DIR"

    cat > "$MOCK_DIR/expectations.json" << 'EOF'
[
  {
    "httpRequest": {
      "path": "/api/v1/health"
    },
    "httpResponse": {
      "statusCode": 200,
      "body": "{ \"status\": \"healthy\", \"timestamp\": \"{{now}}\" }",
      "headers": {
        "Content-Type": ["application/json"]
      }
    }
  },
  {
    "httpRequest": {
      "path": "/api/v1/query",
      "method": "POST"
    },
    "httpResponse": {
      "statusCode": 200,
      "body": "{ \"query_id\": \"mock-{{random}}\", \"status\": \"completed\", \"results\": [] }",
      "headers": {
        "Content-Type": ["application/json"]
      },
      "delay": {
        "timeUnit": "MILLISECONDS",
        "value": 100
      }
    }
  }
]
EOF

    log_success "Mock API configuration created: $MOCK_DIR/expectations.json"
}

# Create Grafana provisioning
create_grafana_config() {
    log_info "Creating Grafana provisioning configuration..."

    GRAFANA_DIR="$WORKSPACE_ROOT/grafana/provisioning/datasources"
    mkdir -p "$GRAFANA_DIR"

    cat > "$GRAFANA_DIR/clickhouse.yml" << 'EOF'
apiVersion: 1

datasources:
  - name: ClickHouse
    type: grafana-clickhouse-datasource
    url: http://clickhouse:8123
    access: proxy
    isDefault: true
    editable: true
    jsonData:
      server: clickhouse
      port: 8123
      username: dev_user
      password: dev_password
      database: aidadb_dev
EOF

    log_success "Grafana configuration created: $GRAFANA_DIR/clickhouse.yml"
}

# Create development scripts
create_dev_scripts() {
    log_info "Creating development helper scripts..."

    # Start services script
    cat > "$SCRIPT_DIR/start-services.sh" << 'EOF'
#!/usr/bin/env bash
# Start all development services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting development services..."
cd "$SCRIPT_DIR"
docker-compose -f docker-compose.dev.yml up -d

echo "Waiting for services to be healthy..."
sleep 5

echo "Services status:"
docker-compose -f docker-compose.dev.yml ps

echo ""
echo "Service URLs:"
echo "  ClickHouse: http://localhost:8123"
echo "  Redis:     localhost:6379"
echo "  Mock API:  http://localhost:1080"
echo "  PostgreSQL: localhost:5432"
echo "  pgAdmin:   http://localhost:5050"
echo "  Grafana:   http://localhost:3000 (admin/admin)"
EOF
    chmod +x "$SCRIPT_DIR/start-services.sh"

    # Stop services script
    cat > "$SCRIPT_DIR/stop-services.sh" << 'EOF'
#!/usr/bin/env bash
# Stop all development services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Stopping development services..."
cd "$SCRIPT_DIR"
docker-compose -f docker-compose.dev.yml down

echo "Services stopped"
EOF
    chmod +x "$SCRIPT_DIR/stop-services.sh"

    # Restart services script
    cat > "$SCRIPT_DIR/restart-services.sh" << 'EOF'
#!/usr/bin/env bash
# Restart all development services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Restarting development services..."
cd "$SCRIPT_DIR"
docker-compose -f docker-compose.dev.yml restart

echo "Waiting for services to be healthy..."
sleep 5

echo "Services status:"
docker-compose -f docker-compose.dev.yml ps
EOF
    chmod +x "$SCRIPT_DIR/restart-services.sh"

    # View logs script
    cat > "$SCRIPT_DIR/view-logs.sh" << 'EOF'
#!/usr/bin/env bash
# View logs for a specific service

if [ $# -eq 0 ]; then
    echo "Usage: $0 <service-name>"
    echo ""
    echo "Available services:"
    echo "  clickhouse, redis, mock-api, postgres, pgadmin, grafana"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SERVICE=$1
cd "$SCRIPT_DIR"
docker-compose -f docker-compose.dev.yml logs -f "$SERVICE"
EOF
    chmod +x "$SCRIPT_DIR/view-logs.sh"

    # Reset data script
    cat > "$SCRIPT_DIR/reset-data.sh" << 'EOF'
#!/usr/bin/env bash
# Reset all development data (WARNING: This deletes all data!)

read -p "This will delete all data in development services. Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted"
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Stopping services..."
cd "$SCRIPT_DIR"
docker-compose -f docker-compose.dev.yml down -v

echo "Starting services..."
docker-compose -f docker-compose.dev.yml up -d

echo "Waiting for services to be healthy..."
sleep 5

echo "Data reset complete"
EOF
    chmod +x "$SCRIPT_DIR/reset-data.sh"

    log_success "Development helper scripts created"
}

# Create IDE configuration recommendations
create_ide_config() {
    log_info "Creating IDE configuration recommendations..."

    # VS Code settings
    VSCODE_DIR="$WORKSPACE_ROOT/.vscode"
    mkdir -p "$VSCODE_DIR"

    cat > "$VSCODE_DIR/settings.json" << 'EOF'
{
  "editor.formatOnSave": true,
  "editor.rulers": [80, 120],
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.formatting.provider": "black",
  "files.exclude": {
    "**/.git": true,
    "**/.DS_Store": true,
    "**/__pycache__": true,
    "**/node_modules": true,
    "**/.venv": true
  },
  "search.exclude": {
    "**/.git": true,
    "**/node_modules": true,
    "**/.venv": true
  }
}
EOF

    cat > "$VSCODE_DIR/extensions.json" << 'EOF'
{
  "recommendations": [
    "ms-python.python",
    "ms-python.vscode-pylance",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "GitHub.copilot",
    "ms-vscode.docker"
  ]
}
EOF

    # Vim/Neovim config suggestion
    cat > "$WORKSPACE_ROOT/.vimrc.recommended" << 'EOF'
" Recommended .vimrc for AI Data Labs development
" Copy to ~/.vimrc to use

syntax on
filetype plugin indent on
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set number
set ruler
set cursorline
set showmatch
set incsearch
set hlsearch
set ignorecase
set smartcase
set wildmenu
set backspace=indent,eol,start
set laststatus=2

" Python specific
autocmd FileType python setlocal tabstop=4 shiftwidth=4 expandtab

" JavaScript specific
autocmd FileType javascript setlocal tabstop=2 shiftwidth=2 expandtab
autocmd FileType javascriptreact setlocal tabstop=2 shiftwidth=2 expandtab

" Markdown specific
autocmd FileType markdown setlocal wrap linebreak nolist
EOF

    log_success "IDE configuration created"
}

# Create environment file template
create_env_template() {
    log_info "Creating environment file template..."

    ENV_FILE="$WORKSPACE_ROOT/.env.dev.template"

    cat > "$ENV_FILE" << 'EOF'
# Development Environment Configuration
# Copy this to .env.dev and fill in your values

# Database Configuration
CLICKHOUSE_HOST=localhost
CLICKHOUSE_PORT=8123
CLICKHOUSE_USER=dev_user
CLICKHOUSE_PASSWORD=dev_password
CLICKHOUSE_DATABASE=aidadb_dev

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# PostgreSQL Configuration (for comparison)
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=dev_user
POSTGRES_PASSWORD=dev_password
POSTGRES_DATABASE=aidadb_dev

# API Configuration
API_HOST=localhost
API_PORT=8000
API_DEBUG=true
API_LOG_LEVEL=debug

# LLM Configuration (for AI agents)
LLM_PROVIDER=openai
LLM_API_KEY=your_api_key_here
LLM_MODEL=gpt-4
LLM_MAX_TOKENS=2000
LLM_TEMPERATURE=0.7

# Monitoring Configuration
GRAFANA_URL=http://localhost:3000
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin

# Logging Configuration
LOG_LEVEL=debug
LOG_FILE=logs/app.log
LOG_FORMAT=json
EOF

    if [ ! -f "$WORKSPACE_ROOT/.env.dev" ]; then
        cp "$ENV_FILE" "$WORKSPACE_ROOT/.env.dev"
        log_success "Environment file template created and copied to .env.dev"
    else
        log_info ".env.dev already exists, skipping template creation"
    fi
}

# Start Docker services
start_services() {
    log_info "Starting Docker services..."

    cd "$SCRIPT_DIR"

    if docker-compose -f docker-compose.dev.yml up -d; then
        log_success "Docker services started"

        # Wait for services to be healthy
        log_info "Waiting for services to be ready (this may take 30-60 seconds)..."
        sleep 10

        # Display service status
        echo ""
        echo "=========================================="
        echo "   Development Services Status"
        echo "=========================================="
        docker-compose -f docker-compose.dev.yml ps
        echo ""
        echo "=========================================="
        echo "   Service URLs & Credentials"
        echo "=========================================="
        echo "  ClickHouse:   http://localhost:8123"
        echo "                 User: dev_user / Pass: dev_password"
        echo "  Redis:        localhost:6379"
        echo "  Mock API:      http://localhost:1080"
        echo "  PostgreSQL:    localhost:5432"
        echo "                 User: dev_user / Pass: dev_password / DB: aidadb_dev"
        echo "  pgAdmin:      http://localhost:5050"
        echo "                 Email: dev@aidatalabs.ai / Pass: dev_password"
        echo "  Grafana:      http://localhost:3000"
        echo "                 User: admin / Pass: admin"
        echo "=========================================="
        echo ""
        echo "Quick commands:"
        echo "  Activate dev env: source scripts/activate-dev"
        echo "  View logs:       scripts/dev-tools/view-logs.sh <service>"
        echo "  Stop services:    scripts/dev-tools/stop-services.sh"
        echo "  Restart:          scripts/dev-tools/restart-services.sh"
        echo "  Reset data:       scripts/dev-tools/reset-data.sh"
        echo ""
    else
        log_error "Failed to start Docker services"
        exit 1
    fi
}

# Main execution
main() {
    echo ""
    echo "=========================================="
    echo "   AI Data Labs - Dev Environment Setup"
    echo "=========================================="
    echo ""

    if $SERVICES_ONLY; then
        log_info "Services-only mode: skipping setup, starting services..."
        start_services
        exit 0
    fi

    # Install dependencies
    if ! $SKIP_DEPS; then
        install_dependencies
        install_python_deps
        install_node_deps
    else
        log_info "Skipping dependency installation (--skip-deps)"
    fi

    # Create configuration files
    create_docker_compose
    create_mock_api_config
    create_grafana_config
    create_dev_scripts
    create_ide_config
    create_env_template

    echo ""
    log_success "Development environment setup complete!"
    echo ""

    # Start services
    if ! $SKIP_SERVICES; then
        start_services
    else
        log_info "Skipping service startup (--skip-services)"
        echo ""
        echo "To start services later, run:"
        echo "  $SCRIPT_DIR/start-services.sh"
    fi

    echo ""
    log_success "Setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Activate the dev environment: source $WORKSPACE_ROOT/scripts/activate-dev"
    echo "  2. Edit .env.dev with your API keys and configuration"
    echo "  3. Start developing!"
    echo ""
}

# Run main function
main "$@"
