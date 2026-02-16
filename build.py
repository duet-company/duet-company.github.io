#!/usr/bin/env python3
"""
Simple static site builder for AI Data Labs website.
Reads markdown files and generates static HTML.
"""

import os
import re
from pathlib import Path
from datetime import datetime

def parse_markdown(content):
    """Parse markdown and convert to HTML."""
    html = content
    # Headers
    html = re.sub(r'^### (.*?)$', r'<h3>\1</h3>', html, flags=re.MULTILINE)
    html = re.sub(r'^## (.*?)$', r'<h2>\1</h2>', html, flags=re.MULTILINE)
    html = re.sub(r'^# (.*?)$', r'<h1>\1</h1>', html, flags=re.MULTILINE)
    # Bold
    html = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', html)
    # Italic
    html = re.sub(r'\*(.*?)\*', r'<em>\1</em>', html)
    # Links
    html = re.sub(r'\[(.*?)\]\((.*?)\)', r'<a href="\2">\1</a>', html)
    # Code
    html = re.sub(r'`(.*?)`', r'<code>\1</code>', html)
    # Line breaks
    html = html.replace('\n\n', '</p><p>')
    html = '<p>' + html + '</p>'
    return html

def read_markdown_file(path):
    """Read a markdown file and extract metadata."""
    with open(path, 'r') as f:
        content = f.read()

    # Extract metadata (YAML frontmatter style)
    metadata = {}
    if content.startswith('---'):
        parts = content.split('---', 2)
        if len(parts) >= 3:
            metadata_str = parts[1]
            content = parts[2]
            for line in metadata_str.split('\n'):
                if ':' in line:
                    key, value = line.split(':', 1)
                    metadata[key.strip()] = value.strip()

    return metadata, content

def generate_site():
    """Generate the static site."""
    website_dir = Path(__file__).parent
    output_dir = website_dir / 'docs'
    content_dir = website_dir / 'content'

    # Create output directory
    output_dir.mkdir(exist_ok=True)

    # Copy index.html
    index_html = website_dir / 'index.html'
    if index_html.exists():
        import shutil
        shutil.copy(index_html, output_dir / 'index.html')
        print(f"✓ Copied index.html")

    # Process content files
    content_dir.mkdir(exist_ok=True)

    # Create simple pages from markdown
    pages = {
        'about.md': 'about.html',
        'features.md': 'features.html',
        'pricing.md': 'pricing.html',
        'contact.md': 'contact.html',
    }

    for md_file, html_file in pages.items():
        md_path = content_dir / md_file
        if md_path.exists():
            metadata, content = read_markdown_file(md_path)
            html_content = parse_markdown(content)

            # Create page template
            page_html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{metadata.get('title', 'AI Data Labs')}</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Clash+Display:wght@500;600;700&display=swap" rel="stylesheet">
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif; background: #ffffff; color: #111111; line-height: 1.5; -webkit-font-smoothing: antialiased; }}
        .container {{ max-width: 800px; margin: 0 auto; padding: 2rem 24px; }}
        header {{ background: #ffffff; border-bottom: 1px solid #e5e7eb; position: fixed; top: 0; left: 0; right: 0; z-index: 100; }}
        nav {{ display: flex; justify-content: space-between; align-items: center; padding: 20px 0; }}
        .logo {{ font-family: 'Clash Display', sans-serif; font-size: 24px; font-weight: 600; color: #111111; text-decoration: none; }}
        .nav-links a {{ color: #666666; text-decoration: none; margin-left: 32px; font-size: 14px; font-weight: 500; }}
        .nav-links a:hover {{ color: #111111; }}
        h1 {{ font-family: 'Clash Display', sans-serif; font-size: 40px; font-weight: 600; margin-bottom: 2rem; color: #111111; }}
        h2 {{ font-size: 24px; font-weight: 600; margin: 2rem 0 1rem; color: #111111; }}
        h3 {{ font-size: 20px; font-weight: 600; margin: 1.5rem 0 0.75rem; color: #111111; }}
        p {{ color: #666666; margin-bottom: 1rem; line-height: 1.6; }}
        a {{ color: #111111; text-decoration: none; font-weight: 500; }}
        a:hover {{ text-decoration: underline; }}
        code {{ background: #f9fafb; padding: 0.2rem 0.4rem; border: 1px solid #e5e7eb; border-radius: 4px; font-size: 14px; }}
    </style>
</head>
<body>
    <header>
        <div class="container" style="padding: 0 24px;">
            <nav>
                <a href="/" class="logo">AI Data Labs</a>
                <div class="nav-links">
                    <a href="/">Home</a>
                    <a href="/features.html">Features</a>
                    <a href="/pricing.html">Pricing</a>
                    <a href="https://github.com/duet-company/duet-company.github.io">GitHub</a>
                </div>
            </nav>
        </div>
    </header>
    <main class="container" style="padding-top: 120px;">
        {html_content}
    </main>
    <footer style="border-top: 1px solid #e5e7eb; padding: 3rem 0; margin-top: 4rem;">
        <div class="container" style="display: flex; justify-content: space-between; align-items: center;">
            <p style="color: #666666; font-size: 14px;">&copy; 2026 Duet Company</p>
            <div>
                <a href="https://github.com/duet-company" style="margin-left: 32px;">GitHub</a>
                <a href="mailto:hello@aidatalabs.ai" style="margin-left: 32px;">Contact</a>
            </div>
        </div>
    </footer>
</body>
</html>"""

            with open(output_dir / html_file, 'w') as f:
                f.write(page_html)
            print(f"✓ Generated {html_file}")

    print(f"\n✓ Site built to {output_dir}")
    print(f"  Files: {len(list(output_dir.glob('*.html')))}")

if __name__ == '__main__':
    generate_site()
