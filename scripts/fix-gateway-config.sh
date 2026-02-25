#!/bin/bash
# Gateway Configuration Helper
# Add origins to allowlist for Control UI access

echo "Gateway Configuration Helper"
echo "==========================="
echo ""

# Add origins to Gateway allowlist
echo "This will add your origins to the Gateway allowlist."
echo ""
echo "Adding origins:"
echo "  - https://openclaw.duyet.net/chat"
echo "  - https://openclaw.dingo-mora.ts.net/chat"
echo ""

# Method 1: Try using openclaw gateway CLI
echo "Attempting to configure Gateway via CLI..."
if command -v openclaw &>/dev/null; then
    # Check if openclaw gateway supports config modification
    openclaw gateway --help 2>&1 | grep -q "config" && {
        echo "Gateway CLI supports config commands"
        echo "You may need to run these commands yourself:"
        echo ""
        echo "# Try each method:"
        echo "openclaw gateway config set gateway.controlUi.allowedOrigins '[\"https://openclaw.duyet.net/chat\",\"https://openclaw.dingo-mora.ts.net/chat\"]'"
        echo ""
        echo "# Then restart:"
        echo "openclaw gateway restart"
    } || {
        echo "Gateway CLI doesn't support direct config modification"
        echo "See manual configuration steps below"
    }
else
    echo "OpenClaw CLI not found in PATH"
fi

echo ""
echo "==================================================="
echo "Manual Configuration Steps:"
echo "==================================================="
echo ""
echo "1. Find Gateway configuration file:"
echo "   Locations to check:"
echo "   - ~/.openclaw/gateway/config.json"
echo "   - ~/.openclaw/gateway/.env"
echo "   - /etc/openclaw/gateway/config.json"
echo ""
echo "2. Edit configuration file:"
echo "   Add to the 'gateway.controlUi.allowedOrigins' array:"
echo '   "gateway.controlUi.allowedOrigins": ['
echo '     "https://openclaw.duyet.net/chat",'
echo '     "https://openclaw.dingo-mora.ts.net/chat"'
echo '   ]'
echo ""
echo "3. Restart Gateway:"
echo "   systemctl --user restart openclaw-gateway"
echo "   OR"
echo "   openclaw gateway restart"
echo ""
echo "==================================================="
echo "Verification Commands:"
echo "==================================================="
echo ""
echo "# After configuration, verify with:"
echo "openclaw gateway config | grep -A5 'controlUi.allowedOrigins'"
echo ""
echo "# Test access:"
echo "curl https://openclaw.duyet.net/chat"
echo ""
echo "==================================================="

exit 0
