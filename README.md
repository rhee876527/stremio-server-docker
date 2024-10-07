# stremio-server-docker
Build stremio server on non-EOL bases.

This docker build retires the node 14 base (based on Debian 10) used by the official stremio docker image both of which are EOL. 

It makes use of Node 20 with alpine 3.20.

Note: The docker server doesn't support transcoding.

This is made possible thanks to the ffmpeg build work done by this project https://github.com/tsaridas/stremio-docker
