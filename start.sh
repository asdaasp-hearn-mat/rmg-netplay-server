#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_PATH="$SCRIPT_DIR/rmg-netplay-server"
PID_FILE="$SCRIPT_DIR/rmg-netplay-server.pid"
LOG_FILE="$SCRIPT_DIR/server.log"

SERVER_NAME="${SERVER_NAME:-Mario Party 2 Server}"
SERVER_MOTD="${SERVER_MOTD:-Welcome to the RMG Netplay Server!}"
MAX_GAMES="${MAX_GAMES:-10}"

# Build binary automatically if not present
if [ ! -x "$BINARY_PATH" ]; then
    echo "Binary not found at $BINARY_PATH. Running build.sh first..."
    "$SCRIPT_DIR/build.sh"
fi

# Refresh IP configuration
"$SCRIPT_DIR/update-ip.sh"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "Server is already running with PID $PID."
        exit 0
    else
        rm -f "$PID_FILE"
    fi
fi

# Launch native server in background detached from terminal
echo "Starting rmg-netplay-server..."
setsid "$BINARY_PATH" \
    --name "$SERVER_NAME" \
    --motd "$SERVER_MOTD" \
    --max-games "$MAX_GAMES" \
    > "$LOG_FILE" 2>&1 &

PID=$!
disown -h "$PID" 2>/dev/null || true
echo "$PID" > "$PID_FILE"

sleep 1
if kill -0 "$PID" 2>/dev/null; then
    echo "Server successfully started with PID $PID."
    echo "Live log output: tail -f $LOG_FILE"
else
    echo "Error: Server failed to start. Check $LOG_FILE for details."
    exit 1
fi
