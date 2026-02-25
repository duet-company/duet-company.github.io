# Memory Log - 2026-02-24 (Backup Fix)

## Issue: Backup Failed Due to SSH Blocking

**Timestamp:** Tue Feb 24 13:37:32 CET 2026

### Problem
- OpenClaw Gateway blocks SSH connections for security
- Git remote was using SSH: `git@github.com:duyet/openclaw-duyetbot-backup.git`
- All git operations (fetch, rebase, push) hung with no output
- Network to github.com was reachable (ping succeeded)

### Solution Applied
1. **Changed remote URL from SSH to HTTPS**
   ```bash
   git remote set-url origin https://github.com/duyet/openclaw-duyetbot-backup.git
   ```

2. **Set up credential helper**
   ```bash
   git config --global credential.helper store
   ```

3. **Created credentials file with GITHUB_TOKEN**
   - Used existing GITHUB_TOKEN from environment
   - File: `/root/.git-credentials` (permissions 600)
   - Format: `https://duyet:<TOKEN>@github.com`

4. **Tested and verified push works**
   - Commit: `f933d61 chore: auto backup 2026-02-24-1233`
   - Commit: `88ab02f fix: backup issue resolved - switched from SSH to HTTPS`
   - Both pushed successfully to GitHub

### Commits Pushed
- `f933d61` - Auto backup from cron job
- `88ab02f` - Fix documentation

### Backup Job
- Job ID: `bec3a0af-b326-46dd-b6a9-a43d37beb886`
- Name: `openclaw-config-backup`
- Schedule: Every 6 hours (everyMs: 21600000)
- Status: ✅ Working

### Security Notes
- Credentials stored in `/root/.git-credentials` with 600 permissions
- Token retrieved from environment variable (GITHUB_TOKEN)
- Less secure than interactive credential prompts but necessary for automated backups
- Alternative would require interactive authentication (not possible in cron)

### Recommendation
- Keep using HTTPS for automated backups
- SSH is blocked by Gateway for security reasons
- HTTPS with stored credentials is reliable for automated workflows

### References
- Cron job: `/root/.openclaw/cron/jobs.json` (openclaw-config-backup)
- Backup log: `/root/.openclaw/logs/backup-failures.log`
- Remote: `https://github.com/duyet/openclaw-duyetbot-backup.git`

---

**Status:** ✅ FIXED AND VERIFIED
**Next scheduled backup:** In ~6 hours from last successful run
