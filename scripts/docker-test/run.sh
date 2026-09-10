#!/usr/bin/env bash
# Builds the sandbox image and runs `./setup bootstrap` inside a fresh
# container, detached, logging to logs/wisp-install.log on the host so it
# can be tailed live. Usage: sudo bash scripts/docker-test/run.sh
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SELF_DIR/../.." && pwd)"
LOG_DIR="$SELF_DIR/logs"
IMAGE="wisp-shell-sandbox"
CONTAINER="wisp-sandbox-$(date +%s)"

mkdir -p "$LOG_DIR"
chmod 777 "$LOG_DIR"
: > "$LOG_DIR/wisp-install.log"
chmod 666 "$LOG_DIR/wisp-install.log"

echo "Building image..."
docker build -t "$IMAGE" -f "$SELF_DIR/Dockerfile" "$REPO_ROOT"

echo "Starting container: $CONTAINER"
docker run -d --name "$CONTAINER" \
    -v "$REPO_ROOT":/home/tester/wisp-shell:ro \
    -v "$LOG_DIR":/home/tester/logs \
    "$IMAGE" \
    bash -lc 'cd /home/tester/wisp-shell && bash setup bootstrap > /home/tester/logs/wisp-install.log 2>&1; echo "EXIT_CODE=$?" >> /home/tester/logs/wisp-install.log'

echo "$CONTAINER" > "$LOG_DIR/last-container"
echo "Container: $CONTAINER"
echo "Log:       $LOG_DIR/wisp-install.log"
echo "Watch:     tail -f $LOG_DIR/wisp-install.log"
echo "Wait:      docker wait $CONTAINER"
