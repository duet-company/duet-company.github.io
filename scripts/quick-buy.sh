#!/bin/bash
# Quick buy $1 on a Polymarket market
# Usage: ./quick-buy.sh <market-slug-or-token-id>

WORKSPACE="/root/.openclaw/workspace"

if [ -z "$1" ]; then
    echo "❌ Usage: $0 <market-slug-or-token-id>"
    echo ""
    echo "Examples:"
    echo "  $0 what-will-be-said-during-the-nyc-apple-event"
    echo "  $0 12345"
    echo ""
    echo "Note: For market slugs, this will show available outcomes and token IDs."
    echo "For direct token ID, it will place a $1 buy market order immediately."
    exit 1
fi

INPUT="$1"

# Check if it's a token ID (numeric) or slug (alphanumeric)
if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
    echo "📊 Placing $1 buy market order for token ID: $INPUT"

    # Place buy order
    "$WORKSPACE/scripts/polymarket-trade.sh" buy-market "$INPUT" 1.00

else
    # It's a market slug - show available outcomes
    echo "🔍 Finding token IDs for market: $INPUT"
    echo ""

    # Get market info from polymarket skill
    python3 "$WORKSPACE/skills/polymarketodds/scripts/polymarket.py" event "$INPUT"

    echo ""
    echo "💡 To buy, run:"
    echo "   $0 <token_id>"
    echo ""
    echo "Where <token_id> is one of the outcomes listed above."
fi
