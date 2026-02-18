#!/usr/bin/env python3
"""
Modern static site builder for Duet Company website.
Uses sophisticated neutral palette with emerald accent.
"""

import os
import re
import shutil
from pathlib import Path

# CSS template with new design system
CSS_TEMPLATE = """/* Modern CSS 2025 - Sophisticated Neutral Palette */
:root {
    /* Light mode */
    --background-light: oklch(99% 0.002 85);
    --surface-light: oklch(95% 0.003 85);
    --foreground-light: oklch(15% 0.005 85);
    --muted-light: oklch(45% 0.01 85);
    --border-light: oklch(88% 0.005 85);
    --accent-light: oklch(62% 0.15 145);

    /* Dark mode (default) - Charcoal/Graphite base */
    --background: oklch(12% 0.008 85);
    --surface: oklch(16% 0.008 85);
    --surface-elevated: oklch(20% 0.008 85);
    --foreground: oklch(97% 0.003 85);
    --muted: oklch(65% 0.008 85);
    --border: oklch(28% 0.008 85);
    --border-subtle: oklch(22% 0.006 85);
    --accent: oklch(70% 0.16 145);

    /* Typography */
    --font-sans: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    --font-display: 'Clash Display', sans-serif;
    --font-mono: 'SF Mono', 'Menlo', monospace;

    /* Spacing */
    --container-max: 1400px;
}

@media (prefers-color-scheme: light) {
    :root {
        --background: var(--background-light);
        --surface: var(--surface-light);
        --surface-elevated: oklch(98% 0.003 85);
        --foreground: var(--foreground-light);
        --muted: var(--muted-light);
        --border: var(--border-light);
        --border-subtle: oklch(92% 0.004 85);
        --accent: oklch(58% 0.18 145);
    }
}

*, *::before, *::after {
    box-sizing: border-box;
}

html {
    scroll-behavior: smooth;
}

body {
    font-family: var(--font-sans);
    background: var(--background);
    color: var(--foreground);
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    line-height: 1.6;
}

h1, h2, h3, h4 {
    text-wrap: balance;
    font-family: var(--font-display);
    font-weight: 600;
    letter-spacing: -0.02em;
    line-height: 1.1;
}

.container {
    max-width: var(--container-max);
    margin: 0 auto;
    padding: 0 24px;
}

@media (min-width: 768px) {
    .container {
        padding: 0 48px;
    }
}

/* Header */
header {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    z-index: 100;
    background: oklch(from var(--background) calc(l - 2%) c h / 0.8);
    backdrop-filter: blur(20px) saturate(180%);
    -webkit-backdrop-filter: blur(20px) saturate(180%);
    border-bottom: 1px solid var(--border-subtle);
}

nav {
    display: flex;
    justify-content: space-between;
    align-items: center;
    height: 64px;
}

.logo {
    font-family: var(--font-display);
    font-size: 18px;
    font-weight: 600;
    color: var(--foreground);
    text-decoration: none;
    letter-spacing: -0.02em;
    display: flex;
    align-items: center;
    gap: 8px;
}

.logo-mark {
    width: 24px;
    height: 24px;
    background: var(--foreground);
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
}

.logo-mark span {
    color: var(--background);
    font-size: 14px;
    font-weight: 700;
}

.nav-links {
    display: flex;
    gap: 32px;
    align-items: center;
}

.nav-links a {
    color: var(--muted);
    text-decoration: none;
    font-size: 14px;
    font-weight: 500;
    transition: color 0.2s ease;
    position: relative;
}

.nav-links a:hover {
    color: var(--foreground);
}

.nav-links a.active::after {
    width: 100%;
}

.nav-links a::after {
    content: '';
    position: absolute;
    bottom: -22px;
    left: 0;
    width: 0;
    height: 2px;
    background: var(--foreground);
    transition: width 0.2s ease;
}

.nav-links a:hover::after {
    width: 100%;
}

.github-link {
    display: flex;
    align-items: center;
    gap: 6px;
    color: var(--muted);
    text-decoration: none;
    font-size: 14px;
    font-weight: 500;
}

.github-link:hover {
    color: var(--foreground);
}

.github-link svg {
    width: 18px;
    height: 18px;
}

@media (max-width: 768px) {
    .nav-links {
        display: none;
    }
}

/* Content */
main {
    padding-top: 140px;
    padding-bottom: 80px;
    min-height: 100vh;
}

/* Page header */
.page-header {
    margin-bottom: 64px;
}

.page-label {
    font-size: 12px;
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    color: var(--accent);
    margin-bottom: 16px;
}

.page-title {
    font-size: clamp(40px, 6vw, 64px);
    max-width: 900px;
    margin-bottom: 24px;
}

.page-subtitle {
    font-size: 18px;
    color: var(--muted);
    max-width: 640px;
    line-height: 1.7;
    font-weight: 300;
}

/* Content styling */
h1 {
    font-size: clamp(32px, 5vw, 48px);
    margin-bottom: 24px;
}

h2 {
    font-size: clamp(24px, 4vw, 36px);
    margin: 48px 0 24px;
    padding-bottom: 16px;
    border-bottom: 1px solid var(--border);
}

h3 {
    font-size: clamp(20px, 3vw, 28px);
    margin: 32px 0 16px;
    color: var(--foreground);
}

p {
    color: var(--muted);
    margin-bottom: 1.5rem;
    line-height: 1.8;
    font-size: 16px;
    font-weight: 300;
}

a {
    color: var(--foreground);
    text-decoration: none;
    border-bottom: 1px solid var(--border);
    transition: border-color 0.2s ease;
}

a:hover {
    border-color: var(--accent);
}

strong {
    color: var(--foreground);
    font-weight: 600;
}

em {
    font-style: italic;
    color: var(--muted);
}

ul, ol {
    margin-bottom: 1.5rem;
    padding-left: 24px;
}

li {
    color: var(--muted);
    margin-bottom: 0.75rem;
    line-height: 1.7;
}

li::marker {
    color: var(--accent);
}

code {
    background: var(--surface);
    color: var(--foreground);
    padding: 4px 8px;
    border-radius: 4px;
    font-family: var(--font-mono);
    font-size: 14px;
}

pre {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 20px;
    overflow-x: auto;
    margin-bottom: 24px;
}

pre code {
    background: none;
    padding: 0;
}

/* Card grid for features */
.card-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 24px;
    margin: 48px 0;
}

.card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 32px;
    transition: all 0.3s ease;
}

.card:hover {
    transform: translateY(-4px);
    border-color: var(--foreground);
    box-shadow: 0 20px 40px -20px oklch(from var(--foreground) c h / 0.2);
}

.card h3 {
    margin-top: 0;
    margin-bottom: 12px;
}

.card p {
    margin-bottom: 0;
}

/* Pricing grid */
.pricing-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 24px;
    margin: 48px 0;
}

.pricing-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 32px;
    display: flex;
    flex-direction: column;
}

.pricing-card.featured {
    border-color: var(--accent);
    position: relative;
}

.pricing-card.featured::before {
    content: 'Most Popular';
    position: absolute;
    top: -12px;
    left: 50%;
    transform: translateX(-50%);
    background: var(--accent);
    color: var(--background);
    font-size: 11px;
    font-weight: 600;
    padding: 4px 12px;
    border-radius: 100px;
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

.pricing-name {
    font-family: var(--font-display);
    font-size: 24px;
    margin-bottom: 8px;
}

.pricing-price {
    font-size: 36px;
    font-weight: 700;
    margin-bottom: 16px;
}

.pricing-price span {
    font-size: 16px;
    font-weight: 400;
    color: var(--muted);
}

.pricing-desc {
    color: var(--muted);
    font-size: 14px;
    margin-bottom: 24px;
}

.pricing-features {
    list-style: none;
    padding: 0;
    margin-bottom: 24px;
    flex-grow: 1;
}

.pricing-features li {
    padding-left: 24px;
    position: relative;
}

.pricing-features li::before {
    content: '✓';
    position: absolute;
    left: 0;
    color: var(--accent);
    font-weight: 600;
}

.pricing-cta {
    display: inline-block;
    padding: 14px 28px;
    background: var(--foreground);
    color: var(--background);
    text-decoration: none;
    border-radius: 6px;
    font-weight: 500;
    font-size: 14px;
    text-align: center;
    border: none;
    transition: all 0.2s ease;
}

.pricing-cta:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 30px -10px oklch(from var(--foreground) c h / 0.3);
    border: none;
}

/* Footer */
footer {
    padding: 48px 0;
    border-top: 1px solid var(--border-subtle);
}

.footer-content {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.footer-text {
    font-size: 14px;
    color: var(--muted);
}

.footer-links {
    display: flex;
    gap: 24px;
}

.footer-links a {
    color: var(--muted);
    text-decoration: none;
    font-size: 14px;
    border: none;
    transition: color 0.2s ease;
}

.footer-links a:hover {
    color: var(--foreground);
}

@media (max-width: 768px) {
    .footer-content {
        flex-direction: column;
        gap: 24px;
        text-align: center;
    }

    h1 { font-size: 32px; }
    h2 { font-size: 24px; }
    main { padding-top: 120px; }
}
"""

def parse_markdown(content):
    """Parse markdown and convert to HTML."""
    lines = content.split('\n')
    output = []
    in_list = False
    in_code_block = False
    list_type = None

    for line in lines:
        # Code block
        if line.strip().startswith('```'):
            if not in_code_block:
                output.append('<pre><code>')
                in_code_block = True
            else:
                output.append('</code></pre>')
                in_code_block = False
            continue

        if in_code_block:
            output.append(line)
            continue

        # List items
        if line.strip().startswith('- ') or line.strip().startswith('* '):
            if not in_list:
                output.append('<ul>')
                in_list = True
                list_type = 'ul'
            output.append(f'<li>{line.strip()[2:]}</li>')
        elif line.strip().startswith(tuple([f'{i}. ' for i in range(1, 10)])):
            if not in_list or list_type != 'ol':
                if in_list and list_type == 'ul':
                    output.append('</ul>')
                output.append('<ol>')
                in_list = True
                list_type = 'ol'
            # Find the number and text
            match = re.match(r'^(\d+)\.\s+(.+)$', line.strip())
            if match:
                output.append(f'<li>{match.group(2)}</li>')
        elif line.strip() == '':
            if in_list:
                output.append('</ul>' if list_type == 'ul' else '</ol>')
                in_list = False
                list_type = None
            output.append('')
        elif line.strip().startswith('### '):
            if in_list:
                output.append('</ul>' if list_type == 'ul' else '</ol>')
                in_list = False
            output.append(f'<h3>{line.strip()[4:]}</h3>')
        elif line.strip().startswith('## '):
            if in_list:
                output.append('</ul>' if list_type == 'ul' else '</ol>')
                in_list = False
            output.append(f'<h2>{line.strip()[3:]}</h2>')
        elif line.strip().startswith('# '):
            if in_list:
                output.append('</ul>' if list_type == 'ul' else '</ol>')
                in_list = False
            output.append(f'<h1>{line.strip()[2:]}</h1>')
        else:
            if in_list:
                output.append('</ul>' if list_type == 'ul' else '</ol>')
                in_list = False
            if line.strip():
                # Bold
                line = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', line)
                # Italic
                line = re.sub(r'\*(.*?)\*', r'<em>\1</em>', line)
                # Links
                line = re.sub(r'\[(.*?)\]\((.*?)\)', r'<a href="\2">\1</a>', line)
                # Inline code
                line = re.sub(r'`(.*?)`', r'<code>\1</code>', line)
                output.append(f'<p>{line}</p>')
            else:
                output.append('')

    if in_list:
        output.append('</ul>' if list_type == 'ul' else '</ol>')

    return '\n'.join(output)

def read_markdown_file(path):
    """Read a markdown file and extract metadata."""
    with open(path, 'r') as f:
        content = f.read()

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

def generate_page_html(title, html_content, active_nav=''):
    """Generate HTML page with template."""
    return f"""<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title}</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600&family=Clash+Display:wght@500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/oat.min.css">
    <style>
{CSS_TEMPLATE}
    </style>
</head>
<body>
    <header>
        <div class="container">
            <nav>
                <a href="/" class="logo">
                    <div class="logo-mark"><span>D</span></div>
                    Duet Company
                </a>
                <div class="nav-links">
                    <a href="/" class="{'active' if active_nav == 'home' else ''}">Home</a>
                    <a href="/features.html" class="{'active' if active_nav == 'features' else ''}">Features</a>
                    <a href="/pricing.html" class="{'active' if active_nav == 'pricing' else ''}">Pricing</a>
                    <a href="/about.html" class="{'active' if active_nav == 'about' else ''}">About</a>
                    <a href="https://github.com/duet-company" class="github-link">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22"/>
                        </svg>
                    </a>
                </div>
            </nav>
        </div>
    </header>
    <main>
        <div class="container">
            {html_content}
        </div>
    </main>
    <footer>
        <div class="container">
            <div class="footer-content">
                <div class="footer-text">&copy; 2026 Duet Company. Built by AI.</div>
                <div class="footer-links">
                    <a href="https://github.com/duet-company">GitHub</a>
                    <a href="/">Home</a>
                    <a href="/features.html">Features</a>
                    <a href="/pricing.html">Pricing</a>
                    <a href="/about.html">About</a>
                </div>
            </div>
        </div>
    </footer>
</body>
</html>"""

def generate_site():
    """Generate the static site."""
    website_dir = Path(__file__).parent
    output_dir = website_dir / 'docs'
    content_dir = website_dir / 'content'

    # Create output directory
    output_dir.mkdir(exist_ok=True)

    # Copy OAT CSS and JS files
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

    # Ensure content directory exists
    content_dir.mkdir(exist_ok=True)

    # Page definitions
    pages = {
        'about.md': ('About Duet Company', 'about', 'about.html'),
        'features.md': ('Features - AI Data Labs', 'features', 'features.html'),
        'pricing.md': ('Pricing - AI Data Labs', 'pricing', 'pricing.html'),
        'contact.md': ('Contact - AI Data Labs', 'contact', 'contact.html'),
    }

    for md_file, (page_title, active_nav, html_file) in pages.items():
        md_path = content_dir / md_file
        if md_path.exists():
            metadata, content = read_markdown_file(md_path)
            title = metadata.get('title', page_title)
            html_content = parse_markdown(content)

            # Wrap content in page header
            page_header = f'<div class="page-header">\n'
            page_header += f'    <div class="page-label">{md_file.replace(".md", "").title()}</div>\n'
            page_header += f'    <h1 class="page-title">{title.replace(" - AI Data Labs", "")}</h1>\n'
            page_header += f'</div>\n'

            # For pricing page, add subtitle
            if md_file == 'pricing.md':
                page_header = f'<div class="page-header">\n'
                page_header += f'    <div class="page-label">Pricing</div>\n'
                page_header += f'    <h1 class="page-title">Simple, transparent pricing</h1>\n'
                page_header += f'    <p class="page-subtitle">Choose the plan that fits your needs. All plans include a 14-day free trial.</p>\n'
                page_header += f'</div>\n'

            full_content = page_header + html_content

            page_html = generate_page_html(title, full_content, active_nav)

            with open(output_dir / html_file, 'w') as f:
                f.write(page_html)
            print(f"✓ Generated {html_file}")
        else:
            print(f"  Skipping {md_file} (not found)")

    print(f"\n✓ Site built to {output_dir}")
    print(f"  Files: {len(list(output_dir.glob('*.html')))}")

if __name__ == '__main__':
    generate_site()
