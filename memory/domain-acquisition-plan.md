# Domain Acquisition Action Plan: aidatalabs.ai

**Status:** 🚧 Ready for Execution
**Priority:** High (Blocker for website and email)
**Estimated Time:** 1-2 hours
**Assigned:** Awaiting human action

---

## Executive Summary

The domain `aidatalabs.ai` is currently unclaimed (no existing presence found on GitHub, LinkedIn, or Twitter). This document provides a complete step-by-step guide for acquisition.

---

## Step-by-Step Instructions

### Phase 1: Domain Search & Purchase (30-45 min)

#### Option A: Namecheap.com (RECOMMENDED)
**Why:** Best .ai pricing (~$70-100/year), excellent support, privacy included

1. **Create Account**
   - Visit: https://www.namecheap.com
   - Sign up for new account
   - Enable 2FA immediately (Settings > Security)

2. **Search Domain**
   - Enter: `aidatalabs.ai`
   - If available → proceed to purchase
   - If unavailable → try alternatives in order:
     - `aidatalabs.com`
     - `duet-data.ai`
     - `duetlabs.ai`

3. **Purchase Configuration**
   - Registration period: **5 years** (recommended for SEO and pricing lock)
   - Enable: **WHOIS Privacy Protection** (free)
   - Enable: **Auto-renewal**
   - Payment method: Use company card if available

#### Option B: Cloudflare Registrar
**Why:** At-cost pricing, great DNS management, integrated with our infrastructure

1. **Create Account**
   - Visit: https://dash.cloudflare.com/sign-up
   - Sign up for new account
   - Verify email

2. **Check & Purchase**
   - Navigate to Register Domain
   - Search: `aidatalabs.ai`
   - Purchase if available (Cloudflare sells at cost, ~$75/year)

---

### Phase 2: DNS Configuration (15-30 min)

**Goal:** Point domain to Cloudflare Workers (our future hosting)

#### After Purchase, Configure DNS:

1. **If using Namecheap:**
   - Go to Domain List > Advanced DNS
   - Add records:
     ```
     Type: A
     Host: @
     Value: 192.0.2.1 (placeholder, will update to actual Cloudflare IP)
     TTL: Automatic
     ```

2. **If using Cloudflare Registrar:**
   - DNS is automatically managed by Cloudflare
   - Add A record pointing to Cloudflare Workers IP

3. **Add Subdomain:**
   ```
   Type: CNAME
   Host: www
   Value: aidatalabs.ai
   TTL: Automatic
   ```

---

### Phase 3: Ownership Verification (10-15 min)

**Goal:** Verify domain with Google services

1. **Google Search Console**
   - Visit: https://search.google.com/search-console
   - Add property: `aidatalabs.ai`
   - Verification method: DNS record (recommended)
   - Add TXT record to DNS:
     ```
     Type: TXT
     Host: @
     Value: google-site-verification=YOUR_CODE_HERE
     ```

2. **Google Analytics**
   - Visit: https://analytics.google.com
   - Set up GA4 property
   - Copy tracking ID (G-XXXXXXXXXX)
   - Add to future website code

---

### Phase 4: Email Configuration (Optional, 15-20 min)

**Goal:** Set up company email (hello@aidatalabs.ai)

**Options:**
1. **Google Workspace** (6-12 USD/user/month)
2. **Fastmail** (5-10 USD/user/month)
3. **Zoho Mail** (Free tier available)

**Steps:**
1. Choose provider and create account
2. Add MX records to DNS:
   ```
   Type: MX
   Host: @
   Value: aspmx.l.google.com
   Priority: 1
   ```
3. Add SPF record:
   ```
   Type: TXT
   Host: @
   Value: v=spf1 include:_spf.google.com ~all
   ```

---

## Deliverables Checklist

- [ ] Domain purchased (`aidatalabs.ai`)
- [ ] Registration period: 5 years
- [ ] WHOIS privacy enabled
- [ ] Auto-renewal enabled
- [ ] 2FA enabled on registrar account
- [ ] A record configured (placeholder for now)
- [ ] CNAME for www configured
- [ ] Google Search Console verified
- [ ] Google Analytics set up
- [ ] Email MX records configured (optional)

---

## Security Notes

1. **Store credentials securely:**
   - Use password manager (1Password, Bitwarden)
   - Store in company vault
   - Share only with authorized team members

2. **Enable security:**
   - 2FA is mandatory on registrar account
   - Keep registrar email separate from domain email
   - Monitor for suspicious activity

3. **Document access:**
   - Create shared document with registrar login info
   - Store in Google Drive > Company > Infrastructure
   - Update whenever credentials change

---

## Cost Estimates

- **Domain registration:** $75-100/year × 5 years = **$375-500**
- **WHOIS privacy:** Included (Namecheap) or $12.95/year
- **Email service:** $60-144/year (Google Workspace, 1 user)

**Total First-Year Cost:** ~$435-650 (5-year domain + 1-year email)

---

## Next Steps After Purchase

1. Update this document with actual purchase details
2. Create PR to update `docs/playbook/business/company-setup.md`
3. Close Kanboard issue #2
4. Update MEMORY.md with company milestone
5. Announce to team via Telegram

---

## Troubleshooting

**Issue:** Domain taken
- **Solution:** Try alternatives: `aidatalabs.com`, `duet-data.ai`, `duetlabs.ai`

**Issue:** DNS not propagating
- **Solution:** Wait 24-48 hours, check with `dig aidatalabs.ai`

**Issue:** Email not working
- **Solution:** Verify MX records, check SPF/DMARC configuration

---

**Prepared by:** Duet Company AI Assistant
**Date:** 2026-03-22
**Reference:** Kanboard Issue #2
**SOP:** docs/playbook/business/company-setup.md
