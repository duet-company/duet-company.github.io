#!/usr/bin/env python3
"""
Find Polymarket token IDs from market slugs
"""

import requests

def find_market(slug=None, query=None):
    """Find market token ID from slug or search query"""
    try:
        if slug:
            # Get specific market by slug
            resp = requests.get(
                "https://gamma-api.polymarket.com/markets",
                params={"slug": slug}
            )
        else:
            # Search markets
            resp = requests.get(
                "https://gamma-api.polymarket.com/markets",
                params={"query": query, "limit": 10}
            )

        if resp.status_code != 200:
            print(f"❌ API Error: {resp.status_code}")
            return

        data = resp.json()

        # Handle different response structures
        if isinstance(data, dict):
            markets = data.get("data", [])
        elif isinstance(data, list):
            markets = data
        else:
            print(f"❌ Unexpected response structure: {type(data)}")
            return

        if not markets:
            print("❌ No markets found")
            return

        print(f"\n🔍 Found {len(markets)} market(s):\n")

        for i, market in enumerate(markets, 1):
            print(f"{i}. {market.get('question', 'N/A')}")
            print(f"   Slug: {market.get('slug', 'N/A')}")
            print(f"   Token ID: {market.get('tokens', [{}])[0].get('token_id', 'N/A') if market.get('tokens') else 'N/A'}")
            print(f"   Status: {market.get('status', 'N/A')}")
            print(f"   End Date: {market.get('end_date_iso', 'N/A')}\n")

            # Show tokens if available
            if market.get('tokens'):
                print("   Outcomes:")
                for token in market.get('tokens', []):
                    price = token.get('price', 0)
                    print(f"      - {token.get('outcome', 'N/A')}: {price*100:.1f}% (${price:.2f})")
                    print(f"        Token ID: {token.get('token_id', 'N/A')}")
                print()

    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("""
🔍 Polymarket Token ID Finder

Usage:
  python3 find-token.py --slug <market-slug>
  python3 find-token.py --search <query>

Examples:
  python3 find-token.py --slug what-will-be-said-during-the-nyc-apple-event
  python3 find-token.py --search apple intelligence
  python3 find-token.py --search bitcoin
        """)
        sys.exit(1)

    if sys.argv[1] == "--slug":
        if len(sys.argv) < 3:
            print("Usage: --slug <market-slug>")
            sys.exit(1)
        find_market(slug=sys.argv[2])

    elif sys.argv[1] == "--search":
        if len(sys.argv) < 3:
            print("Usage: --search <query>")
            sys.exit(1)
        find_market(query=sys.argv[2])

    else:
        print("❌ Unknown option. Use --slug or --search")
