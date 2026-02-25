#!/bin/bash
# Polymarket Weekly Digest - Using Unified Template
# Generates beautiful HTML report and publishes to here.now

set -e

# Paths
DATE=$(date +%Y-%m-%d)
TEMPLATE_DIR="$HOME/.openclaw/workspace/templates"
OUTPUT_DIR="$HOME/.openclaw/workspace/polymarket-weekly-digest"

# Generate HTML using unified template
bash "$TEMPLATE_DIR/generate-report.sh" polymarket-weekly "Polymarket Weekly Digest" "" "$OUTPUT_DIR" "Weekly digest of major categories: politics, crypto, sports"

# Output result
if [ -f "$OUTPUT_DIR/latest-url.txt" ]; then
    URL=$(cat "$OUTPUT_DIR/latest-url.txt")
    echo "📰 POLYMARKET WEEKLY DIGEST — Week of $DATE"
    echo ""
    echo "$URL"
else
    URL="N/A"
    echo "📰 POLYMARKET WEEKLY DIGEST — Week of $DATE"
    echo ""
    echo "⏳ Generation in progress..."
fi
