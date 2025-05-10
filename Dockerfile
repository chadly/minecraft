FROM itzg/minecraft-bedrock-server:latest

ENV EULA=true \
    TZ="America/Chicago" \
    SERVER_NAME="Qube" \
    ENABLE_LAN_VISIBILITY=true
