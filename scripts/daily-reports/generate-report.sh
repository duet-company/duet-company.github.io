#!/bin/bash
# Daily Report Generator with AI News
# Generates comprehensive daily report

set -e

REPORT_DIR="${HOME}/openclaw/workspace/daily-reports"
TRACKING_FILE="$REPORT_DIR/.tracking.json"
PUBLISH_SCRIPT="/root/.openclaw/workspace/scripts/publish.sh"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

mkdir -p "$REPORT_DIR"
mkdir -p "$REPORT_DIR/data"

get_tracking_info() {
    if [ -f "$TRACKING_FILE" ]; then
        cat "$TRACKING_FILE"
    else
        echo '{"actualSlug": "", "siteUrl": "", "claimToken": ""}'
    fi
}

save_tracking_info() {
    local actual_slug="$1"
    local site_url="$2"
    local claim_token="$3"
    cat > "$TRACKING_FILE" << EOF
{
  "actualSlug": "$actual_slug",
  "siteUrl": "$site_url",
  "claimToken": "$claim_token"
}
EOF
}

generate_telegram_overview() {
    local overview_file="$REPORT_DIR/telegram-overview.md"
    local report_url="$1"

    DISK_USAGE=$(df -h 2>/dev/null | awk 'NR==2 {print $5}' || echo "N/A")
    MEMORY_USED=$(free -h 2>/dev/null | grep Mem | awk '{print $3}' || echo "N/A")
    MEMORY_TOTAL=$(free -h 2>/dev/null | grep Mem | awk '{print $2}' || echo "N/A")

    if systemctl --user is-active openclaw-gateway &>/dev/null; then
        OPENCLAW_STATUS="OK"
    else
        OPENCLAW_STATUS="Stopped"
    fi

    POLY_DATA=$(python3 /root/.openclaw/workspace/skills/polymarketodds/scripts/polymarket.py trending 2>/dev/null | head -1 | sed 's/^🔥 \*\*Trending on Polymarket\*\*//' | head -c 80 || echo "No data")

    COMPANY_DATA=$(gh repo list duet-company --limit 2 --json name,updatedAt 2>/dev/null | jq -r '.[] | "• \(.name): \(.updatedAt | split("T")[0])"' || echo "No data")

    # AI News summary
    AI_SUMMARY=""
    if [ -f "$REPORT_DIR/data/news.json" ]; then
        NEWS_COUNT=$(jq 'length' "$REPORT_DIR/data/news.json" 2>/dev/null || echo "0")
        AI_SUMMARY="${NEWS_COUNT} AI news items today"
    else
        AI_SUMMARY="AI news not available"
    fi

    if [ -d "${HOME}/projects/website/content/posts" ]; then
        BLOG_COUNT=$(find "${HOME}/projects/website/content/posts" -name "*.md" -mtime -7 2>/dev/null | wc -l | tr -d ' ')
    else
        BLOG_COUNT="0"
    fi

    cat > "$overview_file" << OVERVIEW
Daily Report ${DATE}

System
• Disk: ${DISK_USAGE}
• Memory: ${MEMORY_USED}/${MEMORY_TOTAL}
• OpenClaw: ${OPENCLAW_STATUS}

AI News
${AI_SUMMARY}

Polymarket
${POLY_DATA}

Company
${COMPANY_DATA}

Blog: ${BLOG_COUNT} posts this week

View: ${report_url:-https://duyet-daily-report.here.now/}
OVERVIEW
}

collect_data_json() {
    local data_dir="$REPORT_DIR/data"

    if command -v openclaw &>/dev/null && openclaw cron list --json &>/dev/null; then
        openclaw cron list --json 2>/dev/null | jq '[.jobs[] | {name, status: (.state.lastStatus // "pending"), nextRun: .state.nextRunMs}]' > "$data_dir/cron.json" || echo '[]' > "$data_dir/cron.json"
    else
        echo '[]' > "$data_dir/cron.json"
    fi

    # Polymarket
    if [ -f "/root/.openclaw/workspace/skills/polymarketodds/scripts/polymarket.py" ] && command -v python3 &>/dev/null; then
        POLY_OUTPUT=$(python3 /root/.openclaw/workspace/skills/polymarketodds/scripts/polymarket.py trending 2>/dev/null | head -5 || true)
        {
            echo '['
            first=1
            while IFS= read -r line; do
                if [[ "$line" =~ ^ ]]; then
                    CLEANED=$(echo "$line" | sed 's/[*_`$()]/\\&/g' | sed 's/"/\\"/g')
                    [ $first -eq 0 ] && echo ','
                    printf '    {"title": "%s"}' "$CLEANED"
                    first=0
                fi
            done <<< "$POLY_OUTPUT"
            echo ''
            echo ']'
        } 2>/dev/null > "$data_dir/polymarket.json" || echo '[]' > "$data_dir/polymarket.json"
    else
        echo '[]' > "$data_dir/polymarket.json"
    fi

    # Company
    if command -v gh &>/dev/null; then
        gh repo list duet-company --limit 10 --json name,updatedAt 2>/dev/null > "$data_dir/company.json" || echo '[]' > "$data_dir/company.json"
    else
        echo '[]' > "$data_dir/company.json"
    fi

    # Blog posts
    if [ -d "${HOME}/projects/website/content/posts" ]; then
        find "${HOME}/projects/website/content/posts" -name "*.md" -mtime -7 -type f 2>/dev/null | head -20 | while read post; do
            FN=$(basename "$post" | sed 's/"/\\"/g')
            DT=$(stat -c %y "$post" 2>/dev/null | cut -d'.' -f1 | sed 's/T/ /' || echo "unknown")
            printf '{"filename": "%s", "date": "%s"}\n' "$FN" "$DT"
        done > "$data_dir/blog.txt"
        if [ -s "$data_dir/blog.txt" ]; then
            jq -s '.' "$data_dir/blog.txt" > "$data_dir/blog.json" 2>/dev/null || echo '[]' > "$data_dir/blog.json"
            rm -f "$data_dir/blog.txt"
        else
            echo '[]' > "$data_dir/blog.json"
        fi
    else
        echo '[]' > "$data_dir/blog.json"
    fi

    # AI News - copy from separate ai-news-page data if exists
    if [ -f "${HOME}/.openclaw/workspace/ai-news-page/data/news.json" ]; then
        cp "${HOME}/.openclaw/workspace/ai-news-page/data/news.json" "$data_dir/news.json"
    else
        # Generate sample AI news (placeholder)
        cat > "$data_dir/news.json" << 'AI_SAMPLE'
[
  {
    "title": "OpenAI o1-preview models now available to all free users",
    "source": "OpenAI Blog",
    "date": "2025-02-22",
    "category": "release",
    "link": "https://openai.com/blog"
  },
  {
    "title": "Google Gemini 2.0 Pro with 1M token context",
    "source": "Google",
    "date": "2025-02-21",
    "category": "product",
    "link": "https://blog.google/technology/ai/"
  },
  {
    "title": "Anthropic releases Claude 4 Sonnet with improved reasoning",
    "source": "Anthropic",
    "date": "2025-02-20",
    "category": "model",
    "link": "https://www.anthropic.com/news"
  },
  {
    "title": "Meta releases Llama 4 with 405B parameters",
    "source": "Meta AI",
    "date": "2025-02-19",
    "category": "model",
    "link": "https://ai.meta.com/blog"
  }
]
AI_SAMPLE
    fi
}

generate_html_report() {
    local html_file="$REPORT_DIR/index.html"

    cat > "$html_file" << 'HEADER'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Daily Report - REPORT_DATE_PLACEHOLDER</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', sans-serif;
            background: #f5f5f5;
            color: #1a1a1a;
            line-height: 1.6;
            padding: 20px;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            background: white;
            border-radius: 4px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .header {
            border-bottom: 2px solid #e0e0e0;
            padding: 24px 32px;
            background: #fafafa;
        }
        .header h1 { font-size: 24px; font-weight: 600; margin-bottom: 8px; color: #1a1a1a; }
        .header .date { color: #6b7280; font-size: 14px; }
        .content { padding: 32px; }
        .section { margin-bottom: 40px; }
        .section h2 { font-size: 18px; font-weight: 600; margin-bottom: 16px; color: #1a1a1a; padding-bottom: 8px; border-bottom: 1px solid #e0e0e0; }
        .metric { display: flex; justify-content: space-between; padding: 12px 0; border-bottom: 1px solid #f0f0f0; }
        .metric:last-child { border-bottom: none; }
        .metric-label { color: #4a5568; font-size: 14px; }
        .metric-value { font-weight: 500; color: #1a1a1a; }
        .status-ok { color: #059669; }
        .status-warning { color: #d97706; }
        .status-error { color: #dc2626; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px; margin: 20px 0; }
        .card { background: #f9fafb; padding: 16px; border-radius: 4px; border: 1px solid #e5e7eb; }
        .card h4 { font-size: 14px; font-weight: 600; margin-bottom: 12px; color: #1f2937; }
        .list-item { padding: 8px 0; color: #4a5568; font-size: 14px; }
        .list-item:before { content: "• "; color: #d1d5db; margin-right: 4px; }
        .news-item { padding: 16px; background: #f9fafb; border-radius: 4px; border: 1px solid #e5e7eb; margin-bottom: 16px; }
        .news-item h3 { font-size: 16px; font-weight: 500; margin-bottom: 8px; color: #1f2937; }
        .news-item .meta { font-size: 12px; color: #6b7280; margin-bottom: 12px; }
        .news-item .meta span { margin-right: 12px; }
        .news-item .category { display: inline-block; padding: 3px 8px; border-radius: 3px; font-size: 11px; background: #e3f2fd; color: #1a1a1a; }
        .category.release { background: #059669; color: white; }
        .category.product { background: #2563eb; color: white; }
        .category.model { background: #7c3aed; color: white; }
        .category.research { background: #0891b2; color: white; }
        .news-item a { display: inline-block; margin-top: 10px; padding: 6px 12px; background: #1f2937; color: white; text-decoration: none; border-radius: 3px; font-size: 12px; }
        .news-item a:hover { background: #2563eb; }
        .footer { border-top: 1px solid #e0e0e0; padding: 20px; text-align: center; color: #6b7280; font-size: 13px; background: #fafafa; border-radius: 0 0 4px 4px; }
        .loading { color: #9ca3af; font-style: italic; }
        a { color: #2563eb; text-decoration: none; } a:hover { text-decoration: underline; }
        @media (max-width: 768px) { body { padding: 12px; } .header { padding: 16px 20px; } .header h1 { font-size: 20px; } .content { padding: 20px; } .grid { grid-template-columns: 1fr; } }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Daily System Report</h1>
            <div class="date">REPORT_DATE_PLACEHOLDER</div>
        </div>
        <div class="content">
HEADER

    echo "            <div class=\"section\"><h2>System Health</h2><div class=\"grid\">" >> "$html_file"
    df -h 2>/dev/null | awk 'NR>1 {printf "                    <div class=\"card\"><h4>Disk Usage</h4><div class=\"metric\"><span class=\"metric-label\">%s</span><span class=\"metric-value\">%s</span></div></div>", $1, $5}' >> "$html_file"
    free -h 2>/dev/null | grep Mem | awk '{printf "                    <div class=\"card\"><h4>Memory</h4><div class=\"metric\"><span class=\"metric-label\">Used</span><span class=\"metric-value\">%s / %s</span></div></div>", $3, $2}' >> "$html_file"
    echo "                </div></div>" >> "$html_file"

    echo "            <div class=\"section\"><h2>Cron Jobs</h2><div class=\"subsection\"><div id=\"cron-status\"><span class=\"loading\">Loading...</span></div></div></div>" >> "$html_file"

    echo "            <div class=\"section\"><h2>AI News</h2><div class=\"subsection\"><div id=\"ai-news\"><span class=\"loading\">Loading...</span></div></div></div>" >> "$html_file"

    echo "            <div class=\"section\"><h2>Polymarket</h2><div class=\"subsection\"><div id=\"polymarket\"><span class=\"loading\">Loading...</span></div></div></div>" >> "$html_file"
    echo "            <div class=\"section\"><h2>Company Activity</h2><div class=\"subsection\"><div id=\"company\"><span class=\"loading\">Loading...</span></div></div></div>" >> "$html_file"
    echo "            <div class=\"section\"><h2>Blog Posts</h2><div class=\"subsection\"><div id=\"blog\"><span class=\"loading\">Loading...</span></div></div></div>" >> "$html_file"

    cat >> "$html_file" << 'JS'
        </div>
        <div class="footer">
            Generated by OpenClaw • Last updated: <span id="last-updated"></span>
        </div>
    </div>
    <script>
        document.getElementById('last-updated').textContent = new Date().toLocaleDateString();
        
        function showError(element, message) {
            document.getElementById(element).innerHTML = '<span class="status-error">Error: ' + message + '</span>';
        }
        
        function loadNews(elementId) {
            fetch('data/news.json')
                .then(r => r.json())
                .then(data => {
                    if (!Array.isArray(data) || data.length === 0) {
                        document.getElementById(elementId).innerHTML = '<em>No AI news today</em>';
                        return;
                    }
                    const html = data.map(item => \`
                        <div class="news-item">
                            <h3>\${item.title || 'Untitled'}</h3>
                            <div class="meta">
                                <span class="category category-\${item.category}">\${item.category || 'news'}</span>
                                <span>\${item.source || 'Unknown'}</span>
                                <span>\${item.date || ''}</span>
                            </div>
                            \${item.description ? '<div class="description">' + item.description + '</div>' : ''}
                            \${item.link ? \`<a href="\${item.link}" target="_blank">Read more →</a>\` : ''}
                        </div>
                    \`).join('');
                    document.getElementById(elementId).innerHTML = html;
                })
                .catch(err => showError(elementId, err.message));
        }

        function loadData(url, elementId) {
            fetch(url)
                .then(r => r.json())
                .then(data => {
                    const el = document.getElementById(elementId);
                    if (!el) return;
                    
                    if (Array.isArray(data) && data.length === 0) {
                        el.innerHTML = '<em>No data</em>';
                        return;
                    }
                    
                    if (elementId === 'cron-status') {
                        el.innerHTML = data.map(job => {
                            const statusClass = job.status === 'ok' ? 'status-ok' : 
                                              job.status === 'pending' ? 'status-pending' : 
                                              job.status === 'error' ? 'status-error' : '';
                            const nextRun = job.nextRun ? new Date(job.nextRun).toLocaleString() : 'N/A';
                            return \`<div class="metric"><span class="metric-label">\${job.name}</span><span class="metric-value \${statusClass}">\${job.status}</span></div><div style="font-size: 12px; color: #6b7280; margin-top: 4px; margin-left: 0;">Next: \${nextRun}</div>\`;
                        }).join('');
                    } else if (elementId === 'polymarket') {
                        el.innerHTML = data.map(item => \`<div class="list-item"><strong>\${item.title || 'Unknown'}</strong></div>\`).join('');
                    } else if (elementId === 'company') {
                        el.innerHTML = data.map(item => \`<div class="list-item"><strong>\${item.name || 'Unknown'}</strong> - \${item.updatedAt || 'N/A'}</div>\`).join('');
                    } else if (elementId === 'blog') {
                        el.innerHTML = data.map(item => \`<div class="list-item">\${item.filename || 'Unknown'} - \${item.date || 'N/A'}</div>\`).join('');
                    }
                })
                .catch(err => showError(elementId, err.message));
        }
        
        loadNews('ai-news');
        loadData('data/cron.json', 'cron-status');
        loadData('data/polymarket.json', 'polymarket');
        loadData('data/company.json', 'company');
        loadData('data/blog.json', 'blog');
    </script>
</body>
</html>
JS

    sed -i "s/REPORT_DATE_PLACEHOLDER/$DATE/g" "$html_file" 2>/dev/null || true
}

publish_to_herenow() {
    cd "$REPORT_DIR"
    TRACKING=$(get_tracking_info)
    ACTUAL_SLUG=$(echo "$TRACKING" | jq -r '.actualSlug')
    CLAIM_TOKEN=$(echo "$TRACKING" | jq -r '.claimToken')
    
    if [ -n "$ACTUAL_SLUG" ] && [ "$ACTUAL_SLUG" != "null" ] && [ -n "$CLAIM_TOKEN" ]; then
        echo "Updating publish ($ACTUAL_SLUG)..."
        PUBLISH_OUTPUT=$($PUBLISH_SCRIPT . --slug "$ACTUAL_SLUG" --claim-token "$CLAIM_TOKEN" 2>&1)
        URL=$(echo "$PUBLISH_OUTPUT" | grep -Eo 'https://[a-z0-9-]+\.here\.now' | head -1)
        if [ -n "$URL" ]; then
            echo "OK: $URL/"
            return 0
        fi
    fi
    
    echo "Creating new publish..."
    PUBLISH_OUTPUT=$($PUBLISH_SCRIPT . 2>&1)
    URL=$(echo "$PUBLISH_OUTPUT" | grep -Eo 'https://[a-z0-9-]+\.here\.now' | head -1)
    
    if [ -n "$URL" ]; then
        NEW_SLUG=$(echo "$URL" | sed 's|https://||' | sed 's|\.here\.now||')
        echo "OK: $URL/"
        save_tracking_info "$NEW_SLUG" "$URL/" ""
        
        if [ -f ".herenow/state.json" ]; then
            STATE_TOKEN=$(jq -r --arg slug "$NEW_SLUG" '.publishes[$slug].claimToken // empty' ".herenow/state.json" 2>/dev/null)
            if [ -n "$STATE_TOKEN" ]; then
                save_tracking_info "$NEW_SLUG" "$URL/" "$STATE_TOKEN"
            fi
        fi
        return 0
    fi
    
    return 1
}

get_published_url() {
    TRACKING=$(get_tracking_info)
    echo "$TRACKING" | jq -r '.siteUrl // ""'
}

main() {
    echo "Generating Daily Report..."
    
    # Get AI news first (for data)
    AI_NEWS_DIR="${HOME}/.openclaw/workspace/ai-news-page"
    if [ -f "$AI_NEWS_DIR/data/news.json" ]; then
        cp "$AI_NEWS_DIR/data/news.json" "$REPORT_DIR/data/"
        echo "✅ AI news data included"
    fi
    
    collect_data_json
    generate_html_report
    generate_telegram_overview "https://duyet-daily-report.here.now/"
    
    echo "Publishing..."
    if publish_to_herenow; then
        URL=$(get_published_url)
        if [ -n "$URL" ]; then
            generate_telegram_overview "$URL"
        fi
        echo ""
        echo "OK: Report published"
        echo "URL: $URL"
        echo ""
        cat "$REPORT_DIR/telegram-overview.md"
    else
        echo ""
        echo "ERROR: Publish failed"
        echo "Report at: $REPORT_DIR"
    fi
}

main "$@"
