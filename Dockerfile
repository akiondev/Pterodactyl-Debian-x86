# syntax=docker/dockerfile:1.6
FROM i386/debian:bookworm-slim

# Install minimal runtime deps in a single RUN layer (Debian equivalent of "no-cache").
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      bash ca-certificates curl unzip file tzdata tar openssl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 # Create the required Pterodactyl user and home
 && useradd -m -d /home/container -s /bin/bash container

# Pterodactyl requirements
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

# Entrypoint that evaluates and runs $STARTUP
COPY --chown=container:container entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
