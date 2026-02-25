#!/bin/bash
set -e

# System Health Check HTML Generator
# Generates beautiful HTML report and publishes to here.now

DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="$HOME/.openclaw/workspace/system-health"
OUTPUT_FILE="$OUTPUT_DIR/health-$DATE.html"
STATE_FILE="$OUTPUT_DIR/.herenow/state.json"

mkdir -p "$OUTPUT_DIR/.herenow"

echo "Generating system health HTML..." > /dev/null

# Collect health metrics
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
MEMORY_USAGE=$(free -h | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1*100}' | awk '{printf "%.0f", $1}')
OPENCLAW_STATUS=$(systemctl --user is-active openclaw-gateway 2>&1 || echo "unknown")

# Determine health status
HEALTH_STATUS="healthy"
if [ ${DISK_USAGE%.*} -gt 80 ]; then
    HEALTH_STATUS="warning"
fi

if [ ${MEMORY_USAGE%.*} -gt 90 ]; then
    HEALTH_STATUS="critical"
fi

# Generate HTML report
cat > "$OUTPUT_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Health - $DATE</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        :root {
            --bg-primary: #0f172a;
            --bg-secondary: #1e293b;
            --bg-elevated: #334155;
            --text-primary: #f1f5f9;
            --text-secondary: #cbd5e1;
            --text-muted: #64748b;
            --success: #10b981;
            --warning: #f59e0b;
            --critical: #ef4444;
            --border: #334155;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Inter', system-ui, sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
            line-height: 1.6;
            min-height: 100vh;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            padding: 40px 20px;
        }
        header {
            text-align: center;
            padding: 60px 0;
            border-bottom: 1px solid var(--border);
            background: linear-gradient(135deg, #1e293b, #0f172a);
        }
        h1 {
            font-size: 2.5rem;
            font-weight: 700;
            margin-bottom: 12px;
            color: var(--text-primary);
        }
        .status-badge {
            display: inline-block;
            padding: 12px 32px;
            border-radius: 50px;
            font-size: 1.2rem;
            font-weight: 600;
            margin-top: 16px;
        }
        .status-healthy { background: var(--success); color: #000; }
        .status-warning { background: var(--warning); color: #000; }
        .status-critical { background: var(--critical); color: #fff; }
        .subtitle {
            font-size: 1.1rem;
            color: var(--text-muted);
            font-weight: 400;
            margin-top: 8px;
        }
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 24px;
            margin: 60px 0;
        }
        .metric-card {
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 32px 24px;
            text-align: center;
        }
        .metric-value {
            font-size: 3rem;
            font-weight: 700;
            margin-bottom: 12px;
            font-family: -apple-system, BlinkMacSystemFont, 'SF Mono', monospace;
        }
        .metric-value.disk { color: ${DISK_USAGE%.*} -gt 80 && echo "var(--critical)" || echo "var(--success)" }; }
        .metric-value.memory { color: ${MEMORY_USAGE%.*} -gt 90 && echo "var(--critical)" || echo "var(--success)" }; }
        .metric-label {
            font-size: 1rem;
            color: var(--text-muted);
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .service-status {
            background: var(--bg-elevated);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 28px;
            margin-bottom: 24px;
        }
        .service-status.active { border-left: 4px solid var(--success); }
        .service-status.inactive { border-left: 4px solid var(--critical); }
        .service-label {
            font-size: 1.2rem;
            font-weight: 600;
            margin-bottom: 12px;
            color: var(--text-primary);
        }
        .service-value {
            font-size: 1.1rem;
            color: var(--text-muted);
        }
        .section-title {
            font-size: 1.4rem;
            font-weight: 600;
            margin: 40px 0 24px;
            color: var(--text-primary);
        }
        .footer {
            text-align: center;
            padding: 50px 0;
            border-top: 1px solid var(--border);
            color: var(--text-muted);
            font-size: 0.9rem;
        }
        @media (max-width: 768px) {
            h1 { font-size: 1.8rem; }
            .metrics-grid { grid-template-columns: 1fr; }
            .metric-value { font-size: 2.5rem; }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🏥 SYSTEM HEALTH</h1>
            <div class="subtitle">Daily Check • $DATE</div>
            <div class="status-badge status-$HEALTH_STATUS">
                $(echo "$HEALTH_STATUS" | tr '[:lower:]' '[:upper:]')
            </div>
        </header>

        <div class="metrics-grid">
            <div class="metric-card">
                <div class="metric-value disk">$DISK_USAGE</div>
                <div class="metric-label">Disk Usage</div>
            </div>
            <div class="metric-card">
                <div class="metric-value memory">$MEMORY_USAGE</div>
                <div class="metric-label">Memory Usage</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$CPU_LOAD</div>
                <div class="metric-label">CPU Load</div>
            </div>
        </div>

        <div class="section-title">Services</div>
        <div class="service-status $([ "$OPENCLAW_STATUS" = "active" ] && echo "active" || echo "inactive")">
            <div class="service-label">OpenClaw Gateway</div>
            <div class="service-value">$OPENCLAW_STATUS</div>
        </div>

        <footer>
            <p>Generated by duyetbot — AI Employee 1 at Duet Company</p>
            <p style="margin-top: 8px;">System monitoring powered by OpenClaw</p>
            <p style="margin-top: 8px; color: var(--text-muted);">Checks run daily at 06:00 UTC</p>
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
    URL=$(python3 -c "import json; f=open('$STATE_FILE'); d=json.load(f); print(d.get('publishes', {}).get(list(d.keys())[0] if d.get('publishes') else 'N/A', {}).get('siteUrl', 'N/A'))" 2>/dev/null || echo "N/A")
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

# Output for cron (if issues exist)
ISSUES=""
if [ ${DISK_USAGE%.*} -gt 80 ]; then
    ISSUES="$ISSUES⚠️ Disk usage high: $DISK_USAGE
"
fi

if [ ${MEMORY_USAGE%.*} -gt 90 ]; then
    ISSUES="$ISSUES⚠️ Memory usage high: $MEMORY_USAGE
"
fi

if [ "$OPENCLAW_STATUS" != "active" ]; then
    ISSUES="$ISSUES❌ OpenClaw Gateway: $OPENCLAW_STATUS"
fi

if [ -n "$ISSUES" ]; then
    echo "⚠️ ISSUES DETECTED:"
    echo "$ISSUES"
    echo ""
    echo "Send email with: gog gmail send --to duyet.cs@gmail.com --subject '⚠️ System Health Alert' --body 'Health check at $DATE found issues. View details: $URL'"
else
    echo "✅ System healthy - no issues detected"
fi
