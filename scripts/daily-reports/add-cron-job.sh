#!/bin/bash
# Add daily comprehensive report cron job

set -euo pipefail

JOBS_FILE="/root/.openclaw/cron/jobs.json"
BACKUP_FILE="${JOBS_FILE}.backup.$(date +%Y%m%d-%H%M%S)"

# Backup the original file
cp "$JOBS_FILE" "$BACKUP_FILE"

# Create new job JSON
NEW_JOB=$(cat << 'EOF'
{
  "id": "daily-comprehensive-report",
  "agentId": "main",
  "name": "daily-comprehensive-report",
  "enabled": true,
  "createdAtMs": 0,
  "updatedAtMs": 0,
  "schedule": {
    "kind": "cron",
    "expr": "30 7 * * *",
    "tz": "UTC"
  },
  "sessionTarget": "isolated",
  "wakeMode": "now",
  "payload": {
    "kind": "agentTurn",
    "message": "📊 DAILY COMPREHENSIVE REPORT\n\nGenerate comprehensive daily report with Telegram overview and detailed here.now page.\n\nWORKFLOW:\n1. Run the daily report generator script:\n   ~/.openclaw/workspace/scripts/daily-reports/generate-report.sh\n\n2. Read the generated Telegram overview:\n   cat ~/.openclaw/workspace/daily-reports/telegram-overview.md\n\n3. Send to Telegram:\n   Use message tool to send to @duyet (ID: 453193179)\n\n4. The script automatically:\n   - Collects all data (system health, cron status, AI news, Polymarket, company progress)\n   - Generates HTML report at ~/.openclaw/workspace/daily-reports/index.html\n   - Publishes to here.now with slug 'duyet-daily-report'\n   - Returns the public URL\n\nOUTPUT:\n- Send Telegram overview message\n- Include the here.now URL: https://duyet-daily-report.here.now/\n- Confirm: \"✅ Daily comprehensive report generated and published\"",
    "thinking": "low"
  },
  "delivery": {
    "mode": "none"
  },
  "state": {
    "nextRunAtMs": 0,
    "lastRunAtMs": 0,
    "lastStatus": "pending",
    "consecutiveErrors": 0
  }
}
EOF
)

# Add new job to jobs array using jq
TMP_FILE=$(mktemp)

# Add the new job and update timestamps
jq --argjson new_job "$NEW_JOB" '
  .jobs += [$new_job] |
  .jobs[-1].createdAtMs = (now * 1000 | floor) |
  .jobs[-1].updatedAtMs = (now * 1000 | floor) |
  .jobs[-1].state.nextRunAtMs = (now * 1000 | floor + 86400000)
' "$JOBS_FILE" > "$TMP_FILE"

# Validate JSON
if ! jq empty "$TMP_FILE" 2>/dev/null; then
    echo "❌ Error: Generated invalid JSON"
    mv "$BACKUP_FILE" "$JOBS_FILE"
    rm -f "$TMP_FILE"
    exit 1
fi

# Replace original file
mv "$TMP_FILE" "$JOBS_FILE"

echo "✅ Successfully added daily-comprehensive-report cron job"
echo "📅 Schedule: 7:30 AM UTC daily"
echo "📋 Backup saved to: $BACKUP_FILE"
echo ""
echo "Job will run the comprehensive report generator which:"
echo "  • Collects system health, cron status, AI news, Polymarket data, and company progress"
echo "  • Generates Telegram overview"
echo "  • Creates detailed HTML report"
echo "  • Publishes to here.now"
echo "  • Sends Telegram notification with link to detailed report"
