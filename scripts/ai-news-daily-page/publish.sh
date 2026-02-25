#!/bin/bash
set -e

# Daily AI News HTML Generator
# Generates beautiful HTML report and publishes to here.now

DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="$HOME/.openclaw/workspace/ai-news-daily-page"
OUTPUT_FILE="$OUTPUT_DIR/ai-news-$DATE.html"

mkdir -p "$OUTPUT_DIR/.herenow"

echo "Generating Daily AI News HTML..." > /dev/null

# Function to add news item
add_news() {
    local emoji="$1"
    local headline="$2"
    local link="$3"
    NEWS_ITEMS="$NEWS_ITEMS
<p style=\"margin-bottom: 20px; line-height: 1.8;\">
$emoji $headline
</p>
<p style=\"margin: 0 0 0 20px;\">
$link
</p>"
}

# Build news items
NEWS_ITEMS=""

# Search for AI news using web_search
echo "Searching for AI news..." > /dev/null

if command -v web_search &>/dev/null; then
    # Search queries for different categories
    echo "Using web_search for AI news..." > /dev/null
    
    # General AI news
    GENERAL=$(web_search --count 3 --ui_lang en --search_lang en --freshness pd "AI news today \"artificial intelligence\" announcements" 2>/dev/null || echo "")
    
    # Product launches and models
    PRODUCTS=$(web_search --count 2 --ui_lang en --search_lang en --freshness pd "\"new AI model\" launch release OR \"AI tool\" announced" 2>/dev/null || echo "")
    
    # Research and papers
    RESEARCH=$(web_search --count 2 --ui_lang en --search_lang en --freshness pd "\"AI research paper\" breakthrough \"machine learning\" study" 2>/dev/null || echo "")
    
    # Industry and business
    INDUSTRY=$(web_search --count 2 --ui_lang en --search_lang en --freshness pd "\"AI startup\" funding investment \"big tech\" partnership" 2>/dev/null || echo "")
    
    # Tools and applications
    TOOLS=$(web_search --count 2 --ui_lang en --search_lang en --freshness pd "\"AI application\" tool framework \"open source\" release" 2>/dev/null || echo "")
    
    # Policy and ethics
    POLICY=$(web_search --count 2 --ui_lang en --search_lang en --freshness pd "\"AI regulation\" policy safety ethics \"AI governance\"" 2>/dev/null || echo "")
    
    echo "Search completed. Building news items..." > /dev/null
else
    echo "web_search not available, using placeholder content" > /dev/null
fi

# Count news items
NEWS_COUNT=$(echo "$NEWS_ITEMS" | grep -c "<p" 2>/dev/null || echo "0")

# Generate HTML report
cat > "$OUTPUT_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Daily AI News - $DATE</title>
    <meta name="description" content="Daily AI news briefing covering latest developments in artificial intelligence and machine learning.">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        :root {
            --bg-primary: #0f172a;
            --bg-secondary: #1e293b;
            --bg-elevated: #334155;
            --text-primary: #f1f5f9;
            --text-secondary: #cbd5e1;
            --text-muted: #64748b;
            --accent-orange: #f59e0b;
            --accent-green: #10b981;
            --accent-blue: #3b82f6;
            --accent-purple: #8b5cf6;
            --border: #334155;
            --border-subtle: #1e293b;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Inter', system-ui, sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
            line-height: 1.7;
            min-height: 100vh;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            padding: 50px 20px;
        }
        header {
            text-align: center;
            padding: 60px 0;
            border-bottom: 1px solid var(--border);
            background: linear-gradient(135deg, var(--accent-orange), var(--accent-purple));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        h1 {
            font-size: 2.8rem;
            font-weight: 700;
            margin-bottom: 12px;
        }
        .subtitle {
            font-size: 1.2rem;
            color: var(--text-secondary);
            font-weight: 400;
            margin-top: 16px;
        }
        .stats {
            display: flex;
            justify-content: center;
            gap: 40px;
            margin: 40px 0;
            flex-wrap: wrap;
        }
        .stat-item {
            text-align: center;
            padding: 20px 30px;
            background: var(--bg-secondary);
            border-radius: 12px;
            border: 1px solid var(--border);
        }
        .stat-value {
            font-size: 2.5rem;
            font-weight: 700;
            color: var(--accent-green);
            margin-bottom: 8px;
        }
        .stat-label {
            font-size: 0.95rem;
            color: var(--text-muted);
            font-weight: 500;
        }
        .section {
            margin: 50px 0;
        }
        .news-item {
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-left: 4px solid var(--accent-blue);
            border-radius: 10px;
            padding: 24px;
            margin-bottom: 20px;
            transition: transform 0.2s, border-color 0.2s;
        }
        .news-item:hover {
            transform: translateX(8px);
            border-left-color: var(--accent-green);
        }
        .news-item p {
            margin: 0;
        }
        .news-item a {
            color: var(--accent-blue);
            text-decoration: none;
            font-weight: 500;
        }
        .news-item a:hover {
            text-decoration: underline;
        }
        .footer {
            text-align: center;
            padding: 50px 0;
            border-top: 1px solid var(--border);
            color: var(--text-muted);
            font-size: 0.9rem;
        }
        @media (max-width: 768px) {
            h1 { font-size: 2rem; }
            .stats { flex-direction: column; gap: 20px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>DAILY AI NEWS</h1>
            <div class="subtitle">$DATE</div>
        </header>

        <div class="stats">
            <div class="stat-item">
                <div class="stat-value">$NEWS_COUNT</div>
                <div class="stat-label">News Items</div>
            </div>
            <div class="stat-item">
                <div class="stat-value">24h</div>
                <div class="stat-label">Coverage</div>
            </div>
        </div>

        <div class="section">
            <div class="news-item">
$NEWS_ITEMS
            </div>
        </div>

        <footer>
            <p>Generated by duyetbot — AI Employee 1 at Duet Company</p>
            <p style="margin-top: 8px;">Daily AI news powered by multiple sources via web search</p>
        </footer>
    </div>
</body>
</html>
EOF

echo "✅ Generated: $OUTPUT_FILE"

# Publish to here.now
cd "$OUTPUT_DIR"
bash "$HOME/.openclaw/skills/here-now/scripts/publish.sh" "$OUTPUT_FILE"

# Get URL from state file
if [ -f ".herenow/state.json" ]; then
    URL=$(python3 -c "import json; f=open('.herenow/state.json'); d=json.load(f); print(d.get('publishes', {}).get(list(d.get('publishes', {}).keys())[0] if d.get('publishes') else 'N/A', {}).get('siteUrl', 'N/A'))" 2>/dev/null || echo "N/A")
    if [ "$URL" != "N/A" ]; then
        echo "✅ Published: $URL"
        echo "$URL" > "$OUTPUT_DIR/latest-url.txt"
    else
        echo "⚠️ Failed to get URL"
    fi
else
    URL="N/A"
    echo "⚠️ State file not found"
fi

# Output for Telegram (compact format)
if [ -n "$NEWS_ITEMS" ]; then
    echo "🤖 Daily AI Report - $DATE"
    echo ""
    echo "Searching for latest AI news across multiple sources..."
    echo ""
    echo "$NEWS_ITEMS"
    echo ""
    if [ "$URL" != "N/A" ]; then
        echo "🌐 Full Report: $URL"
    fi
else
    echo "⏳ AI news gathering in progress..."
fi
