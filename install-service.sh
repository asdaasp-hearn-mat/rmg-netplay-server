#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_PATH="$SCRIPT_DIR/rmg-netplay-server"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
SERVICE_NAME="rmg-netplay-server.service"

if [ ! -x "$BINARY_PATH" ]; then
    echo "Binary not found at $BINARY_PATH. Building first..."
    "$SCRIPT_DIR/build.sh"
fi

mkdir -p "$TARGET_DIR"

cat <<EOF > "$TARGET_DIR/$SERVICE_NAME"
[Unit]
Description=Rosalie's Mupen GUI Netplay Server
After=network.target

[Service]
Type=simple
WorkingDirectory=$SCRIPT_DIR
ExecStartPre=$SCRIPT_DIR/update-ip.sh
ExecStart=$BINARY_PATH --name "Mario Party 2 Server" --motd "Welcome to the RMG Netplay Server!" --max-games 10
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
echo "Systemd user service installed to: $TARGET_DIR/$SERVICE_NAME"
echo ""
echo "Commands to manage the service:"
echo "  systemctl --user start $SERVICE_NAME"
echo "  systemctl --user status $SERVICE_NAME"
echo "  systemctl --user enable $SERVICE_NAME  # auto-start on login"
echo "  systemctl --user stop $SERVICE_NAME"
