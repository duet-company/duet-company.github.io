# 🚀 Polymarket Trading Bot - Quick Start Guide

## ✅ Setup Complete!

Your Polymarket trading bot is now installed and configured with:
- Python virtual environment with all dependencies
- CLOB API client (`py-clob-client`)
- Trading scripts (buy, sell, cancel)
- Automated monitoring (every 6 hours)

## 📋 Next Steps

### 1. Add Your API Credentials

Edit `~/.openclaw/.env` and add:

```bash
# Your Polymarket private key (from https://polymarket.com/settings)
POLYMARKET_PRIVATE_KEY=your_private_key_here

# Optional: Funder address (only for email/Magic wallets)
# POLYMARKET_FUNDER=0x_your_funder_address
```

**How to get your private key:**
1. Go to https://polymarket.com
2. Go to Settings → API Keys
3. Generate/export your private key
4. Paste into `.env` file

### 2. Test Connection

```bash
# Test without trading (just check connection)
/root/.openclaw/workspace/scripts/polymarket-trade.sh orders
```

If you see "✅ Connected to Polymarket CLOB API", you're ready!

### 3. Start Trading

#### Quick Buy $1 (Market Order)

```bash
# Find token ID first
/root/.openclaw/workspace/scripts/quick-buy.sh "what-will-be-said-during-the-nyc-apple-event"

# Then buy with token ID (example)
/root/.openclaw/workspace/scripts/polymarket-trade.sh buy-market 12345 1.00
```

#### Buy at Specific Price (Limit Order)

```bash
# Buy Apple Intelligence at 75¢ or better
/root/.openclaw/workspace/scripts/polymarket-trade.sh buy-limit TOKEN_ID 0.75 1.33
```

#### Sell Your Position

```bash
# Sell all shares at market price
/root/.openclaw/workspace/scripts/polymarket-trade.sh sell-market TOKEN_ID 1.33
```

#### Set Take Profit

```bash
# Place sell order at your target price
/root/.openclaw/workspace/scripts/polymarket-trade.sh sell-limit TOKEN_ID 0.85 1.33
```

## 📊 Monitoring Your Positions

Your bot automatically monitors your positions every 6 hours and alerts you when:

- ✅ Price hits your sell target (take profit)
- ⚠️ Price drops below your stop loss level
- 📈 Significant price movement (>10%)
- 🔔 Market resolution

Check your monitoring script:
```bash
/root/.openclaw/workspace/scripts/polymarket-monitor.sh
```

## 🎯 Trading Workflow

### For Your Current Positions:

1. **Apple Intelligence (bought at 80¢, now ~70%)**
   ```bash
   # Set take profit at 85¢
   /root/.openclaw/workspace/scripts/polymarket-trade.sh sell-limit TOKEN_ID 0.85 1.25

   # Or cut losses at 60¢
   /root/.openclaw/workspace/scripts/polymarket-trade.sh sell-limit TOKEN_ID 0.60 1.25
   ```

2. **AI Model Markets (Google/DeepSeek)**
   ```bash
   # These are down 90%+ - consider selling or holding to resolution
   # HODL until February 28 (all or nothing)
   ```

3. **Bitcoin Daily (resolved)**
   - Check your Polymarket account for winnings
   - If Bitcoin went UP today, you should have won!

## 📱 Telegram Alerts

You'll receive automated alerts via Telegram for:
- New sell signals
- Market resolutions
- Significant price movements

## 🔧 Available Commands

```bash
# Buy $1 market order
/root/.openclaw/workspace/scripts/polymarket-trade.sh buy-market <token_id> 1.00

# Buy limit order (at specific price)
/root/.openclaw/workspace/scripts/polymarket-trade.sh buy-limit <token_id> <price> [size]

# Sell market order (immediate)
/root/.openclaw/workspace/scripts/polymarket-trade.sh sell-market <token_id> <size>

# Sell limit order (take profit)
/root/.openclaw/workspace/scripts/polymarket-trade.sh sell-limit <token_id> <price> [size]

# Cancel all orders
/root/.openclaw/workspace/scripts/polymarket-trade.sh cancel-all

# View open orders
/root/.openclaw/workspace/scripts/polymarket-trade.sh orders

# View recent trades
/root/.openclaw/workspace/scripts/polymarket-trade.sh positions

# Quick helper to find token IDs
/root/.openclaw/workspace/scripts/quick-buy.sh <market-slug>
```

## 📚 Documentation

Full documentation available at:
- `/root/.openclaw/workspace/scripts/POLYMARKET_TRADING.md`

## ⚠️ Important Notes

1. **Never commit `.env` to git** - contains your private key!
2. **Start small** - Test with $1-$5 trades first
3. **Check token allowances** - If using MetaMask, approve tokens first
4. **Only trade what you can afford to lose** - Prediction markets are risky!
5. **Market resolves at YES/NO** - No partial payouts

## 🆘 Troubleshooting

**"POLYMARKET_PRIVATE_KEY not found"**
→ Add your private key to `~/.openclaw/.env`

**"Error setting API credentials"**
→ Verify your private key is correct (no `0x` prefix)

**"Order rejected"**
→ Check USDC balance and token allowances

**Need help finding token IDs?**
→ Use quick-buy.sh to see market outcomes and token IDs

## 🎉 You're Ready!

Once you've added your API credentials to `.env`, you can:
- Buy limit orders at specific prices
- Buy market orders for immediate execution
- Sell positions with limit or market orders
- Manage orders (cancel, list)
- Monitor positions automatically

Happy trading! 🚀
