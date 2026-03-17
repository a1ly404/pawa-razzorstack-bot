# pawa-razzorstack-bot

Discord voice recording bot (Pawa) configuration for the razzorstack media server stack.

Used as a **git submodule** at `docker/pawa/` in [razzorstack](https://github.com/a1ly404/razzorstack).

## What's in this repo

| File | Purpose |
|------|---------|
| `docker-compose.pawa.yml` | Docker service definition (included by parent compose) |
| `.env.example` | Pawa-specific environment variables |
| `postgres-initdb/create-pawa-db.sh` | Auto-creates `pawa` database on first Postgres init |
| `scripts/pawa_retention_cleanup.py` | Delete oldest recordings when exceeding disk cap |
| `caddy/pawa.caddyfile` | Caddy config snippet for recording file browser |
| `docs/SETUP.md` | Full setup guide and troubleshooting |

## Quick Start

This repo is consumed as a submodule by razzorstack:

```bash
cd /home/daffy/Tools/razzorstack
git submodule update --init docker/pawa
```

The parent `docker-compose.yml` includes this via:
```yaml
include:
  - path: pawa/docker-compose.pawa.yml
```

## Configuration

Add these to `docker/.env` (see `.env.example` for all options):
```bash
PAWA_BOT_TOKEN=your_discord_bot_token
PAWA_VERSION=2.17.0-be7c1c2b
```

## Image

`registry.gitlab.com/pawabot/pawa:2.17.0-be7c1c2b` — Kotlin/JVM, Java 25, distroless container.
