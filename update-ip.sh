#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVERS_JSON="$SCRIPT_DIR/servers.json"
SERVERS_LAN_JSON="$SCRIPT_DIR/servers-lan.json"
SERVERS_TAILSCALE_JSON="$SCRIPT_DIR/servers-tailscale.json"
SERVERS_PUBLIC_JSON="$SCRIPT_DIR/servers-public.json"

# Detect local IP
LOCAL_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}' | tr -d '\n' || echo "127.0.0.1")
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP="127.0.0.1"
fi

# Detect Tailscale IP if active
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || ip -4 addr show tailscale0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1 || echo "")

# Detect public IP
echo "Detecting public IP address..."
PUBLIC_IP=$(curl -s --max-time 4 https://api.ipify.org 2>/dev/null || curl -s --max-time 4 https://ifconfig.me 2>/dev/null || echo "")

if [ -z "$PUBLIC_IP" ]; then
    echo "Warning: Could not automatically detect public IP. Falling back to local IP ($LOCAL_IP)."
    PUBLIC_IP="$LOCAL_IP"
fi

echo "=========================================="
echo "Local IP (LAN):    $LOCAL_IP"
if [ -n "$TAILSCALE_IP" ]; then
    echo "Tailscale IP:      $TAILSCALE_IP"
fi
echo "Public IP:         $PUBLIC_IP"
echo "=========================================="

# Create local servers.json (for Host machine)
if [ -n "$TAILSCALE_IP" ]; then
cat <<EOF > "$SERVERS_JSON"
{
  "Mario Party 2 (Local)": "127.0.0.1",
  "Mario Party 2 (Tailscale: $TAILSCALE_IP)": "$TAILSCALE_IP",
  "Mario Party 2 (LAN: $LOCAL_IP)": "$LOCAL_IP",
  "Mario Party 2 (Internet: $PUBLIC_IP)": "$PUBLIC_IP"
}
EOF

# Create Tailscale-only JSON (for Tailscale peers)
cat <<EOF > "$SERVERS_TAILSCALE_JSON"
{
  "Mario Party 2 Server (Tailscale)": "$TAILSCALE_IP"
}
EOF
else
cat <<EOF > "$SERVERS_JSON"
{
  "Mario Party 2 (Local)": "127.0.0.1",
  "Mario Party 2 (LAN: $LOCAL_IP)": "$LOCAL_IP",
  "Mario Party 2 (Internet: $PUBLIC_IP)": "$PUBLIC_IP"
}
EOF
fi

# Create LAN-only JSON (for local network peers)
cat <<EOF > "$SERVERS_LAN_JSON"
{
  "Mario Party 2 Server (LAN)": "$LOCAL_IP"
}
EOF

# Create public servers-public.json (for remote players over Internet)
cat <<EOF > "$SERVERS_PUBLIC_JSON"
{
  "Mario Party 2 Server": "$PUBLIC_IP"
}
EOF

echo "Files generated successfully:"
echo " - $SERVERS_JSON (Host machine)"
if [ -n "$TAILSCALE_IP" ]; then
    echo " - $SERVERS_TAILSCALE_JSON (Tailscale peers - Recommended!)"
fi
echo " - $SERVERS_LAN_JSON (Local network peers)"
echo " - $SERVERS_PUBLIC_JSON (Remote players over Internet)"
