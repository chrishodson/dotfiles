#!/bin/bash
docker pull plexinc/pms-docker && \
docker ps | grep -q plex && \
  docker stop plex  || (echo "failed to stop"; exit 1)
docker rm plex || echo "No plex container present"
docker run -d                        \
--name plex                          \
--network=host                       \
--restart=unless-stopped             \
-e TZ=America/New_York               \
-v /plex/database:/config            \
-v /plex/transcode/temp:/transcode   \
-v /plex/media:/data                 \
plexinc/pms-docker
