#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/rmg-netplay-server.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "Stopping rmg-netplay-server (PID $PID)..."
        kill "$PID"
        for i in {1..10}; do
            if ! kill -0 "$PID" 2>/dev/null; then
                break
            fi
            sleep 0.5
        done
        if kill -0 "$PID" 2>/dev/null; then
            kill -9 "$PID"
        fi
        echo "Server stopped."
    else
        echo "Process $PID is not running."
    fi
    rm -f "$PID_FILE"
else
    pkill -f "$SCRIPT_DIR/rmg-netplay-server" 2>/dev/null && echo "rmg-netplay-server process terminated." || echo "No running server process found."
fi
