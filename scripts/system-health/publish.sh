#!/bin/bash
# System Health Report - Using Unified Template
# Generates beautiful HTML report and publishes to here.now

set -e

# Paths
DATE=$(date +%Y-%m-%d)
TEMPLATE_DIR="$HOME/.openclaw/workspace/templates"
OUTPUT_DIR="$HOME/.openclaw/workspace/system-health"

# Generate HTML using unified template
bash "$TEMPLATE_DIR/generate-report.sh" health "System Health" "" "$OUTPUT_DIR" "System health monitoring dashboard with metrics"

# Output result
if [ -f "$OUTPUT_DIR/latest-url.txt" ]; then
    URL=$(cat "$OUTPUT_DIR/latest-url.txt")
    echo "🏥 System Health - $DATE"
    echo ""
    echo "$URL"
else
    URL="N/A"
    echo "🏥 System Health - $DATE"
    echo ""
    echo "⏳ Generation in progress..."
fi
