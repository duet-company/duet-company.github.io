#!/bin/bash
set -e

# Daily AI News HTML Generator
# Generates beautiful HTML report and publishes to here.now

DATE=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
OUTPUT_DIR="$HOME/.openclaw/workspace/ai-news-daily-page"
OUTPUT_FILE="$OUTPUT_DIR/ai-news-$DATE.html"

mkdir -p "$OUTPUT_DIR/.herenow"

echo "Generating Daily AI News HTML..." > /dev/null

# Build news content
AI_NEWS=""

# Function to add news item
add_news() {
    local emoji="$1"
    local headline="$2"
    local link="$3"
    AI_NEWS="$AI_NEWS\n$emoji $headline"
    AI_NEWS="$AI_NEWS\n   $link"
}

# Search for AI news using web_search (date-filtered)
echo "Searching for AI news from yesterday..." > /dev/null

# Get today's AI news from web_search
if command -v web_search &>/dev/null; then
    echo "Using web_search for AI news..." > /dev/null
    
    # Search queries for different categories
    SEARCH_RESULTS=""
    
    # General AI news
    if [ -n "$SEARCH_RESULTS" ]; then
        GENERAL=$(web_search --count 5 --ui_lang en --search_lang en --freshness pd "AI news today \"artificial intelligence\" announcements" 2>/dev/null || echo "")
        if [ -n "$GENERAL" ]; then
            SEARCH_RESULTS="$SEARCH_RESULTS\n$GENERAL"
            echo "Found general AI news results" > /dev/null
        fi
    fi
    
    # Product launches and models
    if [ -n "$SEARCH_RESULTS" ]; then
        PRODUCTS=$(web_search --count 3 --ui_lang en --search_lang en --freshness pd "\"new AI model\" launch release OR \"AI tool\" announced" 2>/dev/null || echo "")
        if [ -n "$PRODUCTS" ]; then
            SEARCH_RESULTS="$SEARCH_RESULTS\n$PRODUCTS"
            echo "Found AI product news" > /dev/null
        fi
    fi
    
    # Research and papers
    if [ -n "$SEARCH_RESULTS" ]; then
        RESEARCH=$(web_search --count 3 --ui_lang en --search_lang en --freshness pd "\"AI research paper\" breakthrough \"machine learning\" study" 2>/dev/null || echo "")
        if [ -n "$RESEARCH" ]; then
            SEARCH_RESULTS="$SEARCH_RESULTS\n$RESEARCH"
            echo "Found AI research news" > /dev/null
        fi
    fi
    
    # Industry and business
    if [ -n "$SEARCH_RESULTS" ]; then
        INDUSTRY=$(web_search --count 3 --ui_lang en --search_lang en --freshness pd "\"AI startup\" funding investment \"big tech\" partnership" 2>/dev/null || echo "")
        if [ -n "$INDUSTRY" ]; then
            SEARCH_RESULTS="$SEARCH_RESULTS\n$INDUSTRY"
            echo "Found AI industry news" > /dev/null
        fi
    fi
    
    # Tools and applications
    if [ -n "$SEARCH_RESULTS" ]; then
        TOOLS=$(web_search --count 2 --ui_lang en --search_lang en --freshness pd "\"AI application\" tool framework \"open source\" release" 2>/dev/null || echo "")
        if [ -n "$TOOLS" ]; then
            SEARCH_RESULTS="$SEARCH_RESULTS\n$TOOLS"
            echo "Found AI tool news" > /dev/null
        fi
    fi
    
    # Policy and ethics
    if [ -n "$SEARCH_RESULTS" ]; then
        POLICY=$(web_search --count 2 --ui_lang en --search_lang en --freshness pd "\"AI regulation\" policy safety ethics \"AI governance\" 2>/dev/null || echo "")
        if [ -n "$POLICY" ]; then
            SEARCH_RESULTS="$SEARCH_RESULTS\n$POLICY"
            echo "Found AI policy news" > /dev/null
        fi
    fi
    
    echo "Search completed. Parsing results..." > /dev/null
else
    echo "web_search not available, using placeholder content" > /dev/null
fi

# Count news items
NEWS_COUNT=$(echo "$AI_NEWS" | grep -c "🔥\|📈\|💡\|🤖" 2>/dev/null || echo "0")

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
        .news-category {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 600;
            margin-bottom: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .cat-breaking { background: var(--accent-orange); color: #000; }
        .cat-important { background: var(--accent-blue); color: #fff; }
        .cat-trend { background: var(--accent-purple); color: #fff; }
        .cat-blog { background: var(--accent-green); color: #000; }
        .news-content {
            color: var(--text-primary);
            font-size: 1rem;
            margin-bottom: 16px;
            white-space: pre-wrap;
            line-height: 1.8;
        }
        .news-content strong {
            color: var(--text-primary);
            font-weight: 600;
        }
        .news-content a {
            color: var(--accent-blue);
            text-decoration: none;
            font-weight: 500;
        }
        .news-content a:hover {
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
            .section-title { font-size: 1.3rem; }
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
                <div class="news-content">
$AI_NEWS
                </div>
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
if [ -n "$AI_NEWS" ]; then
    echo "🤖 Daily AI Report - $DATE"
    echo ""
    echo "$AI_NEWS"
    echo ""
    if [ "$URL" != "N/A" ]; then
        echo "🌐 Full Report: $URL"
    fi
else
    echo "⏳ AI news gathering in progress or no news found..."
fi
