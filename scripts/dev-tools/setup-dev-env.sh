#!/bin/bash
set -e

# One-Command Development Environment Setup
# Sets up all required services for local development

echo "🚀 Setting up Duet Company development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker not found${NC}"
        echo "Please install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose not found${NC}"
        echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites found${NC}"
}

# Create workspace directories
create_workspace() {
    echo -e "${BLUE}Creating workspace directories...${NC}"
    
    mkdir -p ~/workspace/duet-company/{data,logs,temp,exports}
    mkdir -p ~/workspace/duet-company/certs/{clickhouse,api,gateway}
    
    echo -e "${GREEN}✅ Workspace directories created${NC}"
}

# Generate environment file
generate_env_file() {
    echo -e "${BLUE}Generating environment file...${NC}"
    
    cat > ~/workspace/duet-company/.env << EOF
# Duet Company Development Environment
# Generated: $(date +%Y-%m-%d)

# Database
CLICKHOUSE_HOST=localhost
CLICKHOUSE_PORT=8123
CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=
CLICKHOUSE_DATABASE=duet_dev

# API
API_HOST=localhost
API_PORT=8000
API_RELOAD=true
API_LOG_LEVEL=debug

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Development
DEV_HOT_RELOAD=true
DEV_LOG_SQL=true
DEV_DEBUG_MODE=true
EOF
    
    echo -e "${GREEN}✅ Environment file created${NC}"
}

# Generate docker-compose.yml
generate_docker_compose() {
    echo -e "${BLUE}Generating docker-compose.yml...${NC}"
    
    cat > ~/workspace/duet-company/docker-compose.yml << 'EOF'
version: '3.8'

services:
  # ClickHouse Database
  clickhouse:
    image: clickhouse/clickhouse-server:latest
    container_name: duet-clickhouse
    ports:
      - "8123:8123"
      - "9000:9000"
    volumes:
      - ~/workspace/duet-company/data/clickhouse:/var/lib/clickhouse
      - ~/workspace/duet-company/certs/clickhouse:/etc/clickhouse-server
    environment:
      - CLICKHOUSE_DB=duet_dev
      - CLICKHOUSE_USER=default
      - CLICKHOUSE_PASSWORD=
      - CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1
    healthcheck:
      test: ["CMD", "clickhouse-client", "--query", "SELECT 1"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - duet-network

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: duet-redis
    ports:
      - "6379:6379"
    volumes:
      - ~/workspace/duet-company/data/redis:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - duet-network

  # Mock API (for testing)
  api-mock:
    image: mockserver/mockserver:latest
    container_name: duet-api-mock
    ports:
      - "8000:8000"
    volumes:
      - ~/workspace/duet-company/temp:/tmp/mock-data
    environment:
      - MOCK_SERVER_PORT=8000
      - LOG_LEVEL=debug
    networks:
      - duet-network

  # Development Tools
  clickhouse-client:
    image: clickhouse/clickhouse-client:latest
    container_name: duet-clickhouse-client
    profiles:
      - tools
    depends_on:
      - clickhouse
    networks:
      - duet-network

networks:
  duet-network:
    driver: bridge
EOF
    
    echo -e "${GREEN}✅ docker-compose.yml created${NC}"
}

# Start services
start_services() {
    echo -e "${BLUE}Starting services...${NC}"
    
    cd ~/workspace/duet-company
    
    # Start development services
    docker-compose up -d clickhouse redis api-mock
    
    # Wait for services to be healthy
    echo -e "${YELLOW}Waiting for services to be healthy...${NC}"
    sleep 10
    
    # Check service status
    docker-compose ps
    
    echo ""
    echo -e "${GREEN}✅ Services started!${NC}"
    echo ""
    echo -e "${BLUE}Service URLs:${NC}"
    echo -e "  ClickHouse: ${GREEN}http://localhost:8123${NC}"
    echo -e "  ClickHouse Client: ${GREEN}docker-compose --profile tools run clickhouse-client${NC}"
    echo -e "  Redis: ${GREEN}http://localhost:6379${NC}"
    echo -e "  API Mock: ${GREEN}http://localhost:8000${NC}"
    echo ""
    echo -e "${BLUE}Useful commands:${NC}"
    echo -e "  View logs: ${YELLOW}docker-compose logs -f [service]${NC}"
    echo -e "  Stop all: ${YELLOW}docker-compose down${NC}"
    echo -e "  Restart: ${YELLOW}docker-compose restart [service]${NC}"
}

# Stop services
stop_services() {
    echo -e "${YELLOW}Stopping services...${NC}"
    cd ~/workspace/duet-company
    docker-compose down
    echo -e "${GREEN}✅ Services stopped${NC}"
}

# Show status
show_status() {
    echo -e "${BLUE}Development environment status:${NC}"
    cd ~/workspace/duet-company
    docker-compose ps
    
    # Show disk usage
    echo ""
    echo -e "${BLUE}Disk usage:${NC}"
    du -sh ~/workspace/duet-company/data
}

# Clean up
cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    
    # Stop all services
    docker-compose down 2>/dev/null || true
    
    # Remove containers
    docker-compose rm -f 2>/dev/null || true
    
    # Ask about data cleanup
    echo -e "${YELLOW}Remove data directories? (y/N)${NC}"
    read -r response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        rm -rf ~/workspace/duet-company/data
        echo -e "${GREEN}✅ Data directories removed${NC}"
    fi
}

# Show help
show_help() {
    cat << EOF
${BLUE}Duet Company Development Environment Setup${NC}

Usage: $0 [COMMAND] [OPTIONS]

${BLUE}Commands:${NC}
  ${GREEN}up${NC}       Start all development services
  ${GREEN}down${NC}     Stop all development services
  ${GREEN}status${NC}   Show service status
  ${GREEN}clean${NC}    Clean up containers and data
  ${GREEN}help${NC}     Show this help message
  ${GREEN}rebuild${NC}  Rebuild containers and restart

${BLUE}Examples:${NC}
  $0 up              Start ClickHouse, Redis, and API Mock
  $0 status          Check which services are running
  $0 logs api-mock  View API mock logs
  $0 down            Stop all services

${BLUE}Environment:${NC}
  Environment file: ~/workspace/duet-company/.env
  Compose file:    ~/workspace/duet-company/docker-compose.yml
  Data directory:   ~/workspace/duet-company/data/
  Logs directory:   ~/workspace/duet-company/logs/

${BLUE}Quick access:${NC}
  ClickHouse UI:  http://localhost:8123
  API Mock:       http://localhost:8000
  Redis CLI:      docker-compose exec redis redis-cli

EOF
}

# Main script logic
main() {
    case "${1:-help}" in
        up)
            check_prerequisites
            create_workspace
            generate_env_file
            generate_docker_compose
            start_services
            ;;
        down)
            stop_services
            ;;
        status)
            show_status
            ;;
        rebuild)
            docker-compose down 2>/dev/null || true
            main "up"
            ;;
        clean)
            cleanup
            ;;
        logs)
            docker-compose logs -f "${2:-}"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown command: ${1}${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
