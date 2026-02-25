#!/bin/bash
# Monitor Polymarket positions and provide sell recommendations

echo "📊 Polymarket Position Monitor"
echo "================================"
echo ""

# Apple Event (bought at 84%, currently ~70%)
echo "🍎 Apple Intelligence 5+ times"
echo "   Bought: 80¢ (6.3 shares) = \$5.04"
python3 /root/.openclaw/workspace/skills/polymarketodds/scripts/polymarket.py event what-will-be-said-during-the-nyc-apple-event | grep -A 2 "Apple Intelligence 5+ times"
echo ""
echo "   💡 SELL IF:"
echo "      - Price drops below 60¢ (cut losses)"
echo "      - Price rises above 85¢ (take profit)"
echo "      - Price is 74-80¢ on event day (recovery opportunity)"
echo ""

# AI Model Markets - check current state
echo "🤖 AI Model Positions"
echo ""
echo "🔵 Google Best AI Model (Feb 2026)"
echo "   Bought: 42¢ (4.8 shares) = \$2.02"
echo "   Current: ~3.2¢ (severe loss)"
echo "   💡 SELL IF:"
echo "      - Price rises above 30¢ (cut losses at 29% of original)"
echo "      - Otherwise: hold until resolution (HODL)"
echo ""

echo "🔷 DeepSeek Best AI Model (Feb 2026)"
echo "   Bought: 0.8¢ (13.0 shares) = \$0.10"
echo "   Current: ~0.3¢ (severe loss)"
echo "   💡 SELL IF:"
echo "      - Price rises above 0.6¢ (cut losses at 75% of original)"
echo "      - Otherwise: hold until resolution (HODL)"
echo ""

# Summary
echo "================================"
echo "📈 CURRENT RECOMMENDATIONS:"
echo ""
echo "🍎 APPLE EVENT: 🟡 HOLD - Monitor closely, alert if hits 85%"
echo "   - Event in 1 week - time for recovery!"
echo "   - Set limit order at 85¢ if possible"
echo ""
echo "🤖 AI MODELS: 🔴 CUT LOSSES or HODL"
echo "   - Down >90% - unlikely to recover"
echo "   - Option 1: Sell now to cut losses (~\$0.18 remaining)"
echo "   - Option 2: HODL until February 28 resolution (all or nothing)"
echo ""
echo "₿ BITCOIN DAILY: ⚠️ CHECK RESOLUTION"
echo "   - Market should have resolved on Feb 22, 3AM ET"
echo "   - Check if Bitcoin went UP - if so, collect winnings!"
echo ""
