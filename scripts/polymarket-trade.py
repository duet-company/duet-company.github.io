#!/usr/bin/env python3
"""
Polymarket Trading Bot
Buy/sell orders via Polymarket CLOB API
"""

import os
import sys
import json
from dotenv import load_dotenv
from py_clob_client.client import ClobClient
from py_clob_client.clob_types import OrderArgs, MarketOrderArgs, OpenOrderParams
from py_clob_client.order_builder.constants import BUY, SELL

# Load environment variables
load_dotenv()

HOST = "https://clob.polymarket.com"
CHAIN_ID = 137
PRIVATE_KEY = os.getenv("POLYMARKET_PRIVATE_KEY") or os.getenv("POLYMARKET_API_KEY")
FUNDER = os.getenv("POLYMARKET_FUNDER_ADDRESS") or os.getenv("POLYMARKET_FUNDER")

# Determine signature type
SIGNATURE_TYPE = 1  # Default to email/Magic wallet (most common)

def create_client():
    """Initialize Polymarket CLOB client"""
    if not PRIVATE_KEY:
        print("❌ Error: POLYMARKET_PRIVATE_KEY or POLYMARKET_API_KEY not found in .env")
        sys.exit(1)

    client = ClobClient(
        HOST,
        key=PRIVATE_KEY,
        chain_id=CHAIN_ID,
        signature_type=SIGNATURE_TYPE,
        funder=FUNDER
    )

    # Set API credentials
    try:
        creds = client.create_or_derive_api_creds()
        client.set_api_creds(creds)
        print("✅ Connected to Polymarket CLOB API")
        return client
    except Exception as e:
        print(f"❌ Error setting API credentials: {e}")
        sys.exit(1)

def buy_limit(client, token_id, price, size=1.0):
    """Place a buy limit order"""
    try:
        order = OrderArgs(
            token_id=token_id,
            price=price,
            size=size,
            side=BUY
        )
        signed_order = client.create_order(order)
        resp = client.post_order(signed_order)

        print(f"✅ Buy limit order placed:")
        print(f"   Token ID: {token_id}")
        print(f"   Price: ${price}")
        print(f"   Size: {size}")
        print(f"   Order ID: {resp.get('order_id', 'N/A')}")
        print(f"   Cost: ${float(price) * float(size):.2f}")
        return resp
    except Exception as e:
        print(f"❌ Error placing buy order: {e}")
        return None

def buy_market(client, token_id, amount):
    """Place a buy market order (by dollar amount)"""
    try:
        order = MarketOrderArgs(
            token_id=token_id,
            amount=float(amount),
            side=BUY
        )
        signed_order = client.create_market_order(order)
        resp = client.post_order(signed_order)

        print(f"✅ Buy market order placed:")
        print(f"   Token ID: {token_id}")
        print(f"   Amount: ${amount}")
        print(f"   Order ID: {resp.get('order_id', 'N/A')}")
        return resp
    except Exception as e:
        print(f"❌ Error placing market buy order: {e}")
        return None

def sell_limit(client, token_id, price, size=1.0):
    """Place a sell limit order"""
    try:
        order = OrderArgs(
            token_id=token_id,
            price=price,
            size=size,
            side=SELL
        )
        signed_order = client.create_order(order)
        resp = client.post_order(signed_order)

        print(f"✅ Sell limit order placed:")
        print(f"   Token ID: {token_id}")
        print(f"   Price: ${price}")
        print(f"   Size: {size}")
        print(f"   Order ID: {resp.get('order_id', 'N/A')}")
        print(f"   Expected: ${float(price) * float(size):.2f}")
        return resp
    except Exception as e:
        print(f"❌ Error placing sell order: {e}")
        return None

def sell_market(client, token_id, size):
    """Place a sell market order (by share count)"""
    try:
        order = MarketOrderArgs(
            token_id=token_id,
            amount=float(size),
            side=SELL
        )
        signed_order = client.create_market_order(order)
        resp = client.post_order(signed_order)

        print(f"✅ Sell market order placed:")
        print(f"   Token ID: {token_id}")
        print(f"   Size: {size} shares")
        print(f"   Order ID: {resp.get('order_id', 'N/A')}")
        return resp
    except Exception as e:
        print(f"❌ Error placing market sell order: {e}")
        return None

def cancel_order(client, order_id):
    """Cancel a specific order"""
    try:
        resp = client.cancel(order_id)
        print(f"✅ Order cancelled: {order_id}")
        return resp
    except Exception as e:
        print(f"❌ Error cancelling order: {e}")
        return None

def cancel_all(client):
    """Cancel all open orders"""
    try:
        resp = client.cancel_all()
        print(f"✅ All orders cancelled")
        return resp
    except Exception as e:
        print(f"❌ Error cancelling all orders: {e}")
        return None

def get_open_orders(client):
    """Get all open orders"""
    try:
        orders = client.get_orders(OpenOrderParams())
        print(f"\n📋 Open Orders ({len(orders)} total):")
        for i, order in enumerate(orders, 1):
            side = "BUY" if order.get("side") == "BUY" else "SELL"
            price = order.get("price", "N/A")
            size = order.get("original_size", "N/A")
            filled = order.get("filled_size", 0)
            print(f"\n   {i}. {side} {order.get('token_id')}")
            print(f"      Price: ${price}")
            print(f"      Size: {size} (filled: {filled})")
            print(f"      Order ID: {order.get('id')}")
        return orders
    except Exception as e:
        print(f"❌ Error getting orders: {e}")
        return []

def get_positions(client):
    """Get current positions (from trades)"""
    try:
        trades = client.get_trades()
        print(f"\n💰 Recent Trades ({len(trades)} total):")
        for i, trade in enumerate(trades[-10:], 1):  # Last 10 trades
            side = "BUY" if trade.get("side") == "BUY" else "SELL"
            price = trade.get("price", "N/A")
            size = trade.get("size", "N/A")
            print(f"\n   {i}. {side}")
            print(f"      Price: ${price}")
            print(f"      Size: {size}")
            print(f"      Token: {trade.get('token_id')}")
        return trades
    except Exception as e:
        print(f"❌ Error getting positions: {e}")
        return []

def main():
    """Main CLI interface"""
    if len(sys.argv) < 2:
        print("""
📊 Polymarket Trading Bot

Usage:
  python3 polymarket-trade.py <command> [options]

Commands:
  buy-limit <token_id> <price> [size]    - Buy limit order (default size: 1.0)
  buy-market <token_id> <amount>          - Buy market order by $ amount
  sell-limit <token_id> <price> [size]   - Sell limit order (default size: 1.0)
  sell-market <token_id> <size>           - Sell market order by share count
  cancel <order_id>                      - Cancel specific order
  cancel-all                            - Cancel all open orders
  orders                                - List open orders
  positions                             - List recent trades/positions

Environment Variables Required:
  POLYMARKET_PRIVATE_KEY or POLYMARKET_API_KEY
  POLYMARKET_FUNDER (optional, for proxy wallets)

Examples:
  python3 polymarket-trade.py buy-limit 12345 0.85 1.0
  python3 polymarket-trade.py buy-market 12345 1.00
  python3 polymarket-trade.py sell-limit 12345 0.90 1.0
  python3 polymarket-trade.py cancel-all
  python3 polymarket-trade.py orders
        """)
        sys.exit(1)

    command = sys.argv[1].lower()
    client = create_client()

    if command == "buy-limit":
        if len(sys.argv) < 4:
            print("Usage: buy-limit <token_id> <price> [size]")
            sys.exit(1)
        token_id = sys.argv[2]
        price = float(sys.argv[3])
        size = float(sys.argv[4]) if len(sys.argv) > 4 else 1.0
        buy_limit(client, token_id, price, size)

    elif command == "buy-market":
        if len(sys.argv) < 4:
            print("Usage: buy-market <token_id> <amount>")
            sys.exit(1)
        token_id = sys.argv[2]
        amount = float(sys.argv[3])
        buy_market(client, token_id, amount)

    elif command == "sell-limit":
        if len(sys.argv) < 4:
            print("Usage: sell-limit <token_id> <price> [size]")
            sys.exit(1)
        token_id = sys.argv[2]
        price = float(sys.argv[3])
        size = float(sys.argv[4]) if len(sys.argv) > 4 else 1.0
        sell_limit(client, token_id, price, size)

    elif command == "sell-market":
        if len(sys.argv) < 4:
            print("Usage: sell-market <token_id> <size>")
            sys.exit(1)
        token_id = sys.argv[2]
        size = float(sys.argv[3])
        sell_market(client, token_id, size)

    elif command == "cancel":
        if len(sys.argv) < 3:
            print("Usage: cancel <order_id>")
            sys.exit(1)
        order_id = sys.argv[2]
        cancel_order(client, order_id)

    elif command == "cancel-all":
        cancel_all(client)

    elif command == "orders":
        get_open_orders(client)

    elif command == "positions":
        get_positions(client)

    else:
        print(f"❌ Unknown command: {command}")
        print("Run without arguments to see usage")

if __name__ == "__main__":
    main()
