#!/bin/bash
# Polymarket Daily Briefing - Using Unified Template
# Generates beautiful HTML report and publishes to here.now

set -e

# Paths
DATE=$(date +%Y-%m-%d)
TEMPLATE_DIR="$HOME/.openclaw/workspace/templates"
OUTPUT_DIR="$HOME/.openclaw/workspace/polymarket-daily-briefing"

# Generate HTML using unified template
bash "$TEMPLATE_DIR/generate-report.sh" polymarket-daily "Polymarket Daily Briefing" "" "$OUTPUT_DIR" "Daily briefing of trending markets and movers on Polymarket"

# Output result
if [ -f "$OUTPUT_DIR/latest-url.txt" ]; then
    URL=$(cat "$OUTPUT_DIR/latest-url.txt")
    echo "📊 POLYMARKET DAILY BRIEFING — $DATE"
    echo ""
    echo "$URL"
else
    URL="N/A"
    echo "📊 POLYMARKET DAILY BRIEFING — $DATE"
    echo ""
    echo "⏳ Generation in progress..."
fi
