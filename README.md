# stremio-server-docker
Build stremio server on non-EOL bases.

This docker build retires the node 14 base (based on Debian 10) used by the official stremio docker image both of which are EOL. It makes use of Node 18 with alpine 3.18.

Side note: Node 20 with Alpine 3.20 base will also build but ffprobe doesn't work. Not a big deal unless you need transcoding for client.

This is made possible thanks to the ffmpeg build work done by this project https://github.com/tsaridas/stremio-docker
