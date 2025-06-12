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
  allowCheats=$(echo $world | jq -r '.allowCheats')
  levelType=$(echo $world | jq -r '.levelType')
  
  # Extract the seed value if it exists, otherwise it will be null/empty
  seed=$(echo $world | jq -r '.seed // empty')
  
  port=$((base_port + 1))
  base_port=$port

  # Create environment variables block
  env_block="GAMEMODE: $gameMode
      LEVEL_NAME: \"$name\"
      FORCE_GAMEMODE: true
      OPS: \"2533274939375765,2535430013589908\"
      ALLOW_CHEATS: $([ "$allowCheats" = true ] && echo "true" || echo "false")
      LEVEL_TYPE: $levelType"
  
  # Add seed to environment block if provided
  if [ -n "$seed" ]; then
    env_block="$env_block
      LEVEL_SEED: \"$seed\""
  fi

  # Append the service configuration to the docker-compose-worlds.yml file
  cat << EOF >> docker-compose-worlds.yml
  $id:
    container_name: minecraft_$id
    image: chadly/minecraft:latest
    build:
      context: .
    depends_on:
      - bedrockconnect
    tty: true
    stdin_open: true
    restart: unless-stopped
    environment:
      $env_block
    ports:
      - "$port:19132/udp"
    volumes:
      - "./worlds/$id:/data:Z"

EOF
  jq --arg name "$name" \
     --arg iconUrl "$icon_url" \
     --arg address "$server_address" \
     --argjson port "$port" \
     '. += [{"name": $name, "iconUrl": $iconUrl, "address": $address, "port": $port}]' \
     bedrockconnect/servers.json > bedrockconnect/servers.tmp && mv bedrockconnect/servers.tmp bedrockconnect/servers.json
done < <(cat worlds.json | jq -c '.[]')

docker-compose -f docker-compose-worlds.yml up
