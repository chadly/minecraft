#!/bin/bash

# Set default docker-compose file name
compose_file="docker-compose.yml"

# If docker-compose-worlds.yml exists, update the file name
if [ -f "docker-compose-worlds.yml" ]; then
    compose_file="docker-compose-worlds.yml"
fi

# Use the determined compose file for the commands
docker-compose -f "$compose_file" down --remove-orphans
docker-compose -f "$compose_file" build --no-cache
