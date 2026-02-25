#!/bin/bash
# Daily AI News Report - Using Unified Template
# Generates beautiful HTML report and publishes to here.now

set -e

# Paths
DATE=$(date +%Y-%m-%d)
TEMPLATE_DIR="$HOME/.openclaw/workspace/templates"
OUTPUT_DIR="$HOME/.openclaw/workspace/ai-news-daily-page"

# Generate HTML using unified template
bash "$TEMPLATE_DIR/generate-report.sh" ai-news "Daily AI News" "" "" "$OUTPUT_DIR" "Daily AI news briefing covering latest developments"

# Output result
if [ -f "$OUTPUT_DIR/latest-url.txt" ]; then
    URL=$(cat "$OUTPUT_DIR/latest-url.txt")
    echo "🤖 Daily AI Report - $DATE"
    echo ""
    echo "🌐 Full Report: $URL"
else
    URL="N/A"
    echo "🤖 Daily AI Report - $DATE"
    echo ""
    echo "⏳ AI news gathering in progress..."
fi
