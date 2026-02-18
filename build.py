#!/usr/bin/env python3
"""
Simple static site builder for AI Data Labs website using OAT CSS.
Reads markdown files and generates static HTML with semantic OAT components.
"""

import os
import re
from pathlib import Path
from datetime import datetime

def parse_markdown(content):
    """Parse markdown and convert to HTML."""
    html = content

    # Process line by line to handle proper paragraph and list structures
    lines = html.split('\n')
    output = []
    in_list = False
    in_code_block = False

    for line in lines:
        # Code block
        if line.strip().startswith('```'):
            in_code_block = not in_code_block
            if in_code_block:
                output.append('<pre><code>')
            else:
                output.append('</code></pre>')
            continue

        if in_code_block:
            output.append(line)
            continue

        # List items
        if line.strip().startswith('- '):
            if not in_list:
                output.append('<ul>')
                in_list = True
            output.append(f'<li>{line.strip()[2:]}</li>')
        elif line.strip() == '' and in_list:
            output.append('</ul>')
            in_list = False
            output.append('')
        elif line.strip() == '':
            output.append('')
        elif line.strip().startswith('### '):
            if in_list:
                output.append('</ul>')
                in_list = False
            output.append(f'<h3>{line.strip()[4:]}</h3>')
        elif line.strip().startswith('## '):
            if in_list:
                output.append('</ul>')
                in_list = False
            output.append(f'<h2>{line.strip()[3:]}</h2>')
        elif line.strip().startswith('# '):
            if in_list:
                output.append('</ul>')
                in_list = False
            output.append(f'<h1>{line.strip()[2:]}</h1>')
        else:
            if in_list:
                output.append('</ul>')
                in_list = False
            if line.strip():
                # Bold
                line = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', line)
                # Italic (for emphasis/em style)
                line = re.sub(r'^\* (.*?)$', r'*\1*', line)
                line = re.sub(r' \* (.*?)$', r' *\1*', line)
                # Links
                line = re.sub(r'\[(.*?)\]\((.*?)\)', r'<a href="\2">\1</a>', line)
                # Code
                line = re.sub(r'`(.*?)`', r'<code>\1</code>', line)
                output.append(f'<p>{line}</p>')
            else:
                output.append('')

    if in_list:
        output.append('</ul>')

    return '\n'.join(output)

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

    # Copy OAT CSS and JS files
    import shutil
    oat_css = website_dir / 'oat.min.css'
    oat_js = website_dir / 'oat.min.js'
    if oat_css.exists():
        shutil.copy(oat_css, output_dir / 'oat.min.css')
        print(f"✓ Copied oat.min.css")
    if oat_js.exists():
        shutil.copy(oat_js, output_dir / 'oat.min.js')
        print(f"✓ Copied oat.min.js")

    # Copy index.html
    index_html = website_dir / 'index.html'
    if index_html.exists():
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

            # Create page template with OAT CSS
            page_html = f"""<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{metadata.get('title', 'AI Data Labs')}</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Geist:wght@300;400;500;600&family=Clash+Display:wght@500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/oat.min.css">
    <style>
        /* OAT CSS Custom Theme with OKLCH */
        :root {{
            /* Light mode */
            --background-light: oklch(98% 0.005 85);
            --foreground-light: oklch(15% 0.02 85);
            --primary-light: oklch(55% 0.18 195);
            --muted-foreground-light: oklch(45% 0.015 85);
            --border-light: oklch(90% 0.01 85);
            --faint-light: oklch(95% 0.005 85);

            /* Dark mode (default) */
            --background: oklch(10% 0.015 85);
            --foreground: oklch(95% 0.01 85);
            --primary: oklch(70% 0.18 195);
            --muted-foreground: oklch(70% 0.015 85);
            --border: oklch(25% 0.015 85);
            --faint: oklch(15% 0.015 85);

            /* Override OAT fonts */
            --font-sans: 'Geist', -apple-system, BlinkMacSystemFont, sans-serif;
            --font-mono: 'JetBrains Mono', 'SF Mono', 'Menlo', monospace;
        }}

        @media (prefers-color-scheme: light) {{
            :root {{
                --background: var(--background-light);
                --foreground: var(--foreground-light);
                --primary: var(--primary-light);
                --muted-foreground: var(--muted-foreground-light);
                --border: var(--border-light);
                --faint: var(--faint-light);
            }}
        }}

        body {{
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
        }}

        /* Modern CSS 2025: text-wrap: balance for headlines */
        h1, h2, h3 {{
            text-wrap: balance;
        }}

        .logo {{
            font-family: 'Clash Display', sans-serif;
            font-size: 20px;
            font-weight: 600;
            letter-spacing: -0.01em;
        }}

        .logo span {{
            color: var(--primary);
        }}

        /* Layout */
        main {{
            max-width: 900px;
            margin: 0 auto;
            padding: 0 var(--space-6);
        }}

        /* Header */
        header {{
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            background: var(--background);
            border-bottom: 1px solid var(--border);
            z-index: 100;
            padding: var(--space-4) 0;
        }}

        nav {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            max-width: 900px;
            margin: 0 auto;
            padding: 0 var(--space-6);
        }}

        .nav-links {{
            display: flex;
            gap: var(--space-8);
            align-items: center;
        }}

        .nav-links a {{
            color: var(--muted-foreground);
            text-decoration: none;
            font-size: 14px;
            font-weight: 400;
            transition: color 0.2s ease;
            position: relative;
        }}

        .nav-links a:hover {{
            color: var(--primary);
        }}

        .nav-links a::after {{
            content: '';
            position: absolute;
            bottom: -4px;
            left: 0;
            width: 0;
            height: 1px;
            background: var(--primary);
            transition: width 0.2s ease;
        }}

        .nav-links a:hover::after {{
            width: 100%;
        }}

        .github-link {{
            display: flex;
            align-items: center;
            gap: 6px;
        }}

        .github-link svg {{
            width: 18px;
            height: 18px;
        }}

        /* Content area */
        main {{
            padding-top: 160px;
            padding-bottom: 80px;
        }}

        h1 {{
            font-family: 'Clash Display', sans-serif;
            font-size: 48px;
            font-weight: 600;
            line-height: 1.1;
            letter-spacing: -0.02em;
            margin-bottom: 24px;
            animation: fadeUp 0.8s ease forwards;
            opacity: 0;
        }}

        h2 {{
            font-size: 32px;
            font-weight: 600;
            margin: 3rem 0 1.5rem;
            animation: fadeUp 0.8s ease 0.1s forwards;
            opacity: 0;
        }}

        h3 {{
            font-size: 24px;
            font-weight: 600;
            margin: 2rem 0 1rem;
            animation: fadeUp 0.8s ease 0.15s forwards;
            opacity: 0;
        }}

        p {{
            color: var(--muted-foreground);
            margin-bottom: 1.5rem;
            line-height: 1.8;
            font-size: 16px;
            animation: fadeUp 0.8s ease 0.2s forwards;
            opacity: 0;
        }}

        a {{
            color: var(--primary);
            text-decoration: none;
            font-weight: 500;
            transition: color 0.2s ease;
        }}

        a:hover {{
            text-decoration: underline;
        }}

        strong {{
            color: var(--foreground);
            font-weight: 600;
        }}

        em {{
            font-style: italic;
            color: var(--muted-foreground);
            font-size: 14px;
            display: block;
            margin-top: -1rem;
            margin-bottom: 1.5rem;
        }}

        ul {{
            margin-bottom: 1.5rem;
        }}

        li {{
            color: var(--muted-foreground);
            margin-bottom: 0.5rem;
            padding-left: var(--space-2);
            position: relative;
        }}

        li::before {{
            content: '•';
            position: absolute;
            left: 0;
            color: var(--primary);
        }}

        @keyframes fadeUp {{
            from {{
                opacity: 0;
                transform: translateY(20px);
            }}
            to {{
                opacity: 1;
                transform: translateY(0);
            }}
        }}

        /* Footer */
        footer {{
            border-top: 1px solid var(--border);
            padding: 3rem 0;
            margin-top: 4rem;
        }}

        footer p {{
            font-size: 14px;
            color: var(--muted-foreground);
            margin-bottom: 0.5rem;
            animation: none;
            opacity: 1;
        }}

        footer a {{
            color: var(--muted-foreground);
            margin-left: var(--space-8);
        }}

        footer a:hover {{
            color: var(--primary);
        }}

        @media (max-width: 768px) {{
            h1 {{ font-size: 36px; }}
            h2 {{ font-size: 28px; }}
            main {{ padding-top: 140px; }}
            .nav-links {{ display: none; }}
            main {{ padding: 0 var(--space-5); }}
        }}
    </style>
</head>
<body>
    <header>
        <nav>
            <a href="/" class="logo">Duet <span>Company</span></a>
            <div class="nav-links">
                <a href="/">Home</a>
                <a href="/features.html">Features</a>
                <a href="/pricing.html">Pricing</a>
                <a href="/about.html">About</a>
                <a href="https://github.com/duet-company/duet-company.github.io" class="github-link">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22"/>
                    </svg>
                    GitHub
                </a>
            </div>
        </nav>
    </header>
    <main>
        {html_content}
    </main>
    <footer>
        <main>
            <p>&copy; 2026 Duet Company. Built with AI, refined by humans.</p>
            <div>
                <a href="https://github.com/duet-company">GitHub</a>
                <a href="mailto:hello@duet-company.dev">Email</a>
            </div>
        </main>
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
