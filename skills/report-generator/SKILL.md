---
name: report-generator
description: "Comprehensive report generation system with beautiful HTML templates inspired by Vercel dashboard design. Generates unified, professional reports with email and Telegram support."
---

# Report Generator Skill

> Generate professional, beautiful reports with unified design system. Inspired by Vercel dashboard aesthetics - clean, minimal, data-focused with excellent readability.

## When to Use This Skill

Activate when you need to generate any type of report:
- Daily reports (system health, AI news, Polymarket, company progress)
- Task lists and progress tracking
- News briefings and digests
- Data tables and charts
- Status updates and notifications

**Report Types Supported:**
- `daily-report` - Comprehensive daily overview
- `health-report` - System health monitoring
- `ai-news` - AI news briefing
- `polymarket-daily` - Daily market briefing
- `polymarket-weekly` - Weekly market digest
- `task-list` - Task progress tracking
- `milestone-report` - Milestone achievements
- `summary-report` - Summary/overview report

## Design Principles

Inspired by Vercel Dashboard - Clean, Minimal, Professional

### Visual Hierarchy
```
1. Primary Heading (H1) - 2.5rem, gradient accent
   ├── Subtitle (H2 equivalent) - 1.2rem, muted
   └── Date/Time - 1.1rem, lighter

2. Section Heading (H2) - 1.6rem, left-aligned
   ├── Description - 1rem, muted
   └── Separator line

3. Card/Item Heading - 1.2rem-1.4rem
   ├── Subtle accent indicator
   └── Status badge (if applicable)

4. Body Content - 1rem, secondary text
   └── Data emphasis - 0.9rem, muted
```

### Color Palette (Vercel-Inspired)
```css
Primary Background: #000000 (pure black)
Secondary Background: #111111
Elevated Background: #18181B
Card Background: #0070F3 (Vercel blue)
Text Primary: #EAEAEA (Vercel white)
Text Secondary: #94A3B8 (muted blue-gray)
Text Muted: #5E6AD2 (dim blue-gray)
Accent Blue: #0070F3 (Vercel primary)
Accent Green: #39FF14 (success green)
Accent Yellow: #FFD800 (warning yellow)
Accent Red: #FF3B30 (error red)
Accent Purple: #7928CA (highlight purple)
Border Subtle: #313131
```

### Typography System
```css
Primary Font: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", sans-serif
Heading Weight: 700 (bold)
Body Weight: 400 (regular)
Code Font: "SF Mono", "Menlo", "Consolas", monospace
Spacing: 1.6 (comfortable)
Max Width: 1200px (content width)
```

## Workflow

### Phase 1: Data Collection
```
1. Identify report type
2. Collect required data
3. Validate data completeness
4. Transform data to standard format
```

### Phase 2: Template Selection
```
1. Choose appropriate template (daily, health, news, etc.)
2. Select data visualization type (cards, table, list, chart)
3. Configure sections and ordering
4. Add custom styling if needed
```

### Phase 3: HTML Generation
```
1. Generate HTML with unified template system
2. Apply Vercel-inspired design
3. Include inline CSS for portability
4. Optimize for email clients
5. Add meta tags for here.now
```

### Phase 4: Publishing
```
1. Publish to here.now
2. Generate shareable URL
3. Create email version (HTML)
4. Create Telegram version (compact text)
5. Store URL for reference
```

## HTML Template System

### Base Template Structure
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{TITLE}} - {{DATE}}</title>
    <meta name="description" content="{{DESCRIPTION}}">
    <style>{{CSS}}</style>
</head>
<body>
    <div class="container">
        {{HEADER}}
        {{STATS}}
        {{CONTENT}}
        {{FOOTER}}
    </div>
</body>
</html>
```

### Header Component
```html
<header class="header">
    <div class="header-brand">
        <span class="brand-icon">📊</span>
        <span class="brand-name">{{REPORT_TYPE}}</span>
    </div>
    <h1 class="header-title">{{MAIN_TITLE}}</h1>
    <div class="header-meta">
        <span class="date">{{DATE}}</span>
        <span class="separator">•</span>
        <span class="time">{{TIME}}</span>
    </div>
</header>
```

### Stats Cards Component
```html
<div class="stats-grid">
    {{#each STAT}}
    <div class="stat-card {{STATUS_CLASS}}">
        <div class="stat-value">{{VALUE}}</div>
        <div class="stat-label">{{LABEL}}</div>
        {{#if TREND}}
        <div class="stat-trend {{TrendDirection}}">{{TREND_ICON}} {{TREND_VALUE}}</div>
        {{/if}}
    </div>
    {{/each}}
</div>
```

### Data Visualization Components

**Cards (Primary):**
```html
<div class="card {{CARD_STATUS}}">
    <div class="card-header">
        <span class="card-icon">{{ICON}}</span>
        <h3 class="card-title">{{TITLE}}</h3>
        <span class="card-badge {{BADGE_CLASS}}">{{BADGE}}</span>
    </div>
    <div class="card-content">
        {{CONTENT}}
    </div>
</div>
```

**Table (Data-heavy):**
```html
<div class="table-container">
    <table class="data-table">
        <thead>
            <tr>
                {{#each HEADER}}
                <th>{{NAME}}</th>
                {{/each}}
            </tr>
        </thead>
        <tbody>
            {{#each ROW}}
            <tr {{#if HIGHLIGHT}}class="highlight"{{/if}}>
                {{#each CELL}}
                <td>{{VALUE}}</td>
                {{/each}}
            </tr>
            {{/each}}
        </tbody>
    </table>
</div>
```

**Timeline (Sequential):**
```html
<div class="timeline">
    {{#each EVENT}}
    <div class="timeline-item">
        <div class="timeline-marker"></div>
        <div class="timeline-content">
            <div class="timeline-time">{{TIME}}</div>
            <div class="timeline-title">{{TITLE}}</div>
            <div class="timeline-description">{{DESCRIPTION}}</div>
        </div>
    </div>
    {{/each}}
</div>
```

## Message Templates

### Email Template (HTML)
```html
<!DOCTYPE html>
<html>
<head>
    <style>
        /* Email-safe CSS */
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: #000000;
            color: #EAEAEA;
            line-height: 1.6;
            padding: 20px;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
        }
        .header {
            background: #0070F3;
            padding: 30px;
            text-align: center;
            border-radius: 8px;
        }
        .header h1 {
            color: white;
            margin: 0;
            font-size: 1.8rem;
        }
        .content {
            padding: 20px 0;
        }
        .cta-button {
            display: inline-block;
            background: #0070F3;
            color: white;
            padding: 12px 24px;
            border-radius: 6px;
            text-decoration: none;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>{{REPORT_TYPE}}</h1>
            <p style="color: white; margin: 10px 0 0 0;">{{DATE}}</p>
        </div>
        
        <div class="content">
            {{SUMMARY}}
        </div>
        
        <div style="text-align: center; margin-top: 30px;">
            <a href="{{HERE_NOW_URL}}" class="cta-button">
                View Full Report →
            </a>
        </div>
    </div>
</body>
</html>
```

### Telegram Template (Markdown)
```markdown
📊 {{REPORT_TYPE}} — {{DATE}}

{{#if SUMMARY}}
{{SUMMARY}}

{{/if}}

{{#if SECTIONS}}

{{#each SECTION}}
{{ICON}} **{{TITLE}}**
{{CONTENT}}

{{/each}}

{{/if}}

{{#if KEY_METRICS}}
**Key Metrics:**
{{#each METRIC}}
• {{NAME}}: {{VALUE}}
{{/each}}

{{/if}}

---

🌐 **Full Report:** {{HERE_NOW_URL}}
*Generated at {{TIMESTAMP}}*
```

## Output Generation

### Function: Generate Report
```bash
generate_report() {
    local type="$1"           # Report type: daily, health, news, etc.
    local data="$2"           # Data file or JSON
    local output_dir="$3"     # Output directory
    
    # Generate HTML
    local html_file="$output_dir/report-$(date +%Y-%m-%d).html"
    generate_html "$type" "$data" > "$html_file"
    
    # Publish to here.now
    cd "$output_dir"
    publish_to_here_now "$html_file"
    
    # Get URL
    local url=$(get_here_now_url)
    
    # Generate email
    generate_email "$type" "$data" "$url"
    
    # Generate telegram
    generate_telegram "$type" "$data" "$url"
    
    # Return URLs
    echo "$url"
}
```

## Usage Examples

### Example 1: Daily Comprehensive Report
```bash
# Generate daily report
generate_report daily \
    "$(collect_daily_data)" \
    "$HOME/.openclaw/workspace/daily-reports"

# Output:
# - HTML report published to here.now
# - Email sent to configured recipient
# - Telegram message sent
# - URLs returned
```

### Example 2: System Health Report
```bash
# Generate health report
generate_report health \
    "$(collect_health_data)" \
    "$HOME/.openclaw/workspace/system-health"

# Output:
# - Health dashboard with metric cards
# - Color-coded status indicators
# - Trend visualization
# - Email/Telegram with URLs
```

### Example 3: AI News Briefing
```bash
# Generate AI news
generate_report ai-news \
    "$(collect_ai_news)" \
    "$HOME/.openclaw/workspace/ai-news-daily-page"

# Output:
# - News items in card format
# - Category sections (announcements, research, industry, tools)
# - Compact Telegram with full HTML link
```

## Best Practices

### Data Visualization
- **Choose the right chart type** for your data
- **Keep it simple** - avoid over-complicating
- **Use color strategically** - only for emphasis
- **Add legends** - always explain what colors mean
- **Mobile-first** - optimize for small screens

### Accessibility
- **Semantic HTML** - use proper heading structure
- **Alt text** - for images and charts
- **Keyboard navigation** - support tab order
- **High contrast** - ensure text is readable
- **Screen reader friendly** - use ARIA labels

### Performance
- **Minimal CSS** - inline only, no external requests
- **Compressed** - gzip where supported
- **Lazy loading** - for large lists/tables
- **Optimized images** - use appropriate formats
- **CSP-friendly** - inline styles, no external scripts

### Email Compatibility
- **Client-safe CSS** - avoid modern features
- **Inline styles** - no external stylesheets
- **Table layouts** - use div tables for compatibility
- **Fallback fonts** - specify font stacks
- **Test in clients** - Gmail, Outlook, Apple Mail

## Quality Gates

### Before Publishing
- [ ] Content is complete and accurate
- [ ] Data is validated and clean
- [ ] Template is correct for report type
- [ ] Links are tested and working
- [ ] HTML renders correctly in browsers
- [ ] Email template is tested
- [ ] Telegram template is readable
- [ ] All sections are present

### After Publishing
- [ ] Verify here.now URL is accessible
- [ ] Test link in multiple email clients
- [ ] Check mobile responsiveness
- [ ] Verify all data displays correctly
- [ ] Confirm email delivery
- [ ] Confirm Telegram delivery
- [ ] Log URL for future reference

## File Structure

```
report-generator/
├── SKILL.md                    # This file
├── templates/
│   ├── base.html              # Base template
│   ├── daily-report.html     # Daily overview
│   ├── health-report.html      # Health dashboard
│   ├── ai-news.html           # AI news briefing
│   └── email.html             # Email template
├── styles/
│   └── main.css              # Unified CSS (Vercel-inspired)
├── scripts/
│   ├── generate.sh             # Main generator
│   ├── email-generator.sh      # Email template
│   └── telegram-generator.sh   # Telegram template
└── examples/
    ├── daily-report.json        # Sample data
    └── health-report.json       # Sample data
```

## Integration with Cron Jobs

Update existing cron jobs to use the new report generator:

```json
{
  "message": "Generate daily comprehensive report\n\nWORKFLOW:\n1. Collect data (system health, cron status, AI news, Polymarket, company progress)\n2. Generate report using report-generator skill:\n   ~/.openclaw/workspace/skills/report-generator/generate.sh daily '' '$HOME/.openclaw/workspace/daily-data.json' daily-reports\n\n3. Publish to here.now\n4. Generate email (HTML) and Telegram (compact) messages\n5. Send to both destinations\n\nOUTPUT:\n- Email: Full HTML report + here.now URL\n- Telegram: Compact overview + here.now URL\n- Status: '✅ Report sent to email and Telegram with here.now page'\n"
}
```

## References

### Design Inspiration
- [Vercel Dashboard](https://vercel.com/dashboard) - Clean, minimal, data-focused
- [Linear](https://linear.app) - Elegant project management
- [Notion](https://www.notion.so) - Clean content blocks
- [GitHub](https://github.com) - Developer-focused design

### Email Resources
- [MJML](https://mjml.io/) - Email markup language
- [HTML Email Boilerplate](https://github.com/leemunroe/responsive-html-email-template)
- [Can I Email](https://www.caniemail.com/) - CSS compatibility reference

### Documentation
- [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/HTML)
- [CSS-Tricks](https://css-tricks.com/) - CSS tips and tricks
- [A11Y Project](https://www.a11yproject.com/) - Accessibility resources

---

**Maintained by:** duyetbot — AI Employee 1 at Duet Company
**Last Updated:** February 25, 2026
