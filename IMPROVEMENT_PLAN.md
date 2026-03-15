# Website Improvement Plan - bot.duyet.net (Duet Company)

**Date:** 2026-03-15
**Status:** In Progress

## Executive Summary

This document outlines a comprehensive improvement plan for the Duet Company website (bot.duyet.net/duet-company.github.io) to enhance content quality, user experience, performance, and functionality.

---

## Phase 1: Critical Improvements (Week 1-2)

### 1.1 Content Enhancements

**Priority: HIGH**

#### Issues Identified:
- Hero section copy is generic and lacks compelling value proposition
- Missing proof points, testimonials, or case studies
- "14 day free trial" CTA seems arbitrary - no clear product tiers
- Team section mentions "Founded by AI" but lacks human credibility
- Contact email is placeholder (hello@duet-company.dev) - may not be monitored

#### Recommendations:

**Hero Section:**
- Add quantified metrics from actual platform usage
- Include customer logos or success stories (even hypothetical beta users)
- More specific value proposition: "From 0 to production analytics in < 10 minutes"
- Add social proof badge: "Trusted by X early adopters"

**Product Section:**
- Add specific performance benchmarks (e.g., "1 billion rows, <100ms query")
- Include real platform screenshots (not generic SVG)
- Add pricing tiers with clear differentiation
- Add feature comparison table vs. competitors

**Team Section:**
- Add founder bio (Duyet) for credibility
- Balance AI agent focus with human leadership
- Include photos or avatars (even generated)

**Contact Section:**
- Add working contact form
- Include multiple contact channels (email, Discord, Twitter)
- Add response time commitment (e.g., "We respond within 24 hours")

### 1.2 Technical & Performance

**Priority: HIGH**

#### Issues Identified:
- No meta description tag for SEO
- No Open Graph tags for social sharing
- No structured data (JSON-LD)
- Google Fonts requests could be optimized (self-host or font-display: swap)
- No service worker for offline capability
- No analytics tracking (Google Analytics, Plausible, etc.)
- Large CSS in `<style>` tag (not optimized)

#### Recommendations:

**SEO & Meta:**
```html
<meta name="description" content="AI Data Labs: Autonomous data infrastructure powered by AI. Get production-grade analytics without engineers. 14-day free trial.">
<meta property="og:title" content="AI Data Labs - Data Infrastructure, Built by AI">
<meta property="og:description" content="Autonomous ClickHouse clusters, natural language to SQL, and AI agents that handle everything.">
<meta property="og:image" content="/og-image.png">
<meta property="og:type" content="website">
<meta property="og:url" content="https://bot.duyet.net">
<link rel="canonical" href="https://bot.duyet.net">
```

**Structured Data:**
```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "AI Data Labs",
  "applicationCategory": "BusinessApplication",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD"
  }
}
</script>
```

**Performance:**
- Extract CSS to separate file and minify
- Add font-display: swap to Google Fonts
- Add service worker for PWA capabilities
- Implement lazy loading for images
- Add subresource integrity for external resources

### 1.3 Accessibility

**Priority: MEDIUM**

#### Issues Identified:
- No ARIA labels on interactive elements
- No skip navigation link
- Color contrast may be insufficient in some areas
- No focus-visible states
- Heading hierarchy may need review

#### Recommendations:
- Add `:focus-visible` styles for keyboard navigation
- Add skip link for keyboard users
- Ensure WCAG 2.1 AA contrast compliance
- Add `aria-label` to icon-only buttons
- Review and fix heading hierarchy

---

## Phase 2: Feature Additions (Week 3-4)

### 2.1 Blog Section

**Priority: MEDIUM**

**Additions:**
- Blog listing page with latest posts
- Individual blog post pages
- RSS feed
- Reading time estimates
- Related posts section
- Social sharing buttons

**Implementation:**
- Create `/blog/index.html` listing page
- Convert existing blog markdown files to HTML
- Add blog navigation to header
- Add blog card to homepage

### 2.2 Interactive Demo

**Priority: MEDIUM**

**Additions:**
- Embedded SQL playground (ClickHouse demo)
- Natural language to SQL demo
- Interactive dashboard preview
- Try-it-now button for quick signup

### 2.3 Documentation

**Priority: HIGH**

**Additions:**
- `/docs` section with comprehensive documentation
- API reference
- Getting started guide
- FAQ section
- Changelog/release notes

### 2.4 Pricing Page

**Priority: HIGH**

**Additions:**
- Clear pricing tiers (Free, Pro, Enterprise)
- Feature comparison table
- FAQ about pricing
- Contact sales for enterprise

---

## Phase 3: Advanced Features (Week 5-6)

### 3.1 Authentication & User Dashboard

**Priority: LOW**

**Additions:**
- User authentication (OAuth or email/password)
- User dashboard
- Account settings
- Usage metrics
- Billing management

### 3.2 Internationalization

**Priority: LOW**

**Additions:**
- Vietnamese language support
- Language switcher
- i18n infrastructure

### 3.3 Marketing Features

**Priority: MEDIUM**

**Additions:**
- Newsletter signup
- Lead capture form
- Referral program
- Affiliate links

---

## Phase 4: Ongoing Maintenance

### 4.1 Content Updates
- Weekly blog posts from AI agents
- Regular feature updates
- Case studies from beta users
- Press mentions and media coverage

### 4.2 Performance Monitoring
- Core Web Vitals tracking
- Lighthouse audits monthly
- Error tracking (Sentry)
- Uptime monitoring

### 4.3 SEO Optimization
- Monthly SEO audit
- Backlink building
- Content optimization
- Technical SEO updates

---

## Implementation Priority Matrix

| Feature | Impact | Effort | Priority |
|---------|--------|--------|----------|
| SEO meta tags | High | Low | P0 |
| Contact form | High | Low | P0 |
| Pricing page | High | Medium | P0 |
| Blog section | Medium | Medium | P1 |
| Interactive demo | High | High | P1 |
| Documentation | High | Medium | P1 |
| Analytics tracking | Medium | Low | P1 |
| User dashboard | Medium | High | P2 |
| Internationalization | Low | High | P2 |

---

## Success Metrics

### Engagement
- Time on site: > 2 minutes
- Bounce rate: < 60%
- Pages per session: > 2

### Conversion
- Sign-up rate: > 5%
- Trial-to-paid conversion: > 10%
- Contact form submissions: > 3/week

### Technical
- Lighthouse Performance score: > 90
- Lighthouse Accessibility score: > 95
- Lighthouse SEO score: > 100

---

## Next Steps (Immediate)

1. **Today:**
   - Add SEO meta tags
   - Add Open Graph tags
   - Fix contact section with working form
   - Add analytics tracking

2. **This Week:**
   - Create pricing page
   - Improve hero section with better copy
   - Add documentation section
   - Fix accessibility issues

3. **Next Week:**
   - Create blog section
   - Add structured data
   - Implement performance optimizations
   - Add interactive demo

---

## Notes

- All improvements should maintain the existing design aesthetic (dark mode, modern CSS)
- Use the same color palette and typography (Inter + Clash Display)
- Ensure mobile responsiveness is maintained
- Keep file sizes minimal for fast loading
- Test cross-browser compatibility (Chrome, Firefox, Safari, Edge)

---

**Last Updated:** 2026-03-15
**Next Review:** 2026-03-22
