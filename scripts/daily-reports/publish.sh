#!/bin/bash
# Daily Comprehensive Report - Using Unified Template
# Generates beautiful HTML report and publishes to here.now

set -e

# Paths
DATE=$(date +%Y-%m-%d)
TEMPLATE_DIR="$HOME/.openclaw/workspace/templates"
OUTPUT_DIR="$HOME/.openclaw/workspace/daily-reports"

# Generate HTML using unified template
bash "$TEMPLATE_DIR/generate-report.sh" comprehensive "Daily Comprehensive Report" "" "$OUTPUT_DIR" "Comprehensive daily report: system health, cron status, AI news, Polymarket, company progress"

# Generate telegram overview
bash "$OUTPUT_DIR/generate-telegram-overview.sh"

# Output result
if [ -f "$OUTPUT_DIR/latest-url.txt" ]; then
    URL=$(cat "$OUTPUT_DIR/latest-url.txt")
    echo "📊 DAILY COMPREHENSIVE REPORT — $DATE"
    echo ""
    echo "$URL"
else
    URL="N/A"
    echo "📊 DAILY COMPREHENSIVE REPORT — $DATE"
    echo ""
    echo "⏳ Generation in progress..."
fi
