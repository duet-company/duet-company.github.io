# Daily Report System

## Overview
Generates comprehensive daily reports with Telegram overview and detailed HTML page published to here.now.

## Current Status
✅ **Fully Working** - System generates and publishes reports correctly

## Published URL
🔗 **https://spicy-zephyr-mx35.here.now/**

## Features
- ✅ System health monitoring (disk, memory, OpenClaw status)
- ✅ Cron job status tracking
- ✅ Polymarket trending data
- ✅ Duet Company GitHub activity
- ✅ Blog post tracking (last 7 days)
- ✅ Automatic here.now publishing (authenticated, permanent)
- ✅ Telegram-friendly overview format
- ✅ Responsive HTML design (mobile-friendly)

## Design
**Clean, Professional Aesthetic:**
- Light color scheme (#f5f5f5 background, white cards)
- Simple typography (system fonts, no fancy effects)
- Business-like layout (clear sections, good hierarchy)
- Readable on all devices (mobile responsive)
- High contrast text (dark gray on light backgrounds)
- Color-coded status indicators (green/yellow/red)

## Scripts
- `generate-report.sh` - Main report generator
- Cron job: `daily-comprehensive-report` (runs 7:30 AM UTC)

## File Structure
```
~/.openclaw/workspace/daily-reports/
├── index.html              # Full detailed HTML report
├── telegram-overview.md    # Quick Telegram summary
├── data/                  # JSON data for dynamic loading
│   ├── cron.json
│   ├── polymarket.json
│   ├── company.json
│   └── blog.json
├── .tracking.json          # Tracks actual slug for updates
└── README.md              # This file
```

## Usage
```bash
# Generate and publish report
~/.openclaw/workspace/scripts/daily-reports/generate-report.sh

# Or wait for cron (7:30 AM UTC daily)
```

## Cron Job
The cron job `daily-comprehensive-report` runs this script daily at 7:30 AM UTC.
You can check its status with:
```bash
openclaw cron list | grep daily-comprehensive
```

The job payload includes all workflow instructions and documentation references.

## Data Collected
1. **System Health**
   - Disk usage across all mounts
   - Memory usage (used/total)
   - OpenClaw Gateway service status

2. **Cron Job Status**
   - All scheduled jobs
   - Last run status
   - Next run timestamp

3. **Polymarket Data**
   - Top trending markets
   - Volume and price info

4. **Duet Company Progress**
   - Recent GitHub activity
   - Repository update timestamps

5. **Blog Posts**
   - New posts in last 7 days
   - Filenames and dates

## Output
### Telegram Overview
Compact format suitable for Telegram mobile:
- System health summary
- Key highlights
- Link to detailed report
- Generated timestamp

### HTML Report
Full interactive report with:
- Responsive design
- Dynamic data loading (JSON)
- Color-coded status indicators
- Professional layout matching clean aesthetic
- Mobile-friendly viewing

## Authentication
Uses authenticated here.now publishing (API key: ~/.herenow/credentials)
- Permanent storage (no 24h expiry)
- No claim token required for updates
- Uses actual slug for updates

## Troubleshooting

### If publish fails:
1. Check API key exists: `cat ~/.herenow/credentials`
2. Verify network connectivity
3. Check disk space
4. Run manually for debugging

### If data missing:
1. Check Python3 is installed
2. Verify GitHub CLI is configured
3. Check Polymarket script exists
4. Verify blog directory path
