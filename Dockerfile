# Stage 1: Build
FROM ubuntu:22.04 AS build

# Install required dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    libpqxx-dev \
    pkg-config \
    gdb

# Set working directory
WORKDIR /usr/src/app

# Copy source code
COPY . .

# Create build directory
RUN mkdir -p build
WORKDIR /usr/src/app/build

# Run CMake and compile
RUN cmake .. && make

# Debugging: Ensure the binary exists
RUN ls -lh /usr/src/app/build/MMOLoginServer




# Stage 2: Runtime (smaller final image)
FROM ubuntu:22.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libpqxx-dev \
    libpq5 \
    libtsan0 \
    libstdc++6

# Set working directory
WORKDIR /usr/src/app

# Copy only the compiled executable from the build stage
COPY --from=build /usr/src/app/build/MMOLoginServer /usr/src/app/MMOLoginServer

#Copy config file
COPY --from=build /usr/src/app/config.json /usr/src/app/config.json

# Ensure the binary is executable
RUN chmod +x /usr/src/app/MMOLoginServer

# Expose the application port
EXPOSE 27014

# Run the application
CMD ["/usr/src/app/MMOLoginServer"]
