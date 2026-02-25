#!/usr/bin/env python3
"""
Quick token ID finder - shows just the token IDs for a market
"""

import requests
import json
import sys

def get_market_tokens(market_slug):
    """Get all tokens for a market, return as simple dict"""
    
    url = f"https://gamma-api.polymarket.com/events?slug={market_slug}"
    
    try:
        resp = requests.get(url, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        
        # Response can be dict or list
        if isinstance(data, dict) and 'data' in data:
            events = data['data']
        elif isinstance(data, list):
            events = data
        else:
            print(f"❌ Unexpected response format: {type(data)}")
            return {}
        
        if not events:
            print(f"❌ No event found")
            return {}
        
        event = events[0]
        markets = event.get('markets', [])
        tokens = {}
        
        print(f"\n🎯 {event.get('title', 'Unknown')}\n")
        print("=" * 70)
        
        for market in markets:
            for token in market.get('tokens', []):
                outcome = token.get('outcome', 'N/A')
                token_id = token.get('token_id')
                price = float(token.get('price', 0)) * 100
                
                tokens[outcome] = {
                    'token_id': token_id,
                    'price_pct': price,
                    'price': token.get('price')
                }
                
                print(f"{outcome:30s}")
                print(f"  Token ID: {token_id}")
                print(f"  Price: {price:.1f}% (${token.get('price'):.4f})")
                print()
        
        print("=" * 70)
        print(f"Total: {len(tokens)} outcomes\n")
        
        # Print easy-to-use format
        print("📋 Token IDs (for trading):\n")
        for outcome, data in tokens.items():
            print(f"{data['token_id']}  # {outcome}")
        
        return tokens
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return {}

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 token-ids.py <market-slug>")
        sys.exit(1)
    
    market_slug = sys.argv[1]
    get_market_tokens(market_slug)
