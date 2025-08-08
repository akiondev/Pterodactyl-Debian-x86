# Pterodactyl-Debian-x86

A minimal **Debian i386 (32-bit)** runtime image tailored for **Pterodactyl** game servers.

This image follows Pterodactyl’s container requirements:

- User `container` with home at `/home/container`
- `WORKDIR /home/container`
- An entrypoint that evaluates and executes the Panel’s `$STARTUP` command
- Small, dependency-light base (Debian bookworm-slim)

> Useful for running legacy 32-bit dedicated servers on Pterodactyl.

---

## Image

Published to GitHub Container Registry (GHCR):

```
ghcr.io/akiondev/pterodactyl-debian-x86:bookworm
ghcr.io/akiondev/pterodactyl-debian-x86:latest
```

### What’s inside

- Base: `i386/debian:bookworm-slim`
- Runtime deps: `bash`, `curl`, `ca-certificates`, `unzip`, `file`, `tzdata`, `tar`, `openssl`, `sed`
- User: `container` (home: `/home/container`)
- Entrypoint: [`entrypoint.sh`](./entrypoint.sh)  
  - Expands Pterodactyl-style `{{VAR}}` placeholders using environment variables
  - Echoes the final command
  - `exec`s the resulting command as PID 1 (proper signal handling)

---

## Quick test (Docker, outside Pterodactyl)

```bash
docker run --rm ghcr.io/akiondev/pterodactyl-debian-x86:bookworm   -e STARTUP='echo hello-from-startup'
# Expected:
# :/home/container$ echo hello-from-startup
# hello-from-startup
```

---

## Using it with Pterodactyl

### 1) Add the image to your Egg

**Admin → Nests → Eggs → (your egg) → Docker Images**  
Add:
```
ghcr.io/akiondev/pterodactyl-debian-x86:bookworm
```

### 2) Startup command

Set **Egg → Startup Command** to whatever you want the container to run as `$STARTUP`.  
Typical patterns:

- Run your bootstrap script:
  ```
  /home/container/start.sh
  ```

- Or run your server process directly, for example:
  ```
  ./your_binary +set some_var {{SOME_ENV}} +exec server.cfg
  ```

> The entrypoint expands `{{SOME_ENV}}` and other variables that you define in the Egg.

### 3) Installation script (optional)

If you use an installer to download/unpack files, set **Script Container** to a Debian i386 image so `apt-get` works:

- **Copy Script From:** *(None)*
- **Script Container:** `i386/debian:bookworm-slim`
- **Script Entrypoint Command:** `bash`

Then place your installer shell script in the Egg, e.g. to download assets and create `/home/container/start.sh`.

### 4) Reinstall

After changing the image or Egg config, go to **Server → Settings → Reinstall** so Wings pulls the new image and applies settings.

---

## GitHub Actions (CI)

This repo includes a workflow at `.github/workflows/publish.yml` that builds and pushes the image to GHCR on pushes to `main` and tags matching `v*`.

Tags produced by default:
- `ghcr.io/akiondev/pterodactyl-debian-x86:bookworm`
- `ghcr.io/akiondev/pterodactyl-debian-x86:latest`

> If you need to force a fresh build, bump a tag or add `no-cache: true` to the build step temporarily.

---

## Troubleshooting

### I see `$'\r': command not found` or `set: invalid option`
This usually indicates **CRLF line endings** in a shell script.  
This image normalizes `entrypoint.sh` during build, but your **runtime scripts** (e.g., `/home/container/start.sh`) must be LF as well.

Fix in the container:
```bash
sed -i 's/\r$//' /home/container/start.sh
chmod +x /home/container/start.sh
```

Also consider a `.gitattributes` in your game/installer repo:
```
* text=auto eol=lf
*.sh text eol=lf
```

### Server doesn’t auto-start after Install
Pterodactyl runs install in a separate container and leaves the server **stopped**.  
Click **Start**, create a one-shot **Schedule → Power Action: Start**, or call the **API** (`power: start`) after install if you want auto-boot.

### Missing 32-bit libs
If your server binary complains about missing shared libraries, add the required Debian packages to your **runtime image** or ship them with your server. Common ones for older 32-bit binaries:
- `libstdc++6`, `zlib1g`
  
(You can extend the Dockerfile as needed.)

---

## Development

### Build locally
```bash
DOCKER_BUILDKIT=1 docker build --no-cache -t ghcr.io/akiondev/pterodactyl-debian-x86:bookworm .
docker push ghcr.io/akiondev/pterodactyl-debian-x86:bookworm
```

### Entry point overview
```bash
#!/bin/bash
set -e
cd /home/container
MODIFIED_STARTUP=$(eval echo "$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')")
echo ":/home/container$ ${MODIFIED_STARTUP}"
exec ${MODIFIED_STARTUP}
```

---

## Notes

- This repository aims to provide a clean 32-bit Debian runtime specifically for Pterodactyl.  
- Keep installation logic (downloading, unpacking, etc.) in the **install script container**, and keep the runtime image small.
