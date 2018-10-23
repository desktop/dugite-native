# currently tagged on Docker Hub as shiftkey/dugite-native:arm64-jessie-git-with-curl
FROM multiarch/debian-debootstrap:arm64-jessie

RUN apt-get update
RUN apt-get install -y \
    build-essential \
    autoconf \
    libexpat-dev \
    curl \
    zlib1g-dev \
    libssl-dev \
    gettext

ENV CURL_INSTALL_DIR "/tmp/build/curl"
ENV CURL_VERSION "curl-7.61.1"

# extract curl to temp directory
RUN mkdir -p $CURL_INSTALL_DIR
WORKDIR /tmp
RUN curl -LO "https://curl.haxx.se/download/$CURL_VERSION.tar.gz"
RUN tar -xf "$CURL_VERSION.tar.gz"

# configure and install curl
WORKDIR $CURL_VERSION
RUN ./configure --prefix=$CURL_INSTALL_DIR
RUN make install

#cleanup
WORKDIR /tmp
RUN rm -rf "$CURL_VERSION.tar.gz"
RUN rm -rf "$CURL_VERSION"