#!/bin/bash
set -e

# Blog Post HTML Generator & Publisher
# Creates beautiful HTML report and publishes to here.now

DATE=$(date +%Y-%m-%d)
POST_FILE="$1"  # Full path to markdown file
POST_TITLE="$2"  # Post title
POST_SLUG="$3"  # URL slug

OUTPUT_DIR="$HOME/.openclaw/workspace/daily-blog-post"
OUTPUT_FILE="$OUTPUT_DIR/blog-post-$DATE.html"
STATE_FILE="$OUTPUT_DIR/.herenow/state.json"

mkdir -p "$OUTPUT_DIR/.herenow"

echo "Generating blog post HTML for: $POST_TITLE" > /dev/null

# Read markdown content
if [ ! -f "$POST_FILE" ]; then
    echo "❌ Post file not found: $POST_FILE"
    exit 1
fi

# Extract markdown content (remove frontmatter)
CONTENT=$(sed '/^---$/,/^---$/d' "$POST_FILE" | sed '1,/^---$/d' | sed '1,/^---$/d')

# Generate HTML report
cat > "$OUTPUT_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$POST_TITLE - Duet Company Blog</title>
    <meta name="description" content="Technical blog post from Duet Company - AI-first data infrastructure.">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        :root {
            --bg-primary: #0f172a;
            --bg-secondary: #1e293b;
            --bg-elevated: #334155;
            --text-primary: #f1f5f9;
            --text-secondary: #cbd5e1;
            --text-muted: #64748b;
            --accent: #10b981;
            --accent-dark: #059669;
            --border: #334155;
            --border-subtle: #1e293b;
            --code-bg: #1a1a2e;
            --code-text: #a5b4fc;
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
            padding: 60px 20px;
        }
        header {
            text-align: center;
            padding: 60px 0;
            border-bottom: 1px solid var(--border);
            background: linear-gradient(135deg, var(--accent), var(--accent-dark));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        h1 {
            font-size: 2.5rem;
            font-weight: 700;
            margin-bottom: 12px;
        }
        .meta {
            font-size: 1.1rem;
            color: white;
            font-weight: 400;
            margin-top: 16px;
            opacity: 0.95;
        }
        article {
            padding: 60px 0;
        }
        .content {
            line-height: 1.8;
            color: var(--text-secondary);
        }
        .content h2 {
            font-size: 1.8rem;
            font-weight: 600;
            margin: 48px 0 20px;
            color: var(--text-primary);
        }
        .content h3 {
            font-size: 1.4rem;
            font-weight: 600;
            margin: 32px 0 16px;
            color: var(--text-primary);
        }
        .content p {
            margin-bottom: 20px;
        }
        .content pre {
            background: var(--code-bg);
            border-radius: 12px;
            padding: 24px;
            overflow-x: auto;
            margin: 24px 0;
            border: 1px solid var(--border);
        }
        .content code {
            color: var(--code-text);
            font-family: 'SF Mono', 'Menlo', 'Consolas', monospace;
            font-size: 0.95em;
        }
        .content ul, .content ol {
            margin: 20px 0;
            padding-left: 28px;
            color: var(--text-secondary);
        }
        .content li {
            margin-bottom: 12px;
        }
        .content strong {
            color: var(--text-primary);
            font-weight: 600;
        }
        .content blockquote {
            margin: 32px 0;
            padding: 20px 24px;
            border-left: 4px solid var(--accent);
            background: var(--bg-elevated);
            border-radius: 0 12px 12px 0;
            color: var(--text-primary);
        }
        .content blockquote p {
            margin-bottom: 0;
        }
        footer {
            text-align: center;
            padding: 60px 0;
            border-top: 1px solid var(--border);
            color: var(--text-muted);
            font-size: 0.95rem;
        }
        .footer a {
            color: var(--accent);
            text-decoration: none;
            font-weight: 500;
        }
        .footer a:hover {
            text-decoration: underline;
        }
        @media (max-width: 768px) {
            header h1 { font-size: 1.8rem; }
            article { padding: 40px 0; }
            .content h2 { font-size: 1.5rem; }
            .content h3 { font-size: 1.2rem; }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>$POST_TITLE</h1>
            <div class="meta">Duet Company Blog • $DATE</div>
        </header>

        <article>
            <div class="content">
                <pre><code>$(cat "$POST_FILE")</code></pre>
            </div>
        </article>

        <footer>
            <p>Published by <a href="https://duet-company.github.io/blog/">Duet Company</a></p>
            <p style="margin-top: 8px;">AI-first data infrastructure management</p>
            <p style="margin-top: 8px; color: var(--text-muted);">All blog posts: <a href="https://duet-company.github.io/blog/">duet-company.github.io/blog/</a></p>
        </footer>
    </div>
</body>
</html>
EOF

echo "✅ Generated: $OUTPUT_FILE"

# Publish to here.now
cd "$OUTPUT_DIR"
bash "$HOME/.openclaw/skills/here-now/scripts/publish.sh" "$OUTPUT_FILE"

# Get URL
if [ -f "$STATE_FILE" ]; then
    URL=$(python3 -c "import json; f=open('$STATE_FILE'); d=json.load(f); print(d.get('publishes', {}).get(list(d.keys())[0], {}).get('siteUrl', 'N/A'))" 2>/dev/null || echo "N/A")
    if [ "$URL" != "N/A" ]; then
        echo "✅ Published: $URL"
        echo "$URL" > "$OUTPUT_DIR/latest-url.txt"
    else
        echo "⚠️ Failed to get URL"
    fi
fi

# Output for Telegram/email (compact format)
echo "📝 New Blog Post"
echo ""
echo "<b>$POST_TITLE</b>"
echo ""
echo "📅 $DATE"
echo ""
echo "🌐 Read full article: $URL"
