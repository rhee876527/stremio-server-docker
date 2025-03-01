# stremio-server-docker
Build stremio server on non-EOL bases.

This docker image drops all cruft from [official](https://github.com/Stremio/server-docker) docker image.

Official build uses node 14 base (built on Debian 10) both of which are EOL. It also has a weird hard requirement for jellyfin-ffmpeg version 4.4.1-4 which is terribly outdated.
