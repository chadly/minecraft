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

## Base Image Reference (`itzg/minecraft-bedrock-server`)

The Bedrock server binary is **not bundled** in the image — it downloads/upgrades from Mojang on every container startup. With `VERSION` defaulting to `LATEST`, restarting a container auto-upgrades.

### Environment Variables

The `itzg/minecraft-bedrock-server` image maps environment variables to `server.properties` keys via UPPER_SNAKE_CASE. It also provides container-level variables that control image behavior. Sources: [itzg README](https://github.com/itzg/docker-minecraft-bedrock-server), [Bedrock server.properties](https://minecraft.wiki/w/Server.properties#Bedrock_Edition_2).

#### Container-Level Variables (itzg image only, not in server.properties)

| Variable | Default | Description |
|---|---|---|
| `EULA` | _(none)_ | **Must be `TRUE`** to accept the Minecraft EULA. **Set in Dockerfile.** |
| `VERSION` | `LATEST` | Server version. `LATEST` auto-upgrades on restart. Also: `PREVIEW`, `EXISTING` (use existing binary in `/data`), or a specific version string. |
| `TZ` | _(none)_ | Container timezone. **Set to `America/Chicago` in Dockerfile.** |
| `UID` / `GID` | _(from `/data` owner)_ | User/group ID for the bedrock server process. |
| `PACKAGE_BACKUP_KEEP` | `2` | Number of server package backups to retain. |
| `ENABLE_SSH` | `false` | Enable remote console via SSH on port 2222. |
| `DOWNLOAD_PROGRESS` | `false` | Show progress bar during server download. |
| `DIRECT_DOWNLOAD_URL` | _(none)_ | Override auto-lookup with a direct URL to the `bedrock-server-VERSION.zip`. Useful for CI/CD or when auto-lookup breaks. |
| `MC_PACK` | _(none)_ | Path inside container to a `.mcpack`, `.mcworld`, `.mcaddon`, `.mctemplate`, or zip. Unpacked at startup: `behavior_packs/` and `resource_packs/` go to server pack dirs; world content (`level.dat`) goes to `worlds/{LEVEL_NAME}`. |
| `FORCE_WORLD_COPY` | `false` | When `MC_PACK` contains a world, remove and replace existing `worlds/{LEVEL_NAME}` on every startup. |
| `FORCE_PACK_COPY` | `false` | When `MC_PACK` contains packs, remove and replace existing pack folders on every startup. |
| `OPS` | _(none)_ | Comma or newline-separated list of XUIDs (16+ digit numbers) or Xbox gamertags. Gamertags are resolved to XUIDs at startup via MCProfile API. **Hardcoded in `start.sh`.** |
| `MEMBERS` | _(none)_ | Same format as `OPS`. Defines member-level players. |
| `VISITORS` | _(none)_ | Same format as `OPS`. Defines visitor-level players. |
| `ALLOW_LIST_USERS` | _(none)_ | Comma or newline-separated `gamertag:XUID` pairs for the allowlist. |

#### Server Properties — World & Player Settings

| Variable | Values | Default | Description |
|---|---|---|---|
| `SERVER_NAME` | Any string (no `:`) | `Dedicated Server` | Server name shown in LAN games list and pause menu. **Set to `Qube` in Dockerfile.** |
| `GAMEMODE` | `survival`, `creative`, `adventure` | `survival` | Game mode for new players joining. Does not change existing players' mode unless `FORCE_GAMEMODE` is true. **Set per-world from `worlds.json`.** |
| `FORCE_GAMEMODE` | `true`, `false` | `false` | When true, forces all players to the server's gamemode on join. Required when changing gamemode after world creation. **Set to `true` in `start.sh`.** |
| `DIFFICULTY` | `peaceful`, `easy`, `normal`, `hard` | `easy` | World difficulty. Affects mob damage, hunger, poison. |
| `ALLOW_CHEATS` | `true`, `false` | `false` | Enables commands and cheats for players. **Set per-world from `worlds.json`.** |
| `LEVEL_NAME` | Any string (no illegal filename chars) | `Bedrock level` | World name and folder name under `/worlds`. **Set per-world from `worlds.json`.** |
| `LEVEL_SEED` | Any string | _(random)_ | World generation seed. Only applies at world creation; stored in level files after that. **Set per-world from `worlds.json` if provided.** |
| `LEVEL_TYPE` | `default`, `flat` | _(default)_ | World generation preset. `flat` creates a superflat world. **Set per-world from `worlds.json`.** |
| `MAX_PLAYERS` | Positive integer | `10` | Max simultaneous players. Higher values have performance impact. |
| `ONLINE_MODE` | `true`, `false` | `true` | Require Xbox Live authentication. Remote (non-LAN) clients always require auth regardless. |
| `DEFAULT_PLAYER_PERMISSION_LEVEL` | `visitor`, `member`, `operator` | `member` | Permission level for first-time players. |
| `PLAYER_IDLE_TIMEOUT` | Integer (minutes) | `30` | Kick idle players after this many minutes. `0` = never kick. |
| `TEXTUREPACK_REQUIRED` | `true`, `false` | `false` | Force clients to download resource packs. |
| `ALLOW_LIST` | `true`, `false` | `false` | Require players to be in `allowlist.json`. |
| `WHITE_LIST` | `true`, `false` | `false` | Alias for `ALLOW_LIST`. |
| `OP_PERMISSION_LEVEL` | Integer (0–4) | `4` | Default permission level for operators. |
| `MSA_GAMERTAGS_ONLY` | `true`, `false` | _(unset)_ | Require MSA-authenticated gamertags. |

#### Server Properties — Network & Ports

| Variable | Values | Default | Description |
|---|---|---|---|
| `SERVER_PORT` | 1–65535 | `19132` | IPv4 UDP port the server listens on. |
| `SERVER_PORT_V6` | 1–65535 | `19133` | IPv6 UDP port the server listens on. |
| `ENABLE_LAN_VISIBILITY` | `true`, `false` | `true` | Respond to LAN discovery. Causes server to also bind default ports (19132/19133) even with custom `SERVER_PORT`. **Set to `true` in Dockerfile.** |
| `COMPRESSION_THRESHOLD` | 1–65535 | `1` | Minimum raw network payload size (bytes) before compression is applied. |
| `COMPRESSION_ALGORITHM` | `zlib`, `snappy` | `zlib` | Network compression algorithm. |

#### Server Properties — Performance & Simulation

| Variable | Values | Default | Description |
|---|---|---|---|
| `VIEW_DISTANCE` | Integer >= 5 | `32` | Max view distance in chunks. Higher values = more performance impact. **Set to `6` in `start.sh`.** |
| `TICK_DISTANCE` | 4–12 | `4` | Radius in chunks around each player that gets ticked (entities updated, redstone runs, etc.). Higher = more CPU. |
| `MAX_THREADS` | Any integer | `8` | Max threads for the server. `0` = use all available. **Set to `16` in `start.sh`.** |
| `CLIENT_SIDE_CHUNK_GENERATION_ENABLED` | `true`, `false` | `true` | Let clients generate visual chunks beyond tick distance. Reduces server load. |
| `SERVER_BUILD_RADIUS_RATIO` | `Disabled` or 0.0–1.0 | `Disabled` | How much of the player's view the server generates vs. the client. Only works when client-side chunk gen is enabled. `Disabled` = server decides dynamically. |

#### Server Properties — Anti-Cheat & Movement Authority

| Variable | Values | Default | Description |
|---|---|---|---|
| `SERVER_AUTHORITATIVE_MOVEMENT` | `client-auth`, `server-auth`, `server-auth-with-rewind` | `server-auth` | Movement validation mode. `server-auth` replays client input server-side and sends corrections. `server-auth-with-rewind` adds client-side time rewinding for smoother corrections. |
| `PLAYER_POSITION_ACCEPTANCE_THRESHOLD` | Positive number | `0.5` | Tolerance for client/server position discrepancy before correction. Values >1.0 increase cheating risk. |
| `PLAYER_MOVEMENT_ACTION_DIRECTION_THRESHOLD` | 0–1 | `0.85` | How closely attack direction must match look direction. `1` = exact match, `0` = up to 90° difference. |
| `CORRECT_PLAYER_MOVEMENT` | `true`, `false` | _(unset)_ | Whether server corrects client position during server-auth mode. |
| `SERVER_AUTHORITATIVE_BLOCK_BREAKING` | `true`, `false` | _(unset)_ | Server validates block breaking actions. |
| `SERVER_AUTHORITATIVE_BLOCK_BREAKING_PICK_RANGE_SCALAR` | `true`, `false` | `false` | Server computes block mining in sync with client to verify break range. |
| `PLAYER_MOVEMENT_SCORE_THRESHOLD` | Integer | _(unset)_ | Score threshold for flagging player movement as suspicious. |
| `PLAYER_MOVEMENT_DISTANCE_THRESHOLD` | Number | _(unset)_ | Distance threshold for movement violation detection. |
| `PLAYER_MOVEMENT_DURATION_THRESHOLD_IN_MS` | Integer (ms) | _(unset)_ | Duration threshold for movement violation detection. |

#### Server Properties — Chat & Interaction

| Variable | Values | Default | Description |
|---|---|---|---|
| `CHAT_RESTRICTION` | `None`, `Dropped`, `Disabled` | `None` | `None` = normal chat. `Dropped` = messages silently dropped, players notified. `Disabled` = chat UI hidden for non-operators. |
| `DISABLE_PLAYER_INTERACTION` | `true`, `false` | `false` | Tells clients to ignore other players when interacting with the world. Not server-authoritative. |
| `DISABLE_CUSTOM_SKINS` | `true`, `false` | `false` | Block custom skins made outside Character Creator / Marketplace packs. |
| `DISABLE_PERSONA` | `true`, `false` | `false` | Internal use only. |
| `BLOCK_NETWORK_IDS_ARE_HASHES` | `true`, `false` | `true` | Use stable hashed block network IDs instead of sequential ones. |

#### Server Properties — Content Logging

| Variable | Values | Default | Description |
|---|---|---|---|
| `CONTENT_LOG_FILE_ENABLED` | `true`, `false` | `false` | Log content errors to a file. |
| `CONTENT_LOG_LEVEL` | `verbose`, `info`, `warning`, `error` | _(unset)_ | Content log verbosity level. |
| `CONTENT_LOG_CONSOLE_OUTPUT_ENABLED` | `true`, `false` | _(unset)_ | Also output content log to console. |
| `ITEM_TRANSACTION_LOGGING_ENABLED` | `true`, `false` | _(unset)_ | Log item transactions. |
| `EMIT_SERVER_TELEMETRY` | `true`, `false` | `false` | Send server telemetry data to Mojang. |

#### Server Properties — Script Debugging

| Variable | Values | Default | Description |
|---|---|---|---|
| `ALLOW_OUTBOUND_SCRIPT_DEBUGGING` | `true`, `false` | `false` | Allow script debugger 'connect' commands. |
| `ALLOW_INBOUND_SCRIPT_DEBUGGING` | `true`, `false` | `false` | Allow script debugger 'listen' commands. |
| `SCRIPT_DEBUGGER_AUTO_ATTACH` | `disabled`, `connect`, `listen` | `disabled` | Auto-attach debugger at level load. |
| `SCRIPT_DEBUGGER_AUTO_ATTACH_CONNECT_ADDRESS` | `host:port` | `localhost:19144` | Address for `connect` auto-attach mode. |
| `FORCE_INBOUND_DEBUG_PORT` | 1–65535 | `19144` | Lock the inbound debugger listen port. |

#### Server Properties — Script Watchdog

| Variable | Values | Default | Description |
|---|---|---|---|
| `SCRIPT_WATCHDOG_ENABLE` | `true`, `false` | `true` | Enable the script watchdog. |
| `SCRIPT_WATCHDOG_ENABLE_EXCEPTION_HANDLING` | `true`, `false` | `true` | Enable watchdog exception handling via `events.beforeWatchdogTerminate`. |
| `SCRIPT_WATCHDOG_ENABLE_SHUTDOWN` | `true`, `false` | `true` | Shut down server on unhandled watchdog exception. |
| `SCRIPT_WATCHDOG_HANG_EXCEPTION` | `true`, `false` | `true` | Throw critical exception on hang, interrupting script execution. |
| `SCRIPT_WATCHDOG_HANG_THRESHOLD` | 3000–20000 (ms) | `10000` | Single tick hang threshold before watchdog acts. |
| `SCRIPT_WATCHDOG_SPIKE_THRESHOLD` | 50–500 (ms) | `100` | Single tick spike warning threshold. |
| `SCRIPT_WATCHDOG_SLOW_THRESHOLD` | 5–50 (ms) | `10` | Slow script warning threshold over multiple ticks. |
| `SCRIPT_WATCHDOG_MEMORY_WARNING` | 0–2000 (MB) | `100` | Log warning when combined script memory exceeds this. `0` = disabled. |
| `SCRIPT_WATCHDOG_MEMORY_LIMIT` | 0–2000 (MB) | `250` | Save and shut down when combined script memory exceeds this. `0` = disabled. |
