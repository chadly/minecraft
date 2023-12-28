# Minecraft Servers

```
docker compose up
```

## DNS

Add DNS entries to point to your host server (for Bedrock Connect):

| Hostname |
| -------- |
| geo.hivebedrock.network |
| hivebedrock.network |
| play.inpvp.net |
| mco.lbsg.net |
| play.galaxite.net |

Then add DNS entries for each map in `minecraft_router`:

| Hostname |
| -------- |
| vanilla.minecraft.lan |
| disneyland.minecraft.lan |

These entries should correspond with the entries in [`servers.json`](bedrockconnect/servers.json) and the `router` config in [`docker-compose.yml`](docker-compose.yml).
