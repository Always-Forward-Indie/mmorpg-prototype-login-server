# Production build — no hot-reload, optimised binary
FROM ubuntu:22.04

ARG BUILD_TYPE=Release

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    make \
    libpqxx-dev \
    libspdlog-dev \
    libssl-dev \
    pkg-config \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY CMakeLists.txt ./
COPY src ./src
COPY include ./include
COPY config.json ./config.json

RUN mkdir -p build

WORKDIR /usr/src/app/build

RUN cmake -DCMAKE_BUILD_TYPE=${BUILD_TYPE} .. && make -j$(nproc)

RUN ls -lh /usr/src/app/build/MMOLoginServer || (echo "ERROR: Binary not built!" && exit 1)

RUN strip /usr/src/app/build/MMOLoginServer || true
RUN chmod +x /usr/src/app/build/MMOLoginServer

WORKDIR /usr/src/app

EXPOSE 27014

CMD ["/usr/src/app/build/MMOLoginServer"]
