#!/bin/bash

# Set default docker-compose file name
compose_file="docker-compose.yml"

# If docker-compose-worlds.yml exists, update the file name
if [ -f "docker-compose-worlds.yml" ]; then
    compose_file="docker-compose-worlds.yml"
fi

docker-compose -f "$compose_file" down --remove-orphans

docker pull itzg/minecraft-bedrock-server:latest
docker build -t chadly/minecraft:latest --no-cache .

docker-compose -f "$compose_file" build --no-cache
