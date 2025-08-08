# syntax=docker/dockerfile:1.6
FROM i386/debian:bookworm-slim

# Install minimal runtime deps (incl. sed) in a single layer
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      bash ca-certificates curl unzip file tzdata tar openssl sed \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy entrypoint and normalize line endings as root, then make it executable
COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

# Create the required Pterodactyl user and home, and set ownership
RUN useradd -m -d /home/container -s /bin/bash container \
 && chown container:container /entrypoint.sh

# Pterodactyl requirements
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

# Evaluate $STARTUP and run it
CMD ["/bin/bash", "/entrypoint.sh"]
