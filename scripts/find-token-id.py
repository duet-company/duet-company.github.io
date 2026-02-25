#!/usr/bin/env python3
"""
Find Polymarket token IDs by searching for active markets
"""

import requests
import json
import sys

def find_token_by_outcome(market_slug, outcome_name):
    """Find token ID for a specific outcome in a market"""
    
    # Try to get event by slug
    url = f"https://gamma-api.polymarket.com/events?slug={market_slug}"
    
    try:
        resp = requests.get(url, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        
        # Handle response format
        if isinstance(data, dict):
            events = data.get('data', [])
        elif isinstance(data, list):
            events = data
        else:
            print(f"❌ Unexpected response format: {type(data)}")
            return None
        
        if not events:
            print(f"❌ No event found for slug: {market_slug}")
            return None
        
        event = events[0]
        markets = event.get('markets', [])
        
        print(f"\n🎯 Event: {event.get('title', 'Unknown')}")
        print(f"   Slug: {event.get('slug', 'N/A')}")
        print(f"   Markets: {len(markets)}\n")
        
        # Search through all markets and tokens
        for m_idx, market in enumerate(markets, 1):
            question = market.get('question', 'N/A')
            tokens = market.get('tokens', [])
            
            print(f"Market {m_idx}: {question[:60]}")
            
            for t_idx, token in enumerate(tokens, 1):
                outcome = token.get('outcome', 'N/A')
                token_id = token.get('token_id', 'N/A')
                price = float(token.get('price', 0)) * 100
                
                print(f"  {t_idx}. {outcome}")
                print(f"     Token ID: {token_id}")
                print(f"     Price: {price:.1f}%")
                print()
            
        return event
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error fetching market: {e}")
        return None
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return None

def search_markets(query, limit=10):
    """Search for markets by query string"""
    
    url = f"https://gamma-api.polymarket.com/markets?query={query}&limit={limit}"
    
    try:
        resp = requests.get(url, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        
        # Handle response format
        if isinstance(data, dict):
            markets = data.get('data', [])
        elif isinstance(data, list):
            markets = data
        else:
            print(f"❌ Unexpected response format: {type(data)}")
            return []
        
        print(f"\n🔍 Search Results for: '{query}'")
        print(f"Found {len(markets)} markets\n")
        
        for i, market in enumerate(markets, 1):
            question = market.get('question', 'N/A')
            slug = market.get('slug', 'N/A')
            tokens = market.get('tokens', [])
            
            print(f"{i}. {question[:70]}")
            print(f"   Slug: {slug}")
            
            if tokens:
                for t in tokens[:3]:  # Show first 3 tokens
                    outcome = t.get('outcome', 'N/A')
                    token_id = t.get('token_id', 'N/A')
                    price = float(t.get('price', 0)) * 100
                    
                    print(f"   - {outcome}: {price:.1f}% (Token: {token_id})")
            print()
        
        return markets
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error searching markets: {e}")
        return []
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return []

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("""
🔍 Polymarket Token Finder

Usage:
  python3 find-token-id.py <command> [arguments]

Commands:
  find <market-slug>            - Find all tokens for a specific market
  search <query>                 - Search for markets by keyword

Examples:
  python3 find-token-id.py find what-will-be-said-during-the-nyc-apple-event
  python3 find-token-id.py search bitcoin
  python3 find-token-id.py search apple intelligence
        """)
        sys.exit(1)
    
    command = sys.argv[1].lower()
    
    if command == "find":
        if len(sys.argv) < 3:
            print("Usage: find <market-slug>")
            sys.exit(1)
        
        market_slug = sys.argv[2]
        find_token_by_outcome(market_slug, None)
    
    elif command == "search":
        if len(sys.argv) < 3:
            print("Usage: search <query>")
            sys.exit(1)
        
        query = sys.argv[2]
        search_markets(query, limit=10)
    
    else:
        print(f"❌ Unknown command: {command}")
        print("Use 'find' or 'search'")
