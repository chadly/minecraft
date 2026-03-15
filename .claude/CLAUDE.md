# CLAUDE.md

## Project Overview

Docker-based Minecraft Bedrock Edition multi-world server system. Each world runs in its own container using `itzg/minecraft-bedrock-server`. A BedrockConnect proxy (port 19132) allows console players (Xbox, Switch, PS4/PS5) to connect via DNS hijacking of featured server addresses.

## Commands

- **Start all servers:** `./start.sh` — reads `worlds.json`, generates `docker-compose-worlds.yml` and `bedrockconnect/servers.json`, then runs `docker-compose up`
- **Rebuild images:** `./rebuild.sh` — pulls latest base image, rebuilds `chadly/minecraft:latest`, rebuilds compose services

## Architecture

`worlds.json` is the source of truth for world configuration. Each entry has `id`, `name`, `gameMode`, `allowCheats`, `levelType`, and optional `seed`.

`start.sh` generates two files at runtime (both git-ignored):

- `docker-compose-worlds.yml` — merges `docker-compose.yml` (BedrockConnect) with a service per world, ports incrementing from 19133
- `bedrockconnect/servers.json` — server list served by BedrockConnect proxy

World data lives in `worlds/<id>/` (git-ignored). The Dockerfile extends `itzg/minecraft-bedrock-server` with defaults (EULA, timezone, server name, LAN visibility).

Key hardcoded values in `start.sh`: server address (`192.168.1.123`), OPS Xbox Live IDs, VIEW_DISTANCE (6), MAX_THREADS (16).
