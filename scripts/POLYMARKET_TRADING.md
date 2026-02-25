# Polymarket Trading Bot Setup

## Overview

Automated trading bot for Polymarket prediction markets using the CLOB API. Supports limit orders, market orders, and position management.

## Setup

### 1. Get API Credentials

You need one of the following:

**Option A: Private Key (Recommended for EOA wallets)**
- Export your wallet's private key from Polymarket.com
- See: https://docs.polymarket.com/authentication

**Option B: Email/Magic Wallet**
- Export your private key from Polymarket.com
- You'll also need your funder address

### 2. Configure Environment Variables

Edit `~/.openclaw/.env`:

```bash
# Required: Private key
POLYMARKET_PRIVATE_KEY=your_private_key_here

# Optional: Funder address (for email/Magic wallets)
POLYMARKET_FUNDER=0x_your_funder_address
```

### 3. Find Token IDs

Use the find-token script to get token IDs for markets:

```bash
# Find Apple Event market
python3 /root/.openclaw/workspace/scripts/find-token.py --search "apple event"

# Search for Bitcoin markets
python3 /root/.openclaw/workspace/scripts/find-token.py --search "bitcoin"
```

**Alternative:** Get token ID from market page URL:
1. Go to market on polymarket.com
2. Inspect page or use Gamma API
3. Find the `token_id` for the specific outcome you want

## Usage

### Buy Limit Order

Buy at specific price or better:

```bash
/root/.openclaw/workspace/scripts/polymarket-trade.sh buy-limit <token_id> <price> [size]

# Example: Buy Apple Intelligence at 80¢ for $1.00
/root/.openclaw/workspace/scripts/polymarket-trade.sh buy-limit 12345 0.80 1.25
```

### Buy Market Order

Buy immediately at current market price by dollar amount:

```bash
/root/.openclaw/workspace/scripts/polymarket-trade.sh buy-market <token_id> <amount>

# Example: Buy $1 worth of Bitcoin YES
/root/.openclaw/workspace/scripts/polymarket-trade.sh buy-market 67890 1.00
```

### Sell Limit Order

Sell at specific price or better:

```bash
/root/.openclaw/workspace/scripts/polymarket-trade.sh sell-limit <token_id> <price> [size]

# Example: Sell Apple Intelligence at 85¢
/root/.openclaw/workspace/scripts/polymarket-trade.sh sell-limit 12345 0.85 1.25
```

### Sell Market Order

Sell immediately at current market price:

```bash
/root/.openclaw/workspace/scripts/polymarket-trade.sh sell-market <token_id> <size>

# Example: Sell all shares
/root/.openclaw/workspace/scripts/polymarket-trade.sh sell-market 12345 1.25
```

### Cancel Orders

```bash
# Cancel specific order
/root/.openclaw/workspace/scripts/polymarket-trade.sh cancel <order_id>

# Cancel all open orders
/root/.openclaw/workspace/scripts/polymarket-trade.sh cancel-all
```

### Check Orders & Positions

```bash
# List open orders
/root/.openclaw/workspace/scripts/polymarket-trade.sh orders

# List recent trades/positions
/root/.openclaw/workspace/scripts/polymarket-trade.sh positions
```

## Active Trading Workflow

The bot is configured for active trading with automated monitoring:

### Current Positions Being Monitored

1. **Apple Intelligence 5+ times** (token: from find-token script)
   - Bought: 80¢ (6.3 shares)
   - Current: ~70%
   - Strategy: Hold until 85¢ or sell at 60¢

2. **Google Best AI Model** (February 2026)
   - Bought: 42¢ (4.8 shares)
   - Current: ~3.2¢ (severe loss)
   - Strategy: HODL until resolution

3. **DeepSeek Best AI Model** (February 2026)
   - Bought: 0.8¢ (13.0 shares)
   - Current: ~0.3¢ (severe loss)
   - Strategy: HODL until resolution

### Automated Monitoring

- **Frequency:** Every 6 hours
- **Actions:**
  - Check positions against sell criteria
  - Alert when price hits targets
  - Execute sell orders when conditions met

### Trading Strategies

**Limit Orders:**
- Use for taking profit at specific prices
- Set sell targets at resistance levels
- Buy at support levels

**Market Orders:**
- Use for immediate entry/exit
- Best for high-volume markets
- Higher cost due to slippage

**Position Sizing:**
- Start small ($1-$5 per trade)
- Scale in on confirmation
- Never risk more than 10% of portfolio

## Common Operations

### Quick Buy $1

```bash
# Replace TOKEN_ID with actual token ID
/root/.openclaw/workspace/scripts/polymarket-trade.sh buy-market TOKEN_ID 1.00
```

### Quick Sell Position

```bash
# Cancel any existing limit orders first
/root/.openclaw/workspace/scripts/polymarket-trade.sh cancel-all

# Sell all shares at market price
/root/.openclaw/workspace/scripts/polymarket-trade.sh sell-market TOKEN_ID <size>
```

### Set Take Profit

```bash
# Place sell limit order at target price
/root/.openclaw/workspace/scripts/polymarket-trade.sh sell-limit TOKEN_ID 0.85 1.25
```

### Set Stop Loss

```bash
# Place sell limit order below current price
/root/.openclaw/workspace/scripts/polymarket-trade.sh sell-limit TOKEN_ID 0.60 1.25
```

## Token Allowances (MetaMask/EOA Users)

If using MetaMask or hardware wallet, you must set token allowances BEFORE trading:

1. Approve USDC for exchange contracts
2. Approve Conditional Tokens for exchange contracts

See: https://github.com/Polymarket/py-clob-client#token-allowances

Email/Magic wallet users: Allowances are set automatically!

## Troubleshooting

**"POLYMARKET_PRIVATE_KEY not found"**
- Add your private key to `~/.openclaw/.env`
- Make sure it's not preceded by `0x`

**"Error setting API credentials"**
- Verify your private key is correct
- Check if you need a funder address (email wallets)

**"Order rejected"**
- Check token allowances
- Verify you have sufficient USDC balance
- Ensure token ID is correct and active

**"Market not found"**
- Verify market is still active
- Use find-token.py to get correct token ID
- Check market hasn't resolved yet

## Security Notes

- 🔐 Never commit `.env` to git
- 🔐 Use environment variables, not hardcoded keys
- 🔐 Rotate keys periodically
- 🔐 Only trade with funds you can afford to lose

## API Documentation

- Polymarket CLOB API: https://docs.polymarket.com/trading/clob
- Gamma Markets API: https://docs.polymarket.com/developers/gamma-markets-api
- Python Client: https://github.com/Polymarket/py-clob-client
