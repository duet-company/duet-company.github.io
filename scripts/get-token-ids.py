#!/usr/bin/env python3
"""
Extract Polymarket token IDs from events - for trading
"""

import requests
import json
import sys

def get_token_ids(market_slug):
    """Get clobTokenIds for all markets in an event"""
    
    url = f"https://gamma-api.polymarket.com/events?slug={market_slug}"
    
    try:
        resp = requests.get(url, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        
        if isinstance(data, dict):
            events = data.get('data', [])
        elif isinstance(data, list):
            events = data
        else:
            print(f"❌ Unexpected format")
            return {}
        
        if not events:
            print(f"❌ No event found")
            return {}
        
        event = events[0]
        markets = event.get('markets', [])
        
        print(f"\n🎯 {event.get('title', 'Unknown')}")
        print("=" * 70)
        
        tokens = {}
        
        for m in markets:
            question = m.get('question', 'N/A')
            clob_token_ids = m.get('clobTokenIds', [])
            outcomes = m.get('outcomes', [])
            outcome_prices = m.get('outcomePrices', [])
            
            # Map outcomes to token IDs
            if clob_token_ids and len(clob_token_ids) == len(outcomes):
                print(f"\n{question[:70]}")
                print("-" * 70)
                
                for i, (outcome, token_id, price_str) in enumerate(zip(outcomes, clob_token_ids, outcome_prices)):
                    price = float(price_str) * 100
                    tokens[outcome] = {
                        'token_id': token_id,
                        'price_pct': price,
                        'price': price_str
                    }
                    
                    print(f"  {outcome}")
                    print(f"    Token ID: {token_id}")
                    print(f"    Price: {price:.1f}% (${float(price_str):.4f})")
                    print()
            
        print("=" * 70)
        print(f"\n📋 TRADING READY - Token IDs:\n")
        for outcome, data in tokens.items():
            print(f"{data['token_id']}  # {outcome} - ${data['price']:.4f}")
        
        return tokens
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return {}

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 get-token-ids.py <market-slug>")
        sys.exit(1)
    
    market_slug = sys.argv[1]
    get_token_ids(market_slug)
