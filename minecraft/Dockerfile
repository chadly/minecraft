FROM itzg/minecraft-server:stable as vanilla

ENV TYPE=PAPER \
    EULA=TRUE \
    DIFFICULTY=normal

RUN mkdir -p /plugins
RUN wget -O /plugins/geyser.jar https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot && \
    wget -O /plugins/floodgate.jar https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot

COPY plugins/*.jar /plugins/
