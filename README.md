# pawa-razzorstack-bot

Self-hosted [Pawa](https://gitlab.com/pawabot/pawa) Discord voice recording bot — configured for the [razzorstack](https://github.com/a1ly404/razzorstack) media server stack.

Pawa records Discord voice channels and saves them as MP3 files. Recordings are browseable via a password-protected web file browser.

> **Upstream project:** [gitlab.com/pawabot/pawa](https://gitlab.com/pawabot/pawa) — see the [Pawa README](https://gitlab.com/pawabot/pawa/-/blob/master/README.md) and [Changelog](https://gitlab.com/pawabot/pawa/-/blob/master/CHANGELOG.md) for full documentation.

## Slash Commands

Once the bot is in your server, these slash commands are available:

| Command | Description |
|---------|-------------|
| `/record` | Join your voice channel and start recording |
| `/save` | Finalize and upload the recording as an MP3 to the text channel |
| `/stop` | Stop recording and leave the voice channel |
| `/recover` | Recover a failed recording using a Session ID |
| `/autorecord` | Automatically start recording when someone joins a voice channel |
| `/autostop` | Automatically stop when the voice channel empties |
| `/autosave` | Automatically save recordings (on by default for self-hosted) |
| `/info` | Display recording info and guild settings |
| `/volume` | Adjust recording volume |
| `/lang` | Change the bot's language |
| `/ignore` | Exclude specific users or bots from the recording |
| `/alias` | Set command aliases |

Prefix commands (`!record`, `!save`, `!stop`, etc.) are also enabled.

## Default Options

These are the defaults configured in `docker-compose.pawa.yml`:

| Setting | Value | Description |
|---------|-------|-------------|
| `BOT_FILE_FORMAT` | `mp3` | Output format for recordings |
| `BOT_RECORDER_TYPE` | `QUEUE` | BlockingQueue recorder — more stable than LEGACY (no deadlocks) |
| `BOT_MP3_VBR` | `0` | Constant bitrate (CBR) for consistent quality |
| `BOT_STANDALONE` | `true` | Self-hosted mode (no cloud features) |
| `BOT_PREFIX_COMMANDS` | `true` | Enable `!record` / `!save` / `!stop` prefix commands |
| `BOT_LEAVE_GUILD_AFTER` | `0` | Never auto-leave inactive guilds |
| `BOT_ACTIVITY` | `Voice Recording` | Bot status shown in Discord |
| `BOT_MAINTENANCE` | `false` | Not in maintenance mode |
| `BOT_WEBSITE` | `https://pawa.razzormail.com` | Recording file browser URL |

## What's in this repo

| File | Purpose |
|------|---------|
| `docker-compose.pawa.yml` | Docker service definition (included by parent compose) |
| `.env.example` | All Pawa-specific environment variables |
| `postgres-initdb/create-pawa-db.sh` | Auto-creates `pawa` database on first Postgres init |
| `scripts/pawa_retention_cleanup.py` | Delete oldest recordings when exceeding a disk cap |
| `caddy/pawa.caddyfile` | [Caddy](https://caddyserver.com/) config for the recording file browser with basic auth |
| `docs/SETUP.md` | Full setup guide and troubleshooting |

## Discord Developer Portal Setup

### 1. Bot Settings

In [discord.com/developers/applications](https://discord.com/developers/applications) → your Pawa app → **Bot**:

| Setting | Value | Why |
|---------|-------|-----|
| **Public Bot** | ❌ Unchecked | Private — only you can invite it |
| **Message Content Intent** | ✅ Enabled | Required for `!record` / `!save` prefix commands |
| **Server Members Intent** | ❌ Not needed | |
| **Presence Intent** | ❌ Not needed | |

### 2. Installation Settings

Go to **Installation** (left sidebar):

| Setting | Value |
|---------|-------|
| **Authorization Method** | None |

> Setting this to "None" is required when Public Bot is unchecked. Use the custom invite URL below instead.

### 3. Bot Permissions

The bot needs these Discord permissions to function:

| Permission | Integer | Required For |
|------------|---------|-------------|
| View Channel | `1024` | See text and voice channels |
| Send Messages | `2048` | Post recording notifications and MP3 files |
| Embed Links | `16384` | Recording info embeds (`/info`, recording details) |
| Attach Files | `32768` | Upload MP3 recordings to the text channel |
| Connect | `1048576` | Join voice channels to record |
| Speak | `2097152` | Required by Discord for voice channel interaction |
| Use Voice Activity | `33554432` | Receive audio from voice channel participants |
| Change Nickname | `67108864` | Set `[REC]` prefix while actively recording |

**Total permission integer:** `2251344896`

### 4. Invite URL (Private Bot)

Since Public Bot is unchecked, use this URL to add the bot to your server:

```
https://discord.com/oauth2/authorize?client_id=1483327849124335646&permissions=2251344896&scope=bot+applications.commands
```

### 5. Channel Permissions

After inviting, ensure the bot role has these permissions in any channel it will use:

- ✅ View Channel
- ✅ Send Messages
- ✅ Attach Files
- ✅ Embed Links
- ✅ Change Nickname
- ✅ Connect (voice channels)
- ✅ Speak (voice channels)
- ✅ Use Voice Activity (voice channels)

> If the bot shows "CANNOT WRITE" as its nickname, it's missing Send Messages or Change Nickname in that channel.

## Quick Start

This repo is consumed as a git submodule by razzorstack:

```bash
cd /path/to/razzorstack
git submodule update --init docker/pawa
```

The parent `docker-compose.yml` includes this via:
```yaml
include:
  - path: pawa/docker-compose.pawa.yml
```

## Configuration

Copy the variables from `.env.example` into the parent `docker/.env`:

```bash
# Required
PAWA_BOT_TOKEN=your_discord_bot_token       # https://discord.com/developers/applications
PAWA_VERSION=2.17.0-be7c1c2b

# Recording file browser (pawa.razzormail.com)
PAWA_BASIC_AUTH_USER=your_username
PAWA_BASIC_AUTH_HASH=your_bcrypt_hash        # Generate: docker exec caddy caddy hash-password --plaintext 'PASSWORD'

# Storage
PAWA_RECORDINGS_PATH=/path/to/recordings     # Host path for recording files
```

See [docs/SETUP.md](docs/SETUP.md) for the full setup guide, troubleshooting, and Discord permissions.

## Docker Image

[`registry.gitlab.com/pawabot/pawa:2.17.0-be7c1c2b`](https://gitlab.com/pawabot/pawa/container_registry) — Kotlin/JVM, Java 25, distroless container.

## License

This deployment configuration is provided as-is. Pawa itself is licensed under the [Apache License 2.0](https://gitlab.com/pawabot/pawa/-/blob/master/LICENSE).
