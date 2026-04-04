#!/usr/bin/env bash

set -euo pipefail

# OpenClaw Config Backup Script
# Backs up ~/.openclaw configuration to GitHub with README status updates

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OPENCLAW_HOME="${HOME}/.openclaw"
readonly README_PATH="${OPENCLAW_HOME}/README.md"
readonly LOG_DIR="${OPENCLAW_HOME}/logs"
readonly LOG_FILE="${LOG_DIR}/backup-failures.log"
readonly GIT_REMOTE="origin"
readonly GIT_BRANCH="main"
readonly EMAIL_TO="duyet.cs@gmail.com"
readonly EMAIL_SUBJECT="❌ OpenClaw Backup Failed"

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# Logging functions
log_info() {
    echo "[INFO] $(date -u +"%Y-%m-%d %H:%M:%S UTC") $*" >&2
}

log_error() {
    echo "[ERROR] $(date -u +"%Y-%m-%d %H:%M:%S UTC") $*" >&2
}

log_failure() {
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] $*" >> "${LOG_FILE}"
}

send_failure_email() {
    local error_msg="$1"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

    log_error "Sending failure email: ${error_msg}"

    # Try to send email via gog
    if command -v gog &>/dev/null; then
        gog gmail send \
            --to "${EMAIL_TO}" \
            --subject "${EMAIL_SUBJECT}" \
            --body "Backup failed at ${timestamp}.\n\nError: ${error_msg}\n\nTried: fetch+rebase, force-with-lease, retry." \
            && log_info "Failure email sent" \
            || log_error "Failed to send email"
    else
        log_error "gog command not found, cannot send email"
    fi
}

# Get current system status
get_system_status() {
    local status=""

    # Timestamp (UTC)
    local timestamp
    timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

    # OpenClaw version
    local version="Unknown"
    if command -v openclaw &>/dev/null; then
        version=$(openclaw --version 2>/dev/null | head -1 | tr -d '\n' || echo "Unknown")
    fi

    # Cronjob status
    local cron_status="Unknown"
    if command -v openclaw &>/dev/null; then
        cron_status=$(openclaw cron list 2>/dev/null | jq -r '.jobs | length' 2>/dev/null || echo "Unknown")
    fi

    # Last commit info
    local last_commit="None"
    if git -C "${OPENCLAW_HOME}" log -1 --format="%h %ad" --date=iso &>/dev/null; then
        last_commit=$(git -C "${OPENCLAW_HOME}" log -1 --format="%h %ad" --date=iso 2>/dev/null | tr -d '\n' || echo "None")
    fi

    status="| Metric | Value |\n|--------|-------|\n| **Last Backup** | ${timestamp} |\n| **OpenClaw Version** | ${version} |\n| **Active Cronjobs** | ${cron_status} |\n| **Last Commit** | ${last_commit} |"

    echo -e "${status}"
}

# Update README.md System Status section
update_readme_status() {
    local status_table
    status_table=$(get_system_status)

    if [[ ! -f "${README_PATH}" ]]; then
        log_error "README.md not found at ${README_PATH}"
        return 1
    fi

    # Create backup of README
    cp "${README_PATH}" "${README_PATH}.bak"

    # Find the System Status section and replace it
    # Using awk to replace between "## 📊 System Status" and the next "##" or end of section
    local temp_file
    temp_file=$(mktemp)

    awk -v new_status="${status_table}" '
        BEGIN { in_section=0; printed=0 }
        /^## 📊 System Status/ {
            print;
            in_section=1;
            next
        }
        in_section && /^## / && !/^## 📊 System Status/ {
            if (!printed) {
                print new_status "\n";
                printed=1
            }
            in_section=0;
            print
            next
        }
        in_section && /^### Recent Cronjob Runs/ {
            if (!printed) {
                print new_status "\n";
                printed=1
            }
            in_section=0;
            print
            next
        }
        { print }
        END {
            if (in_section && !printed) {
                print new_status "\n"
            }
        }
    ' "${README_PATH}" > "${temp_file}"

    mv "${temp_file}" "${README_PATH}"
    log_info "README.md System Status updated"
}

# Check for git changes
check_git_changes() {
    if git -C "${OPENCLAW_HOME}" status --porcelain | grep -q .; then
        return 0  # Changes exist
    else
        return 1  # No changes
    fi
}

# Commit and push changes
commit_and_push() {
    local commit_sha

    log_info "Staging changes..."
    git -C "${OPENCLAW_HOME}" add -A

    local commit_msg="chore: auto backup $(date +%Y-%m-%d-%H%M%S)"
    log_info "Committing: ${commit_msg}"
    git -C "${OPENCLAW_HOME}" commit -m "${commit_msg}" || {
        log_error "Git commit failed"
        return 1
    }

    log_info "Pushing to ${GIT_REMOTE}/${GIT_BRANCH}..."
    if git -C "${OPENCLAW_HOME}" push "${GIT_REMOTE}" "${GIT_BRANCH}"; then
        commit_sha=$(git -C "${OPENCLAW_HOME}" rev-parse --short HEAD)
        log_info "Push successful, commit: ${commit_sha}"
        echo "💾 Backup complete: ${commit_sha}"
        return 0
    else
        log_error "Git push failed, attempting recovery..."
        return 1
    fi
}

# Try to fix git push issues
fix_git_push() {
    log_info "Checking network connectivity to github.com..."
    if ! ping -c 1 github.com &>/dev/null; then
        log_error "Network unreachable: cannot ping github.com"
        return 1
    fi

    log_info "Checking remote configuration..."
    git -C "${OPENCLAW_HOME}" remote -v

    log_info "Attempting fetch and rebase..."
    if git -C "${OPENCLAW_HOME}" fetch "${GIT_REMOTE}" "${GIT_BRANCH}"; then
        log_info "Fetch successful, attempting rebase..."
        if git -C "${OPENCLAW_HOME}" rebase "${GIT_REMOTE}/${GIT_BRANCH}"; then
            log_info "Rebase successful, retrying push..."
            if git -C "${OPENCLAW_HOME}" push "${GIT_REMOTE}" "${GIT_BRANCH}"; then
                local commit_sha
                commit_sha=$(git -C "${OPENCLAW_HOME}" rev-parse --short HEAD)
                log_info "Push successful after rebase, commit: ${commit_sha}"
                echo "💾 Backup complete (after rebase): ${commit_sha}"
                return 0
            fi
        else
            log_error "Rebase failed, aborting..."
            git -C "${OPENCLAW_HOME}" rebase --abort || true
        fi
    else
        log_error "Git fetch failed"
    fi

    log_info "Attempting force push with lease..."
    if git -C "${OPENCLAW_HOME}" push --force-with-lease "${GIT_REMOTE}" "${GIT_BRANCH}"; then
        local commit_sha
        commit_sha=$(git -C "${OPENCLAW_HOME}" rev-parse --short HEAD)
        log_info "Force push successful, commit: ${commit_sha}"
        echo "💾 Backup complete (force-with-lease): ${commit_sha}"
        return 0
    else
        log_error "Force push failed"
    fi

    log_info "Waiting 30 seconds before retry..."
    sleep 30

    log_info "Final push attempt..."
    if git -C "${OPENCLAW_HOME}" push "${GIT_REMOTE}" "${GIT_BRANCH}"; then
        local commit_sha
        commit_sha=$(git -C "${OPENCLAW_HOME}" rev-parse --short HEAD)
        log_info "Push successful on retry, commit: ${commit_sha}"
        echo "💾 Backup complete (retry): ${commit_sha}"
        return 0
    else
        log_error "All push attempts failed"
        return 1
    fi
}

# Update README with Last Backup timestamp (after successful backup)
update_last_backup_timestamp() {
    local timestamp
    timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

    # Get the commit SHA from the last commit
    local commit_sha
    commit_sha=$(git -C "${OPENCLAW_HOME}" log -1 --format="%h" 2>/dev/null || echo "??????")

    # Update the Last Backup line(s) in README
    if [[ -f "${README_PATH}" ]]; then
        # Replace entire line containing "**Last Backup**" with standard format
        # This ensures consistent spacing and includes commit SHA
        sed -i -E "/^\s*\|\s*\*\*Last Backup\*\*\s*\|/ s/.*/| **Last Backup** | ${timestamp} (${commit_sha}) |/" "${README_PATH}"

        log_info "Last Backup timestamp updated: ${timestamp} (${commit_sha})"

        # Commit and push the README update
        git -C "${OPENCLAW_HOME}" add "${README_PATH}"
        if git -C "${OPENCLAW_HOME}" diff --cached --quiet; then
            log_info "No changes to README after timestamp update"
            return 0
        fi

        git -C "${OPENCLAW_HOME}" commit -m "chore: update backup timestamp to ${timestamp}" || {
            log_error "Failed to commit README timestamp update"
            return 0  # Non-critical
        }

        log_info "Pushing README update..."
        if git -C "${OPENCLAW_HOME}" push "${GIT_REMOTE}" "${GIT_BRANCH}"; then
            log_info "README update pushed"
        else
            log_error "Failed to push README update, but backup was successful"
        fi
    fi
}

# Main execution
main() {
    log_info "Starting OpenClaw config backup..."

    # Check we're in the right directory
    if [[ ! -d "${OPENCLAW_HOME}/.git" ]]; then
        log_error "Not a git repository: ${OPENCLAW_HOME}"
        exit 1
    fi

    # Step 1: Update README status
    log_info "Updating README.md System Status..."
    if ! update_readme_status; then
        log_error "Failed to update README status"
        exit 1
    fi

    # Step 2: Check for changes
    log_info "Checking for changes..."
    if check_git_changes; then
        log_info "Changes detected, committing and pushing..."

        # Try commit and push
        if commit_and_push; then
            # Step 4: Update README Last Backup timestamp
            update_last_backup_timestamp
            exit 0
        else
            # Try to fix and retry
            log_info "Attempting recovery..."
            if fix_git_push; then
                update_last_backup_timestamp
                exit 0
            else
                local error_msg="Git push failed after all recovery attempts"
                log_failure "${error_msg}"
                send_failure_email "${error_msg}"
                echo "❌ Backup failed after all fix attempts: ${error_msg}"
                exit 1
            fi
        fi
    else
        log_info "No config changes found"
        # Still need to push the README status update if it changed
        if git -C "${OPENCLAW_HOME}" diff --quiet; then
            log_info "No changes to commit"
            echo "✅ No config changes, README status updated"
            exit 0
        else
            log_info "README status changed, committing..."
            git -C "${OPENCLAW_HOME}" add "${README_PATH}"
            git -C "${OPENCLAW_HOME}" commit -m "chore: update README status $(date +%Y-%m-%d-%H%M%S)" || {
                log_error "Failed to commit README status update"
                exit 1
            }
            if git -C "${OPENCLAW_HOME}" push "${GIT_REMOTE}" "${GIT_BRANCH}"; then
                log_info "README status update pushed"
                echo "✅ No config changes, README status updated"
                exit 0
            else
                log_error "Failed to push README status update"
                exit 1
            fi
        fi
    fi
}

main "$@"
