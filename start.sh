#!/bin/bash

base_port=19132
icon_url="https://micdoodle8.com/wp-content/uploads/2023/07/enderman-micdoodle8-1-1024x571.jpg"
server_address="qube.lan"

# Delete the existing docker-compose-worlds.yml file if it exists
[ -f docker-compose-worlds.yml ] && rm docker-compose-worlds.yml

# Copy the existing docker-compose.yml to docker-compose-worlds.yml
cp docker-compose.yml docker-compose-worlds.yml

# Initialize servers.json
echo "[]" > bedrockconnect/servers.json

# Initialize router mapping
router_mapping="|"

# Read each world from the JSON file
while read -r world; do
  id=$(echo $world | jq -r '.id')
  motd=$(echo $world | jq -r '.MOTD')

  # Calculate the port for the current service
  port=$((base_port + 1))
  base_port=$port

  # Append to router mapping
  router_mapping+="\n        $id.minecraft.lan=$id:25565"

  # Append the service configuration to the docker-compose-worlds.yml file
  cat << EOF >> docker-compose-worlds.yml
  $id:
    container_name: minecraft_$id
    build:
      context: ./minecraft
    depends_on:
      - bedrockconnect
      - router
    tty: true
    stdin_open: true
    restart: unless-stopped
    environment:
      MOTD: "$motd"
    ports:
      - "$port:19132/udp"
    volumes:
      - "./minecraft/worlds/$id:/data:Z"

EOF

  # Update servers.json file with the new server entry
  jq --arg name "$motd" \
     --arg iconUrl "$icon_url" \
     --arg address "$server_address" \
     --argjson port "$port" \
     '. += [{"name": $name, "iconUrl": $iconUrl, "address": $address, "port": $port}]' \
     bedrockconnect/servers.json > bedrockconnect/servers.tmp && mv bedrockconnect/servers.tmp bedrockconnect/servers.json
done < <(cat minecraft/worlds.json | jq -c '.[]')

# Replace ROUTER_MAPPING in docker-compose-worlds.yml with the actual router mapping
sed -i "s#__ROUTER_MAPPING__#$router_mapping#" docker-compose-worlds.yml

docker-compose -f docker-compose-worlds.yml up
