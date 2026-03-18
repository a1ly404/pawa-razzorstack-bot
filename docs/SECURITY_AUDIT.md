# Pawa Security Audit Report

**Date:** March 18, 2026  
**Scope:** pawa-razzorstack-bot repository  
**Files Reviewed:** 11

---

## Summary

| Severity | Count | Status |
|----------|-------|--------|
| CRITICAL | 0 | N/A |
| HIGH | 4 | Action needed |
| MEDIUM | 6 | Review needed |
| LOW/INFO | 3 | Monitoring |

**No secrets leaked.** All credentials properly externalized to `.env` (gitignored).

---

## 1. Secrets Exposure: PASS

| Severity | Finding | Location | Details |
|----------|---------|----------|---------|
| OK | Secrets externalized | docker-compose.pawa.yml | `BOT_TOKEN` and `DB_PASSWORD` use env vars |
| OK | Caddyfile password hash externalized | caddy/pawa.caddyfile | Uses `{$PAWA_BASIC_AUTH_HASH}` env var |
| INFO | "Never commit real secrets" reminder | README.md | Good practice |

---

## 2. Docker Security

| Severity | Finding | Location | Fix |
|----------|---------|----------|-----|
| GOOD | Init process enabled | docker-compose.pawa.yml L7 | `init: true` — reaps zombie processes |
| MEDIUM | No explicit capability dropping | docker-compose.pawa.yml | Add `cap_drop: ["ALL"]` and `cap_add` as needed |
| HIGH | JVM internals opened unconditionally | docker-compose.pawa.yml L37 | `--add-opens=java.base/java.lang=ALL-UNNAMED` opens all internals; assess if Pawa needs this |
| GOOD | Resource limits enforced | docker-compose.pawa.yml L9-11 | CPU 1 core, memory 2GB |
| GOOD | Dependency on service health | docker-compose.pawa.yml L41-42 | Waits for `jellystat-db` healthy |
| MEDIUM | OOM crash on exit | docker-compose.pawa.yml L37 | `-XX:+CrashOnOutOfMemoryError` — consider restart orchestration |

---

## 3. Caddy/Web Security

| Severity | Finding | Location | Fix |
|----------|---------|----------|-----|
| GOOD | Basic auth configured | pawa.caddyfile L10-12 | Bcrypt hash, no plaintext |
| GOOD | X-Content-Type-Options | pawa.caddyfile L18 | `nosniff` set |
| GOOD | HTTP→HTTPS redirect | pawa.caddyfile L22-24 | Automatic |
| MEDIUM | CSP uses 'unsafe-inline' | pawa.caddyfile L17 | Replace with: `"default-src 'self'; script-src 'self'; style-src 'self'"` |
| HIGH | Missing HSTS header | pawa.caddyfile | Add: `Strict-Transport-Security "max-age=31536000; includeSubDomains"` |
| HIGH | Missing X-Frame-Options | pawa.caddyfile | Add: `X-Frame-Options "SAMEORIGIN"` |
| MEDIUM | Missing Referrer-Policy | pawa.caddyfile | Add: `Referrer-Policy "no-referrer"` |
| MEDIUM | Missing Permissions-Policy | pawa.caddyfile | Add: `Permissions-Policy "geolocation=(), microphone=(), camera=()"` |

---

## 4. Supply Chain / GitHub Actions

| Severity | Finding | Location | Fix |
|----------|---------|----------|-----|
| HIGH | Actions not pinned to commit SHA | check-pawa-update.yml | Pin `imjasonh/setup-crane`, `actions/checkout`, `peter-evans/create-pull-request` to SHA |
| MEDIUM | No image vulnerability scanning | check-pawa-update.yml | Add `trivy image` scan step |
| GOOD | Dependabot configured | dependabot.yml | Weekly GH Actions updates |

---

## 5. Database Security

| Severity | Finding | Location | Fix |
|----------|---------|----------|-----|
| MEDIUM | Shared Postgres credentials with Jellystat | docker-compose.pawa.yml L24-27 | Create separate `PAWA_POSTGRES_USER` |
| MEDIUM | ALL PRIVILEGES granted | postgres-initdb/create-pawa-db.sh L9 | Limit to CREATE, CONNECT, USAGE |
| GOOD | Credentials via env vars | docker-compose.pawa.yml | Properly implemented |

---

## 6. File Permissions & Scripts

| Severity | Finding | Location |
|----------|---------|----------|
| OK | No hardcoded secrets in scripts | deploy-pawa.sh, pawa_retention_cleanup.py |
| INFO | Username in default path | pawa_retention_cleanup.py L14 — `/home/daffy/pawa-recordings` |
| OK | Scripts not setuid | scripts/ |

---

## 7. Dependency & Image Security

| Severity | Finding | Fix |
|----------|---------|-----|
| MEDIUM | Docker image not SHA-pinned | Pin to `@sha256:...` digest |
| GOOD | Distroless base image | Smaller attack surface |
| MEDIUM | No CVE scanning in CI | Add trivy/grype step |
| GOOD | Automated version checks | Weekly check + PR creation |

---

## Priority Action Items

### Immediate (This week)
1. Add missing security headers to pawa.caddyfile (HSTS, X-Frame-Options, Referrer-Policy, Permissions-Policy)
2. Pin GitHub Actions to commit SHAs

### Short-term (Next 2 weeks)
3. Add image vulnerability scanning (trivy) to CI workflow
4. Create separate Postgres user for Pawa
5. Restrict database user privileges

### Medium-term (This month)
6. Review JVM security flags with Pawa upstream
7. Pin Docker image to SHA256 digest
8. Remove 'unsafe-inline' from CSP

---

## 10 Future Enhancements

1. **Automatic audio transcription** — Integrate OpenAI Whisper or self-hosted whisper-standalone to auto-transcribe recordings into searchable text. Store transcripts in Postgres alongside metadata.

2. **Recording search & full-text indexing** — Add search to pawa.razzormail.com by speaker name, date, duration, or transcribed text. Use Postgres full-text search.

3. **Recording sharing with expiring links** — Generate time-limited URLs for sharing individual recordings with non-authenticated users. Include QR codes for mobile.

4. **Multi-track audio export** — Export individual per-speaker tracks + metadata (timestamps, speaker names) for post-production editing.

5. **Automatic Discord thread archival** — Create Discord threads with recording metadata (duration, speaker count, timestamp) automatically linked to searchable archives.

6. **Storage tiering / cloud archive** — Archive old recordings to S3/Backblaze B2 with on-demand retrieval. Implement hot/cold retention policies.

7. **Speaker detection & diarization** — Use pyannote.audio for automatic speaker identification and labeling in multi-speaker recordings.

8. **Webhook notifications** — Send Discord embeds on recording start/stop/completion with metadata, links, and transcripts.

9. **Recording quality metrics** — Display bitrate, sample rate, audio levels, clipping detection on the web UI.

10. **Backup/replication to NAS** — Auto-sync completed recordings to the Synology NAS (Nancy at 192.168.1.100) with intelligent deduplication.
