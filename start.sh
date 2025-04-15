#!/bin/bash

base_port=19132
icon_url="https://placecats.com/150/150"
server_address="192.168.1.123"

# Delete the existing docker-compose-worlds.yml file if it exists
[ -f docker-compose-worlds.yml ] && rm docker-compose-worlds.yml

# Copy the existing docker-compose.yml to docker-compose-worlds.yml
cp docker-compose.yml docker-compose-worlds.yml

# Initialize servers.json
mkdir -p bedrockconnect
[ -f bedrockconnect/servers.json ] && rm bedrockconnect/servers.json
echo "[]" > bedrockconnect/servers.json

# Read each world from the JSON file
while read -r world; do
  id=$(echo $world | jq -r '.id')
  name=$(echo $world | jq -r '.name')
  gameMode=$(echo $world | jq -r '.gameMode')
  port=$((base_port + 1))
  base_port=$port

  # Append the service configuration to the docker-compose-worlds.yml file
  cat << EOF >> docker-compose-worlds.yml
  $id:
    container_name: minecraft_$id
    image: chadly/minecraft:latest
    build:
      context: ./minecraft
    depends_on:
      - bedrockconnect
    tty: true
    stdin_open: true
    restart: unless-stopped
    environment:
      GAMEMODE: $gameMode
      LEVEL_NAME: "$name"
    ports:
      - "$port:19132/udp"
    volumes:
      - "./minecraft/worlds/$id:/data:Z"

EOF

  # Update servers.json file with the new server entry
  jq --arg name "$name" \
     --arg iconUrl "$icon_url" \
     --arg address "$server_address" \
     --argjson port "$port" \
     '. += [{"name": $name, "iconUrl": $iconUrl, "address": $address, "port": $port}]' \
     bedrockconnect/servers.json > bedrockconnect/servers.tmp && mv bedrockconnect/servers.tmp bedrockconnect/servers.json
done < <(cat minecraft/worlds.json | jq -c '.[]')

docker-compose -f docker-compose-worlds.yml up
