#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_PATH="$SCRIPT_DIR/rmg-netplay-server"
IMAGE_NAME="rmg-netplay-server:latest"

build_with_go() {
    echo "Building rmg-netplay-server natively with Go..."
    (cd "$SCRIPT_DIR" && CGO_ENABLED=0 go build -a -o "$BINARY_PATH" .)
    chmod +x "$BINARY_PATH"
    echo "Build complete: $BINARY_PATH"
}

build_with_container() {
    local engine="$1"
    echo "Building rmg-netplay-server using $engine (via Containerfile)..."
    "$engine" build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Containerfile" "$SCRIPT_DIR"

    local temp_container="rmg-extract-$$"
    "$engine" create --name "$temp_container" "$IMAGE_NAME" >/dev/null
    "$engine" cp "$temp_container:/rmg-netplay-server" "$BINARY_PATH"
    "$engine" rm "$temp_container" >/dev/null
    chmod +x "$BINARY_PATH"
    echo "Build complete (extracted static binary): $BINARY_PATH"
}

if [[ "${1:-}" == "--container" ]]; then
    if command -v podman >/dev/null 2>&1; then
        build_with_container podman
    elif command -v docker >/dev/null 2>&1; then
        build_with_container docker
    else
        echo "Error: Neither podman nor docker found in PATH."
        exit 1
    fi
elif command -v go >/dev/null 2>&1; then
    build_with_go
elif command -v podman >/dev/null 2>&1; then
    build_with_container podman
elif command -v docker >/dev/null 2>&1; then
    build_with_container docker
else
    echo "Error: Could not find 'go', 'podman', or 'docker' to compile rmg-netplay-server."
    echo "Please install Go (https://go.dev/) or Podman/Docker and try again."
    exit 1
fi
