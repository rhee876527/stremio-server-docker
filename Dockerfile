# Start from alpine base 
FROM alpine:3.21

# Install dependencies
RUN apk add --no-cache jellyfin-ffmpeg nodejs curl jq

# Fetch server.js version from latest tagged version on Docker Hub
RUN VERSION=$(curl -s "https://registry.hub.docker.com/v2/repositories/stremio/server/tags/" | jq -r '.results[].name' | grep -v 'latest' | sort -V | tail -n 1); \
    echo "Using version: ${VERSION}"; \
    # Download the selected server.js file
    curl -fLO "https://dl.strem.io/server/${VERSION}/desktop/server.js"

# Copy server.js 
COPY . .

# Custom ENV options
ENV FFMPEG_BIN=
ENV FFPROBE_BIN=
ENV NODE_ENV=production
ENV APP_PATH=
ENV NO_CORS=
ENV CASTING_DISABLED=

# Cache folder
VOLUME ["/root/.stremio-server"]

# Expose default ports
EXPOSE 11470 12470

# Start stremio server
ENTRYPOINT [ "node", "server.js" ]
