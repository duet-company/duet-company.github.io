#!/bin/bash
# Daily Blog Post Report - Using Unified Template
# Generates beautiful HTML report and publishes to here.now

set -e

# Paths
DATE=$(date +%Y-%m-%d)
TEMPLATE_DIR="$HOME/.openclaw/workspace/templates"
POST_FILE="$1"
POST_TITLE="$2"

# Generate HTML using unified template
bash "$TEMPLATE_DIR/generate-report.sh" blog-post "$POST_TITLE" "$POST_FILE" "$HOME/.openclaw/workspace/daily-blog-post" "Blog post from Duet Company: $POST_TITLE"

# Output result
if [ -f "$HOME/.openclaw/workspace/daily-blog-post/latest-url.txt" ]; then
    URL=$(cat "$HOME/.openclaw/workspace/daily-blog-post/latest-url.txt")
    echo "📝 New Blog Post"
    echo ""
    echo "<b>$POST_TITLE</b>"
    echo ""
    echo "📅 $DATE"
    echo ""
    echo "🌐 Read full article: $URL"
else
    URL="N/A"
    echo "📝 New Blog Post"
    echo ""
    echo "⏳ Generation in progress..."
fi
