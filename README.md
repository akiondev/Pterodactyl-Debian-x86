# Pterodactyl-Debian-x86

<div align="center">

[![Build status](https://img.shields.io/github/actions/workflow/status/akiondev/Pterodactyl-Debian-x86/publish.yml?branch=main)](https://github.com/akiondev/Pterodactyl-Debian-x86/actions/workflows/publish.yml)
[![License](https://img.shields.io/github/license/akiondev/Pterodactyl-Debian-x86)](https://github.com/akiondev/Pterodactyl-Debian-x86/blob/main/LICENSE)
[![GHCR](https://img.shields.io/badge/ghcr-available-brightgreen)](https://github.com/akiondev/Pterodactyl-Debian-x86/pkgs/container/pterodactyl-debian-x86)
![Last commit](https://img.shields.io/github/last-commit/akiondev/Pterodactyl-Debian-x86)
![Repo size](https://img.shields.io/github/repo-size/akiondev/Pterodactyl-Debian-x86)
![OS](https://img.shields.io/badge/os-Debian%20bookworm-lightgrey)
![Arch](https://img.shields.io/badge/arch-i386-blue)
[![Discord](https://img.shields.io/discord/1186346882805534742?label=discord)](https://discord.gg/v4umqdd7Aj)

</div>

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

## Example: Installing a game server using this image

Below is a minimal, generic example showing how to use this image with an Egg to download and run a 32‑bit dedicated server. Replace placeholders as needed.

### A) Add Egg variables (user-editable)
- `DOWNLOAD_URL` – direct link to your archive (zip/tar.gz)
- `ARCHIVE_NAME` – the filename inside the download to extract (optional; use if your URL is a zip that contains a tarball or folder)
- `EXTRA_ARGS` – extra startup flags for your server (optional)

**Validation examples:**
- `DOWNLOAD_URL`: `required|string`
- `ARCHIVE_NAME`: `nullable|string|max:128`
- `EXTRA_ARGS`: `nullable|string|max:1024`

### B) Installation script (Egg → Installation)
Use **Script Container** `i386/debian:bookworm-slim` and **Entrypoint** `bash`, then paste:

```bash
#!/bin/bash
set -euo pipefail

# Detect base path (Pterodactyl mounts the volume here)
if [ -d "/mnt/server" ]; then BASE="/mnt/server"; else BASE="/home/container"; fi
echo "BASE=$BASE"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends curl ca-certificates unzip tar file
rm -rf /var/lib/apt/lists/*

: "${DOWNLOAD_URL:?DOWNLOAD_URL is required}"
: "${ARCHIVE_NAME:=}"

DL_DIR="$BASE/.download"
mkdir -p "$DL_DIR"
ARCHIVE="$DL_DIR/pkg"

echo "Downloading: $DOWNLOAD_URL"
curl -fL --retry 5 --retry-delay 2 -o "$ARCHIVE" "$DOWNLOAD_URL"

# Try to detect type and extract accordingly
TYPE=$(file -b "$ARCHIVE")
echo "Detected type: $TYPE"

mkdir -p "$BASE/app"
if echo "$TYPE" | grep -qi "Zip archive"; then
  if [ -n "$ARCHIVE_NAME" ]; then
    echo "Extracting inner item: $ARCHIVE_NAME"
    unzip -p "$ARCHIVE" "$ARCHIVE_NAME" | tar -xz -C "$BASE/app" 2>/dev/null || unzip -q -o "$ARCHIVE" -d "$BASE/app"
  else
    unzip -q -o "$ARCHIVE" -d "$BASE/app"
  fi
elif echo "$TYPE" | grep -qi "gzip compressed"; then
  tar -xzf "$ARCHIVE" -C "$BASE/app"
elif echo "$TYPE" | grep -qi "tar archive"; then
  tar -xf "$ARCHIVE" -C "$BASE/app"
else
  echo "Unknown archive type; copying as-is"
  cp -v "$ARCHIVE" "$BASE/app/"
fi

# Normalize line endings and ensure executables
find "$BASE/app" -type f -name "*.sh" -print0 | xargs -0 -I{} sed -i 's/
$//' "{}" || true
find "$BASE/app" -type f -perm -u+x -print0 | xargs -0 -I{} echo "exec: {}" || true

# Write a minimal start.sh (edit the binary path + args to your server)
cat > "$BASE/start.sh" <<'SH'
#!/bin/sh
set -e
[ -d "/mnt/server" ] && BASE="/mnt/server" || BASE="/home/container"
cd "$BASE/app"

PORT="${SERVER_PORT:-27015}"          # or whatever your server uses
BIN="./your_binary"                   # change to your real binary path
ARGS="${EXTRA_ARGS:-}"                # from Egg variable

echo "Launching: $BIN $ARGS (port=${PORT})"
exec "$BIN" $ARGS
SH
chmod +x "$BASE/start.sh"

rm -rf "$DL_DIR"
echo "Install complete. Set Startup Command to: /home/container/start.sh"
```

### C) Startup command (Egg → Startup)
```
/home/container/start.sh
```

### D) Configure start.sh
Create your own start.sh tailored to the game/server you’re running. Set the working directory, binary path, ports, and flags required by that title. Make sure the file uses LF line endings and is executable (chmod +x /home/container/start.sh). Finally, set the Egg Startup Command to /home/container/start.sh.

That’s it — the entrypoint will run whatever `$STARTUP` is (your `start.sh`), and your installer controls what gets downloaded and how it is launched.

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
