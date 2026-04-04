# HEARTBEAT.md

## Fuel Price Monitoring (Vietnam)
- Use web_fetch on https://vnexpress.net/chu-de/gia-xang-dau-3026 (extractMode: text, maxChars: 2000)
- Extract prices for RON 95-III, E5 RON 92-II, Diesel
- Compare with memory/tracking/fuel-prices.md
- If ANY price changed: update file + notify Duyệt + update chart HTML + re-publish
- If no change: stay silent (HEARTBEAT_OK)
- Late night (23:00-08:00): skip check unless urgent
