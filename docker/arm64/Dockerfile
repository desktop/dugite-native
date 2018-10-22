# currently tagged on Docker Hub as shiftkey/dugite-native:arm64-jessie-git
FROM multiarch/debian-debootstrap:arm64-jessie

RUN apt-get update
RUN apt-get install -y \
    build-essential \
    autoconf \
    libexpat-dev \
    curl \
    libcurl4-openssl-dev \
    zlib1g-dev \
    libssl-dev \
