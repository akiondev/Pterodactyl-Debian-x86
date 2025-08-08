#!/bin/bash
set -e

# Always run from /home/container
cd /home/container

# Replace {{VAR}} with $VAR and echo what will run
MODIFIED_STARTUP=$(eval echo "$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')")
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Exec as PID 1 so signals are handled correctly
exec ${MODIFIED_STARTUP}
