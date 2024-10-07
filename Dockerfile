# Base image
FROM node:20-alpine3.20 AS base

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

RUN apk add --no-cache curl
# Get the latest Stremio server version. The version from server-url.txt can be behind. As of Oct 6, 24 it was showing version v4.20.8 while v4.20.9 was available.
RUN set -eux; \
    # Get the current version from server-url.txt
    CURRENT_VERSION=$(curl -s https://raw.githubusercontent.com/Stremio/stremio-shell/master/server-url.txt | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+'); \
    echo "Current version: ${CURRENT_VERSION}"; \
    # Increment the version
    NEXT_VERSION=$(echo "${CURRENT_VERSION}" | awk -F. -v OFS=. '{$NF++; print}'); \
    echo "Next version: ${NEXT_VERSION}"; \
    # Check if the next version URL is available
    if curl --output /dev/null --silent --fail "https://dl.strem.io/server/${NEXT_VERSION}/desktop/server.js"; then \
        echo "Using next version: ${NEXT_VERSION}"; \
        VERSION=${NEXT_VERSION}; \
    else \
        echo "Next version not available. Using current version: ${CURRENT_VERSION}"; \
        VERSION=${CURRENT_VERSION}; \
    fi; \
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
#disable casting for server
ENV CASTING_DISABLED=1

# Copy ffmpeg
COPY --from=ffmpeg /usr/bin/ffmpeg /usr/bin/ffprobe /usr/bin/
COPY --from=ffmpeg /usr/lib/jellyfin-ffmpeg /usr/lib/

# Add libs
RUN apk add --no-cache libwebp libvorbis x265-libs x264-libs libass opus libgmpxx lame-libs gnutls libvpx libtheora libdrm libbluray zimg libdav1d aom-libs xvidcore fdk-aac libva

# Add arch specific libs
RUN if [ "$(uname -m)" = "x86_64" ]; then \
        apk add --no-cache intel-media-driver; \
    fi

# Clear cache
RUN rm -rf /var/cache/apk/* && rm -rf /tmp/*

VOLUME ["/root/.stremio-server"]

# Expose default ports
EXPOSE 11470 12470

# Start stremio server
ENTRYPOINT [ "node", "server.js" ]
