#!/usr/bin/env python3
"""
Publish blog posts from content/blog/ to docs/blog/
"""

import os
import sys
from pathlib import Path
from datetime import datetime
import re

# Paths
CONTENT_DIR = Path("content/blog")
OUTPUT_DIR = Path("docs/blog")

# Blog post template
BLOG_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title} - Duet Company Blog</title>
    <meta name="description" content="{description}">
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        :root {{
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
        }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Inter', system-ui, sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
            line-height: 1.7;
            min-height: 100vh;
        }}
        .container {{
            max-width: 900px;
            margin: 0 auto;
            padding: 60px 20px;
        }}
        header {{
            text-align: center;
            padding: 60px 0;
            border-bottom: 1px solid var(--border);
            background: linear-gradient(135deg, var(--accent), var(--accent-dark));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }}
        h1 {{
            font-size: 2.5rem;
            font-weight: 700;
            margin-bottom: 12px;
        }}
        .meta {{
            color: var(--text-muted);
            font-size: 0.95rem;
            margin-top: 8px;
        }}
        .meta span {{
            display: inline-block;
            margin: 0 12px;
        }}
        .content {{
            padding: 40px 0;
        }}
        .content h2 {{
            font-size: 1.8rem;
            margin: 40px 0 20px;
            color: var(--accent);
        }}
        .content h3 {{
            font-size: 1.4rem;
            margin: 30px 0 16px;
        }}
        .content p {{
            margin-bottom: 16px;
            line-height: 1.8;
        }}
        .content pre {{
            background: var(--code-bg);
            padding: 20px;
            border-radius: 8px;
            overflow-x: auto;
            margin: 20px 0;
            border: 1px solid var(--border);
        }}
        .content code {{
            color: var(--code-text);
            font-family: 'SF Mono', 'Menlo', monospace;
            font-size: 0.9rem;
        }}
        .content ul, .content ol {{
            margin: 16px 0;
            padding-left: 24px;
        }}
        .content li {{
            margin-bottom: 8px;
        }}
        .content blockquote {{
            border-left: 4px solid var(--accent);
            margin: 20px 0;
            padding: 16px 20px;
            background: var(--bg-secondary);
            border-radius: 0 8px 8px 0;
        }}
        .content table {{
            width: 100%;
            border-collapse: collapse;
            margin: 24px 0;
        }}
        .content th, .content td {{
            padding: 12px 16px;
            text-align: left;
            border-bottom: 1px solid var(--border);
        }}
        .content th {{
            background: var(--bg-secondary);
            font-weight: 600;
            color: var(--accent);
        }}
        .footer {{
            margin-top: 60px;
            padding-top: 40px;
            border-top: 1px solid var(--border);
            text-align: center;
            color: var(--text-muted);
        }}
        .footer a {{
            color: var(--accent);
            text-decoration: none;
        }}
        .footer a:hover {{
            text-decoration: underline;
        }}
        @media (max-width: 768px) {{
            .container {{
                padding: 40px 16px;
            }}
            h1 {{
                font-size: 2rem;
            }}
            .content h2 {{
                font-size: 1.5rem;
            }}
        }}
    </style>
</head>
<body>
    <header>
        <div class="container">
            <h1>{title}</h1>
            <div class="meta">
                <span>📅 {date}</span>
                <span>⏱️ {read_time}</span>
                <span>🏷️ {category}</span>
            </div>
        </div>
    </header>
    <div class="container">
        <article class="content">
            {body}
        </article>
        <footer class="footer">
            <p>© 2026 Duet Company. AI-first data infrastructure.</p>
            <p>
                <a href="../index.html">← Back to Home</a>
            </p>
        </footer>
    </div>
</body>
</html>
"""

def markdown_to_html(markdown_text):
    """Simple Markdown to HTML converter"""
    html = markdown_text

    # Headers
    html = re.sub(r'^### (.+)$', r'<h3>\1</h3>', html, flags=re.MULTILINE)
    html = re.sub(r'^## (.+)$', r'<h2>\1</h2>', html, flags=re.MULTILINE)
    html = re.sub(r'^# (.+)$', r'<h1>\1</h1>', html, flags=re.MULTILINE)

    # Code blocks
    html = re.sub(r'```(\w+)?\n(.*?)```', r'<pre><code>\2</code></pre>', html, flags=re.DOTALL)

    # Inline code
    html = re.sub(r'`([^`]+)`', r'<code>\1</code>', html)

    # Bold
    html = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', html)

    # Italic
    html = re.sub(r'\*([^*]+)\*', r'<em>\1</em>', html)

    # Lists
    lines = html.split('\n')
    in_list = False
    list_type = None
    result = []

    for line in lines:
        if line.startswith('- '):
            if not in_list:
                result.append('<ul>')
                in_list = True
                list_type = 'ul'
            result.append(f'<li>{line[2:]}</li>')
        elif line.strip() == '' and in_list:
            result.append('</ul>')
            in_list = False
            list_type = None
            result.append(line)
        else:
            if in_list:
                result.append('</ul>')
                in_list = False
                list_type = None
            result.append(line)

    if in_list:
        result.append('</ul>')

    html = '\n'.join(result)

    # Paragraphs (skip if already wrapped in HTML tags)
    paragraphs = html.split('\n\n')
    result = []
    for para in paragraphs:
        para = para.strip()
        if para and not para.startswith('<'):
            result.append(f'<p>{para}</p>')
        elif para:
            result.append(para)

    return '\n\n'.join(result)

def extract_metadata(content):
    """Extract title, date, and other metadata from markdown"""
    lines = content.split('\n')

    title = "Blog Post"
    date = datetime.now().strftime("%B %d, %Y")
    category = "Engineering"

    if lines[0].startswith('# '):
        title = lines[0][2:].strip()
        content = '\n'.join(lines[1:])

    return title, date, category, content

def calculate_read_time(content):
    """Calculate estimated read time (assuming 200 words per minute)"""
    word_count = len(content.split())
    minutes = max(1, round(word_count / 200))
    return f"{minutes} min read"

def publish_blog_posts():
    """Publish all blog posts from content/blog/ to docs/blog/"""

    # Create output directory if it doesn't exist
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Find all markdown files in content/blog/
    blog_files = list(CONTENT_DIR.glob("*.md"))

    if not blog_files:
        print("❌ No blog posts found in content/blog/")
        return 1

    published_count = 0

    for blog_file in blog_files:
        print(f"\n📝 Processing: {blog_file.name}")

        # Read markdown content
        with open(blog_file, 'r', encoding='utf-8') as f:
            markdown_content = f.read()

        # Extract metadata
        title, date, category, body = extract_metadata(markdown_content)

        # Convert markdown to HTML
        html_body = markdown_to_html(body)

        # Calculate read time
        read_time = calculate_read_time(markdown_content)

        # Generate description (first 150 chars of body)
        description = body.replace('#', '').strip()[:150] + "..."

        # Create HTML output
        html_output = BLOG_TEMPLATE.format(
            title=title,
            description=description,
            date=date,
            read_time=read_time,
            category=category,
            body=html_body
        )

        # Write to output file
        output_file = OUTPUT_DIR / f"{blog_file.stem}.html"
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(html_output)

        print(f"✅ Published to: {output_file}")
        published_count += 1

    print(f"\n🎉 Successfully published {published_count} blog post(s) to {OUTPUT_DIR}/")
    return 0

if __name__ == "__main__":
    sys.exit(publish_blog_posts())
