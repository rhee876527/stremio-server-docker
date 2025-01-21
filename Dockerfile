# Base image
FROM node:20-alpine3.21 AS base

RUN apk update && apk upgrade

FROM base AS ffmpeg

# We build our own ffmpeg since 4.X is the only one supported
ENV BIN="/usr/bin"
RUN cd && \
  apk add --no-cache --virtual \ 
  .build-dependencies \ 
  gnutls \
  freetype-dev \
  gnutls-dev \
  lame-dev \
  libass-dev \
  libogg-dev \
  libtheora-dev \
  libvorbis-dev \ 
  libvpx-dev \
  libwebp-dev \ 
  libssh2 \
  opus-dev \
  rtmpdump-dev \
  x264-dev \
  x265-dev \
  yasm-dev \
  build-base \ 
  coreutils \ 
  gnutls \ 
  nasm \ 
  dav1d-dev \
  libbluray-dev \
  libdrm-dev \
  zimg-dev \
  aom-dev \
  xvidcore-dev \
  fdk-aac-dev \
  libva-dev \
  git \
  x264 && \
  DIR=$(mktemp -d) && \
  cd "${DIR}" && \
  git clone --depth 1 --branch v4.4.1-4 https://github.com/jellyfin/jellyfin-ffmpeg.git && \
  cd jellyfin-ffmpeg* && \
  PATH="$BIN:$PATH" && \
  ./configure --help && \
  ./configure --bindir="$BIN" --disable-debug \
  --prefix=/usr/lib/jellyfin-ffmpeg --extra-version=Jellyfin --disable-doc --disable-ffplay --disable-shared --disable-libxcb --disable-sdl2 --disable-xlib --enable-lto --enable-gpl --enable-version3 --enable-gmp --enable-gnutls --enable-libdrm --enable-libass --enable-libfreetype --enable-libfribidi --enable-libfontconfig --enable-libbluray --enable-libmp3lame --enable-libopus --enable-libtheora --enable-libvorbis --enable-libdav1d --enable-libwebp --enable-libvpx --enable-libx264 --enable-libx265  --enable-libzimg --enable-small --enable-nonfree --enable-libxvid --enable-libaom --enable-libfdk_aac --enable-vaapi --enable-hwaccel=h264_vaapi --toolchain=hardened && \
  make -j4 && \
  make install && \
  make distclean && \
  rm -rf "${DIR}"  && \
  apk del --purge .build-dependencies

# Main image
FROM base AS final

RUN apk add --no-cache curl jq
# Fetch the latest version tag from Docker Hub
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

# Copy ffmpeg
COPY --from=ffmpeg /usr/bin/ffmpeg /usr/bin/ffprobe /usr/bin/
COPY --from=ffmpeg /usr/lib/jellyfin-ffmpeg /usr/lib/

# Add libs
RUN apk add --no-cache libwebp libvorbis x265-libs x264-libs libass opus libgmpxx lame-libs gnutls libvpx libtheora libdrm libbluray zimg libdav1d aom-libs xvidcore fdk-aac libva

# Add arch specific libs
RUN if [ "$(uname -m)" = "x86_64" ]; then \
        apk add --no-cache intel-media-driver mesa-va-gallium; \
    fi

# Clear cache
RUN rm -rf /var/cache/apk/* && rm -rf /tmp/*

VOLUME ["/root/.stremio-server"]

# Expose default ports
EXPOSE 11470 12470

# Start stremio server
ENTRYPOINT [ "node", "server.js" ]
