# Pawa Voice Recording Bot — Setup & Troubleshooting

## Current Status: Fully Operational

The bot records audio, persists to disk, and recordings are browseable at `pawa.razzormail.com`.
Slash commands (`/record`, `/save`, `/stop`, `/recover`) are registered and functional.

**Image**: `registry.gitlab.com/pawabot/pawa:2.17.0-be7c1c2b` (latest CI build, March 15 2026)

---

## Setup History

- [x] Docker service configured (`docker-compose.pawa.yml`)
- [x] Fixed OTEL agent crash (`OTEL_JAVAAGENT_ENABLED=false` + `--add-opens`)
- [x] Fixed `DS_BUCKET` storage path — recordings persist to `$PAWA_RECORDINGS_PATH/datastore/`
- [x] Enabled MESSAGE CONTENT INTENT in Discord Developer Portal
- [x] Bot connects to Discord Gateway — "Connected to 1 guilds!"
- [x] Slash commands registered (record, stop, save, recover, autorecord, autostop, etc.)
- [x] Test recording successful: 48s from @Lyla, 752KB MP3, QUEUE recorder
- [x] `BOT_LEAVE_GUILD_AFTER=0` — disabled auto-leave for inactive guilds
- [x] `pawa.razzormail.com` — Recording file browser via Caddy `file_server browse` with basic auth
- [x] SSL certificate auto-provisioned via Let's Encrypt + Cloudflare DNS challenge

---

## TODO — User Action Required

### 1. Fix Discord Channel Permissions (BLOCKING)
The bot shows "CANNOT WRITE" and renames itself because it lacks permissions in `#Test-pawa`.

**Steps:**
1. Right-click `#Test-pawa` channel → **Edit Channel** → **Permissions**
2. Click **+** → Add the bot role (or "Eod audio recorder")
3. Enable these permissions:
   - ✅ View Channel
   - ✅ Send Messages
   - ✅ Attach Files
   - ✅ Embed Links (for recording info embeds)
   - ✅ Change Nickname (so bot can set [REC] prefix while recording)
4. Save Changes
5. Right-click the bot → rename from "CANNOT WRITE" back to its real name
6. Test with `/record` in `#Test-pawa`

### 2. Invite Bot to Target Server (for meetings)
```
https://discord.com/oauth2/authorize?client_id=1483327849124335646&scope=applications.commands+bot&permissions=2251328512
```

### 3. Browse Recordings
- URL: `https://pawa.razzormail.com`
- Login: credentials set via `PAWA_BASIC_AUTH_USER` / `PAWA_BASIC_AUTH_HASH` in `docker/.env`

### 4. Set Up Retention Cleanup (Optional)
```bash
# Preview what would be cleaned (250GB cap)
python3 scripts/pawa_retention_cleanup.py --dry-run

# Crontab for weekly cleanup
# 0 3 * * 0 cd /home/daffy/Tools/razzorstack/docker/pawa && python3 scripts/pawa_retention_cleanup.py --limit-gb 250
```

---

## Configuration Reference

| Setting | Value | Location |
|---------|-------|----------|
| Docker image | `registry.gitlab.com/pawabot/pawa:2.17.0-be7c1c2b` | `docker/.env` |
| Bot token | `PAWA_BOT_TOKEN` | `docker/.env` |
| Recordings (host) | `$PAWA_RECORDINGS_PATH/datastore/` | Volume mount |
| Recordings (container) | `/data/datastore/` | `DS_BUCKET` env var |
| Recording file browser | `https://pawa.razzormail.com` | Caddy file_server |
| Browser login | Set via `PAWA_BASIC_AUTH_USER` / `PAWA_BASIC_AUTH_HASH` | `docker/.env` |
| Database | H2 embedded at `/data/embedded-database/` | Auto-managed |
| Recorder type | QUEUE | `BOT_RECORDER_TYPE` |
| File format | mp3 | `BOT_FILE_FORMAT` |
| Auto-leave | Disabled | `BOT_LEAVE_GUILD_AFTER=0` |
| App ID | 1483327849124335646 | Discord Dev Portal |

## Troubleshooting

**"CANNOT WRITE"**: Bot lacks Send Messages permission in the channel. Fix channel permissions.

**"Application did not respond"**: Check `docker compose logs pawa --tail 50` for exceptions.

**Recordings not persisting**: Verify `DS_BUCKET=/data/datastore` in compose and that `$PAWA_RECORDINGS_PATH/datastore/` has files after recording.

**Bot leaves server automatically**: Set `BOT_LEAVE_GUILD_AFTER=0` in compose environment.
