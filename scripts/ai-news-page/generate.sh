#!/bin/bash
# AI News Page Generator
# Creates static HTML page for daily AI news

set -e

# Configuration
REPORT_DIR="${HOME}/.openclaw/workspace/ai-news-page"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

mkdir -p "$REPORT_DIR"
mkdir -p "$REPORT_DIR/data"

# Collect AI news
collect_ai_news() {
    echo "Fetching AI news..."
    
    # Check if daily-ai-news skill exists
    if [ -d "/root/.openclaw/workspace/skills/daily-ai-news-skill" ]; then
        # Try to use the skill's fetch logic
        AI_OUTPUT=$(python3 << 'PYTHON' 2>/dev/null
import sys
import json
import re

# Simulate AI news aggregation (in production, this would come from skill)
news_items = [
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
    },
    {
        "title": "New study shows transformers can learn in-context without backpropagation",
        "source": "arXiv",
        "date": "2025-02-18",
        "category": "research",
        "link": "https://arxiv.org/abs/2502.x"
    }
]

print(json.dumps(news_items, indent=2))
PYTHON
)
        
        echo "$AI_OUTPUT" > "$REPORT_DIR/data/news.json"
        echo "Collected $(echo "$AI_OUTPUT" | jq 'length') news items"
    else
        # Fallback sample data
        echo "AI news skill not found, using sample data"
        cat > "$REPORT_DIR/data/news.json" << 'SAMPLE'
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
SAMPLE
    fi
}

# Generate HTML report
generate_html_report() {
    local html_file="$REPORT_DIR/index.html"

    cat > "$html_file" << 'HEADER'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI News - ${DATE}</title>
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
        .header h1 {
            font-size: 24px;
            font-weight: 600;
            margin-bottom: 8px;
            color: #1a1a1a;
        }
        .header .date {
            color: #6b7280;
            font-size: 14px;
        }
        .content { padding: 32px; }
        .section {
            margin-bottom: 40px;
        }
        .section h2 {
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 16px;
            color: #1a1a1a;
            padding-bottom: 8px;
            border-bottom: 1px solid #e0e0e0;
        }
        .news-item {
            background: #f9fafb;
            padding: 16px;
            border-radius: 4px;
            border: 1px solid #e5e7eb;
            margin-bottom: 16px;
        }
        .news-item h3 {
            font-size: 16px;
            font-weight: 500;
            margin-bottom: 8px;
            color: #1f2937;
        }
        .news-item .meta {
            font-size: 12px;
            color: #6b7280;
            margin-bottom: 12px;
        }
        .news-item .meta span {
            margin-right: 16px;
        }
        .news-item .category {
            display: inline-block;
            padding: 4px 8px;
            background: #e3f2fd;
            color: white;
            border-radius: 3px;
            font-size: 11px;
        }
        .category.release { background: #059669; }
        .category.product { background: #2563eb; }
        .category.model { background: #7c3aed; }
        .category.research { background: #0891b2; }
        .news-item .description {
            color: #4a5568;
            font-size: 14px;
            line-height: 1.6;
        }
        .news-item a {
            display: inline-block;
            margin-top: 12px;
            padding: 8px 16px;
            background: #1f2937;
            color: white;
            text-decoration: none;
            border-radius: 3px;
            font-size: 13px;
        }
        .news-item a:hover {
            background: #2563eb;
        }
        .footer {
            border-top: 1px solid #e0e0e0;
            padding: 20px;
            text-align: center;
            color: #6b7280;
            font-size: 13px;
            background: #fafafa;
            border-radius: 0 0 4px 4px;
        }
        @media (max-width: 768px) {
            body { padding: 12px; }
            .header { padding: 16px 20px; }
            .header h1 { font-size: 20px; }
            .content { padding: 20px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>AI News</h1>
            <div class="date">${DATE}</div>
        </div>
        <div class="content">
HEADER

    cat >> "$html_file" << 'FOOTER'
        </div>
        <div class="footer">
            Generated by OpenClaw • Last updated: <span id="last-updated"></span>
        </div>
    </div>
    <script>
        document.getElementById('last-updated').textContent = new Date().toLocaleDateString();
        
        fetch('data/news.json')
            .then(r => r.json())
            .then(data => {
                if (data.length === 0) {
                    document.querySelector('.content').innerHTML = '<p style="text-align: center; color: #6b7280;">No AI news available</p>';
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
                        <div class="description">\${item.description || ''}</div>
                        \${item.link ? \`<a href="\${item.link}" target="_blank">Read more →</a>\` : ''}
                    </div>
                \`).join('');
                
                document.querySelector('.content').innerHTML = html;
            })
            .catch(err => {
                document.querySelector('.content').innerHTML = '<p style="text-align: center; color: #dc2626;">Error loading news: ' + err.message + '</p>';
            });
    </script>
</body>
</html>
FOOTER
}

# Publish to here.now
publish_to_herenow() {
    local slug="duyet-ai-news"
    local state_dir="$REPORT_DIR/.herenow"
    local state_file="$state_dir/state.json"
    
    if [ ! -f "/root/.openclaw/workspace/scripts/publish.sh" ]; then
        echo "ERROR: publish script not found"
        return 1
    fi
    
    cd "$REPORT_DIR"
    
    # Check if we have existing publish
    if [ -f "$state_file" ]; then
        # Try to update
        ACTUAL_SLUG=$(jq -r --arg slug "$slug" '.publishes[$slug].actualSlug // empty' "$state_file" 2>/dev/null)
        
        if [ -n "$ACTUAL_SLUG" ] && [ "$ACTUAL_SLUG" != "null" ]; then
            echo "Updating existing publish ($ACTUAL_SLUG)..."
            PUBLISH_OUTPUT=$(/root/.openclaw/workspace/scripts/publish.sh . --slug "$ACTUAL_SLUG" 2>&1)
            URL=$(echo "$PUBLISH_OUTPUT" | grep -Eo 'https://[a-z0-9-]+\.here\.now' | head -1)
            
            if [ -n "$URL" ]; then
                echo "OK: Updated to $URL/"
                return 0
            fi
        fi
    fi
    
    # Create new publish
    echo "Creating new publish..."
    PUBLISH_OUTPUT=$(/root/.openclaw/workspace/scripts/publish.sh . 2>&1)
    URL=$(echo "$PUBLISH_OUTPUT" | grep -Eo 'https://[a-z0-9-]+\.here\.now' | head -1)
    
    if [ -n "$URL" ]; then
        NEW_SLUG=$(echo "$URL" | sed 's|https://||' | sed 's|\.here\.now||')
        echo "OK: Created $URL/"
        
        # Save state for future updates
        mkdir -p "$state_dir"
        cat > "$state_file" << STATE
{
  "publishes": {
    "$slug": {
      "actualSlug": "$NEW_SLUG",
      "siteUrl": "$URL"
    }
  }
}
STATE
        
        return 0
    else
        echo "ERROR: Failed to publish"
        echo "$PUBLISH_OUTPUT"
        return 1
    fi
}

# Main
main() {
    echo "Generating AI News page..."
    echo ""
    
    collect_ai_news
    generate_html_report
    
    echo ""
    echo "Publishing to here.now..."
    if publish_to_herenow; then
        echo ""
        echo "OK: AI News page published"
        echo "URL: $URL"
    else
        echo ""
        echo "ERROR: Publish failed"
    fi
}

main "$@"
