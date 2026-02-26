#!/usr/bin/env bash
#
# Backup & Restore Automation
# ---------------------------
# Automated backup and restore for AI Data Labs infrastructure and data
# Usage: ./backup-automation.sh [backup|restore|schedule|verify] [OPTIONS]
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

# Configuration
BACKUP_ROOT="${BACKUP_ROOT:-$WORKSPACE_ROOT/backups}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$BACKUP_ROOT/backup.log"

# Create backup directory
mkdir -p "$BACKUP_ROOT"
mkdir -p "$BACKUP_ROOT/clickhouse"
mkdir -p "$BACKUP_ROOT/postgres"
mkdir -p "$BACKUP_ROOT/terraform-state"
mkdir -p "$BACKUP_ROOT/github"
mkdir -p "$BACKUP_ROOT/workspace"

# Logging functions
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log "INFO" "$1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log "SUCCESS" "$1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log "WARNING" "$1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log "ERROR" "$1"
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Check if service is healthy
check_service_health() {
    local service=$1
    local max_attempts=${2:-30}
    local attempt=0

    log_info "Checking $service health..."

    while [ $attempt -lt $max_attempts ]; do
        if docker ps --filter "name=$service-dev" --filter "status=running" | grep -q "$service-dev"; then
            # Try to connect to the service
            case $service in
                clickhouse)
                    if docker exec clickhouse-dev clickhouse-client --query "SELECT 1" &>/dev/null; then
                        return 0
                    fi
                    ;;
                postgres)
                    if docker exec postgres-dev pg_isready -U dev_user &>/dev/null; then
                        return 0
                    fi
                    ;;
            esac
        fi
        attempt=$((attempt + 1))
        sleep 2
    done

    log_error "$service is not healthy after $max_attempts attempts"
    return 1
}

# Backup ClickHouse database
backup_clickhouse() {
    log_info "Backing up ClickHouse database..."

    check_docker
    check_service_health clickhouse || exit 1

    local backup_file="$BACKUP_ROOT/clickhouse/clickhouse_backup_$TIMESTAMP.sql"
    local compressed_file="${backup_file}.gz"

    # Backup using clickhouse-client
    if docker exec clickhouse-dev clickhouse-client \
        --user dev_user \
        --password dev_password \
        --database aidadb_dev \
        --query "SELECT * FROM system.tables WHERE database = 'aidadb_dev'" \
        --format Pretty &>/dev/null; then

        # Export all tables to SQL
        log_info "Exporting ClickHouse tables..."

        # Get list of tables
        TABLES=$(docker exec clickhouse-dev clickhouse-client \
            --user dev_user \
            --password dev_password \
            --database aidadb_dev \
            --query "SHOW TABLES" \
            --format Raw 2>/dev/null || echo "")

        if [ -n "$TABLES" ]; then
            # Create backup header
            {
                echo "-- ClickHouse Backup"
                echo "-- Timestamp: $TIMESTAMP"
                echo "-- Database: aidadb_dev"
                echo ""

                # Backup each table
                for TABLE in $TABLES; do
                    log_info "  Backing up table: $TABLE"

                    echo "-- Table: $TABLE"
                    echo "DROP TABLE IF EXISTS $TABLE;"

                    # Get table structure
                    docker exec clickhouse-dev clickhouse-client \
                        --user dev_user \
                        --password dev_password \
                        --database aidadb_dev \
                        --query "SHOW CREATE TABLE $TABLE" \
                        --format Pretty 2>/dev/null || true

                    echo ""

                    # Export table data
                    docker exec clickhouse-dev clickhouse-client \
                        --user dev_user \
                        --password dev_password \
                        --database aidadb_dev \
                        --query "SELECT * FROM $TABLE FORMAT CSVWithNames" \
                        2>/dev/null || true

                    echo ""
                    echo ""
                done
            } > "$backup_file"

            # Compress backup
            gzip -f "$backup_file"

            local backup_size=$(du -h "$compressed_file" | cut -f1)
            log_success "ClickHouse backup created: $compressed_file ($backup_size)"
        else
            log_warning "No tables found in aidadb_dev database"
            touch "${backup_file}.empty"
            log_success "Created empty backup marker"
        fi
    else
        log_error "Failed to connect to ClickHouse"
        exit 1
    fi
}

# Backup PostgreSQL database
backup_postgres() {
    log_info "Backing up PostgreSQL database..."

    check_docker
    check_service_health postgres || exit 1

    local backup_file="$BACKUP_ROOT/postgres/postgres_backup_$TIMESTAMP.sql"
    local compressed_file="${backup_file}.gz"

    # Backup using pg_dump
    if docker exec postgres-dev pg_dump \
        -U dev_user \
        -d aidadb_dev \
        --no-owner \
        --no-acl \
        --format=plain \
        2>/dev/null > "$backup_file"; then

        # Compress backup
        gzip -f "$backup_file"

        local backup_size=$(du -h "$compressed_file" | cut -f1)
        log_success "PostgreSQL backup created: $compressed_file ($backup_size)"
    else
        log_error "Failed to backup PostgreSQL"
        exit 1
    fi
}

# Backup Terraform state
backup_terraform_state() {
    log_info "Backing up Terraform state..."

    local tf_state_dirs=(
        "$WORKSPACE_ROOT/infrastructure"
        "$WORKSPACE_ROOT/company"
    )

    local backup_file="$BACKUP_ROOT/terraform-state/terraform_backup_$TIMESTAMP.tar.gz"
    local files_backed=0

    # Create archive of terraform.tfstate files
    for dir in "${tf_state_dirs[@]}"; do
        if [ -d "$dir" ]; then
            find "$dir" -name "terraform.tfstate" -o -name "*.tfstate.backup" | while read -r state_file; do
                if [ -f "$state_file" ]; then
                    tar -czf "$backup_file" -C "$(dirname "$state_file")" "$(basename "$state_file")"
                    files_backed=$((files_backed + 1))
                fi
            done
        fi
    done

    if [ -f "$backup_file" ]; then
        local backup_size=$(du -h "$backup_file" | cut -f1)
        log_success "Terraform state backup created: $backup_file ($backup_size, $files_backed files)"
    else
        log_warning "No Terraform state files found"
    fi
}

# Backup GitHub repositories
backup_github_repos() {
    log_info "Backing up GitHub repositories..."

    local backup_file="$BACKUP_ROOT/github/github_repos_backup_$TIMESTAMP.tar.gz"

    # Find all git repositories and backup refs
    local repos=$(find "$WORKSPACE_ROOT" -name ".git" -type d 2>/dev/null)

    if [ -n "$repos" ]; then
        # Backup .git directories and important files
        find "$WORKSPACE_ROOT" \
            -path "$WORKSPACE_ROOT/backups" -prune -o \
            -path "$WORKSPACE_ROOT/.venv" -prune -o \
            -path "$WORKSPACE_ROOT/node_modules" -prune -o \
            -name ".git" -type d -print | while read -r gitdir; do
            repo_dir=$(dirname "$gitdir")
            repo_name=$(basename "$repo_dir")
            log_info "  Backing up: $repo_name"
        done

        tar -czf "$backup_file" \
            --exclude="$WORKSPACE_ROOT/backups" \
            --exclude="$WORKSPACE_ROOT/.venv" \
            --exclude="$WORKSPACE_ROOT/node_modules" \
            --exclude="$WORKSPACE_ROOT/.git" \
            --exclude="$WORKSPACE_ROOT/tmp" \
            "$WORKSPACE_ROOT" 2>/dev/null || true

        if [ -f "$backup_file" ]; then
            local backup_size=$(du -h "$backup_file" | cut -f1)
            log_success "GitHub repositories backup created: $backup_file ($backup_size)"
        else
            log_warning "Workspace backup failed or is empty"
        fi
    else
        log_warning "No git repositories found"
    fi
}

# Backup workspace configuration and scripts
backup_workspace_config() {
    log_info "Backing up workspace configuration..."

    local backup_file="$BACKUP_ROOT/workspace/workspace_config_backup_$TIMESTAMP.tar.gz"

    # Backup configuration files and scripts
    tar -czf "$backup_file" \
        -C "$WORKSPACE_ROOT" \
        MEMORY.md \
        USER.md \
        SOUL.md \
        AGENTS.md \
        TOOLS.md \
        HEARTBEAT.md \
        IDENTITY.md \
        scripts/ \
        plans/ \
        .openclaw/ \
        2>/dev/null || true

    if [ -f "$backup_file" ]; then
        local backup_size=$(du -h "$backup_file" | cut -f1)
        log_success "Workspace config backup created: $backup_file ($backup_size)"
    else
        log_warning "Workspace config backup failed or is empty"
    fi
}

# Clean old backups
cleanup_old_backups() {
    log_info "Cleaning up old backups (older than $BACKUP_RETENTION_DAYS days)..."

    local total_removed=0
    local total_freed=0

    # Find and remove old backups
    find "$BACKUP_ROOT" -type f -name "*.tar.gz" -mtime +$BACKUP_RETENTION_DAYS -exec rm -v {} \; 2>/dev/null | while read -r removed_file; do
        total_removed=$((total_removed + 1))
    done

    find "$BACKUP_ROOT" -type f -name "*.sql.gz" -mtime +$BACKUP_RETENTION_DAYS -exec rm -v {} \; 2>/dev/null | while read -r removed_file; do
        total_removed=$((total_removed + 1))
    done

    if [ $total_removed -gt 0 ]; then
        log_success "Removed $total_removed old backup files"
    else
        log_info "No old backups to remove"
    fi
}

# Verify backup integrity
verify_backup() {
    local backup_file=$1

    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        exit 1
    fi

    log_info "Verifying backup: $backup_file"

    # Check if gzip is valid
    if [[ "$backup_file" == *.gz ]]; then
        if gzip -t "$backup_file" 2>/dev/null; then
            log_success "Backup integrity verified (gzip)"
            return 0
        else
            log_error "Backup file is corrupted or invalid"
            return 1
        fi
    fi

    # Check if tar is valid
    if [[ "$backup_file" == *.tar.gz ]]; then
        if tar -tzf "$backup_file" > /dev/null 2>&1; then
            log_success "Backup integrity verified (tar.gz)"
            return 0
        else
            log_error "Backup archive is corrupted"
            return 1
        fi
    fi

    log_success "Backup file exists and is readable"
    return 0
}

# Restore ClickHouse database
restore_clickhouse() {
    local backup_file=$1

    log_info "Restoring ClickHouse database from: $backup_file"

    verify_backup "$backup_file" || exit 1

    check_docker
    check_service_health clickhouse || exit 1

    # Decompress if needed
    local sql_file
    if [[ "$backup_file" == *.gz ]]; then
        sql_file=$(mktemp)
        gunzip -c "$backup_file" > "$sql_file"
    else
        sql_file="$backup_file"
    fi

    # Restore database
    if docker exec -i clickhouse-dev clickhouse-client \
        --user dev_user \
        --password dev_password \
        --database aidadb_dev \
        --multiquery < "$sql_file" 2>/dev/null; then

        log_success "ClickHouse database restored successfully"
    else
        log_error "Failed to restore ClickHouse database"
        exit 1
    fi

    # Cleanup temp file
    if [ "$sql_file" != "$backup_file" ]; then
        rm -f "$sql_file"
    fi
}

# Restore PostgreSQL database
restore_postgres() {
    local backup_file=$1

    log_info "Restoring PostgreSQL database from: $backup_file"

    verify_backup "$backup_file" || exit 1

    check_docker
    check_service_health postgres || exit 1

    # Decompress if needed
    local sql_file
    if [[ "$backup_file" == *.gz ]]; then
        sql_file=$(mktemp)
        gunzip -c "$backup_file" > "$sql_file"
    else
        sql_file="$backup_file"
    fi

    # Restore database (drop existing first)
    docker exec postgres-dev dropdb -U dev_user aidadb_dev 2>/dev/null || true
    docker exec postgres-dev createdb -U dev_user aidadb_dev 2>/dev/null

    if docker exec -i postgres-dev psql \
        -U dev_user \
        -d aidadb_dev \
        < "$sql_file" 2>/dev/null; then

        log_success "PostgreSQL database restored successfully"
    else
        log_error "Failed to restore PostgreSQL database"
        exit 1
    fi

    # Cleanup temp file
    if [ "$sql_file" != "$backup_file" ]; then
        rm -f "$sql_file"
    fi
}

# Schedule automatic backups
schedule_backup() {
    log_info "Setting up automatic backup schedule..."

    local cron_file="/tmp/backup-cron.$$"
    local schedule=${1:-"0 2 * * *"}  # Default: daily at 2 AM

    # Create cron job
    cat > "$cron_file" << EOF
# AI Data Labs Automated Backups
$schedule $WORKSPACE_ROOT/scripts/dev-tools/backup-automation.sh backup-all >> $BACKUP_ROOT/backup.log 2>&1
0 3 * * 0 $WORKSPACE_ROOT/scripts/dev-tools/backup-automation.sh cleanup >> $BACKUP_ROOT/backup.log 2>&1
EOF

    # Install cron job
    if crontab -l 2>/dev/null | grep -q "backup-automation.sh"; then
        log_warning "Backup cron job already exists"
    else
        (crontab -l 2>/dev/null; cat "$cron_file") | crontab -
        log_success "Backup cron job installed"
    fi

    rm -f "$cron_file"

    log_info "Backup schedule: $schedule (daily backups at 2 AM)"
    log_info "Cleanup schedule: 0 3 * * 0 (weekly cleanup at 3 AM on Sunday)"
}

# List all backups
list_backups() {
    log_info "Listing all backups..."

    echo ""
    echo "=========================================="
    echo "   ClickHouse Backups"
    echo "=========================================="
    ls -lh "$BACKUP_ROOT/clickhouse/" 2>/dev/null | tail -n +2 || echo "No backups"

    echo ""
    echo "=========================================="
    echo "   PostgreSQL Backups"
    echo "=========================================="
    ls -lh "$BACKUP_ROOT/postgres/" 2>/dev/null | tail -n +2 || echo "No backups"

    echo ""
    echo "=========================================="
    echo "   Terraform State Backups"
    echo "=========================================="
    ls -lh "$BACKUP_ROOT/terraform-state/" 2>/dev/null | tail -n +2 || echo "No backups"

    echo ""
    echo "=========================================="
    echo "   GitHub/Workspace Backups"
    echo "=========================================="
    ls -lh "$BACKUP_ROOT/github/" "$BACKUP_ROOT/workspace/" 2>/dev/null | tail -n +2 || echo "No backups"
}

# Show usage
usage() {
    cat << EOF
Usage: $0 <command> [OPTIONS]

Commands:
    backup-all         Backup all data sources (databases, state, repos)
    backup-clickhouse  Backup ClickHouse database
    backup-postgres     Backup PostgreSQL database
    backup-terraform    Backup Terraform state
    backup-github       Backup GitHub repositories
    backup-workspace    Backup workspace configuration
    cleanup             Remove old backups (older than BACKUP_RETENTION_DAYS)
    restore-clickhouse <file>   Restore ClickHouse from backup file
    restore-postgres <file>     Restore PostgreSQL from backup file
    schedule [cron]     Schedule automatic backups (default: daily at 2 AM)
    list                List all backup files
    verify <file>       Verify backup file integrity

Environment Variables:
    BACKUP_ROOT          Backup directory (default: $WORKSPACE_ROOT/backups)
    BACKUP_RETENTION_DAYS  Backup retention in days (default: 30)

Examples:
    $0 backup-all                           # Backup everything
    $0 backup-clickhouse                    # Backup only ClickHouse
    $0 restore-clickhouse clickhouse_backup_20260228_120000.sql.gz
    $0 schedule "0 */6 * * *"              # Backup every 6 hours
    $0 list                                 # List all backups

EOF
    exit 0
}

# Main execution
case "${1:-}" in
    backup-all)
        log_info "Starting full backup..."
        backup_clickhouse
        backup_postgres
        backup_terraform_state
        backup_github_repos
        backup_workspace_config
        cleanup_old_backups
        log_success "Full backup complete!"
        ;;

    backup-clickhouse)
        backup_clickhouse
        ;;

    backup-postgres)
        backup_postgres
        ;;

    backup-terraform)
        backup_terraform_state
        ;;

    backup-github)
        backup_github_repos
        ;;

    backup-workspace)
        backup_workspace_config
        ;;

    cleanup)
        cleanup_old_backups
        ;;

    restore-clickhouse)
        if [ -z "${2:-}" ]; then
            log_error "Please specify backup file"
            usage
        fi
        restore_clickhouse "$2"
        ;;

    restore-postgres)
        if [ -z "${2:-}" ]; then
            log_error "Please specify backup file"
            usage
        fi
        restore_postgres "$2"
        ;;

    schedule)
        schedule_backup "${2:-}"
        ;;

    list)
        list_backups
        ;;

    verify)
        if [ -z "${2:-}" ]; then
            log_error "Please specify backup file to verify"
            usage
        fi
        verify_backup "$2"
        ;;

    *)
        usage
        ;;
esac
