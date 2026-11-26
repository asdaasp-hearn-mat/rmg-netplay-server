# rmg-netplay-server

A reproducible, self-contained setup for building and hosting **Rosalie's Mupen GUI (RMG)** Netplay sessions (configured out-of-the-box for *Mario Party 2* or general N64 netplay).

## Supported Emulators
* [RMG (Rosalie's Mupen GUI)](https://github.com/Rosalie241/RMG)

---

## 1. Quick Start (From Scratch)

The binary `rmg-netplay-server` is not tracked in Git; instead, it is compiled locally from source (`main.go`) using either **Go** natively or a container engine (**Podman** / **Docker** via `Containerfile`).

```bash
# 1. Clone the repository
git clone git@github.com:asdaasp-hearn-mat/rmg-netplay-server.git
cd rmg-netplay-server

# 2. Build and start the server
# (If the binary does not exist yet, start.sh automatically invokes build.sh)
./start.sh
```

To build the static binary manually without starting the server:
```bash
./build.sh              # Auto-detects Go, Podman, or Docker
./build.sh --container  # Forces container-based build via Podman/Docker
```

---

## 2. Connection Methods

When `./start.sh` or `./update-ip.sh` runs, it detects the host's network interfaces and generates untracked JSON files (`servers*.json`) ready to be loaded into RMG.

### Method A: Tailscale (Recommended — Zero Router / Firewall Setup)
If both the host and clients are connected to the same Tailscale network (Tailnet):
* **No router port forwarding** or firewall changes required.
* Works across different networks, CGNAT, and Wi-Fi AP isolation via an encrypted WireGuard tunnel.

**Steps:**
1. Ensure Tailscale is active on both the host and client machines.
2. Run `./start.sh` on the host machine. This generates `servers-tailscale.json` containing the host's Tailscale IP (e.g. `100.x.y.z`).
3. Share `servers-tailscale.json` with the client machine(s) and configure RMG (**Settings** -> **Netplay** -> **Server list URL**).
4. Select `Mario Party 2 Server (Tailscale)` in RMG's Netplay dialog.

### Method B: Local Area Network (LAN)
* On the same local network, RMG can discover the server automatically via UDP broadcast on port `45000`.
* Alternatively, load the generated `servers-lan.json` on other LAN machines so they connect directly to the host's LAN IP (e.g. `192.168.1.x`).

### Method C: Port Forwarding (Direct Internet)
To host for remote players over the public Internet without Tailscale:
* **Required Ports**: `45000–45010` on both **TCP** and **UDP**
  * `45000 TCP`: WebSocket Lobby & API (room listing, chat, matchmaking)
  * `45000 UDP`: LAN broadcast discovery
  * `45001–45010 TCP & UDP`: Dynamic game room ports (one port per active room)
* **Router Configuration**: Forward ports `45000` to `45010` (`TCP/UDP`) to your host's local LAN IP.
* Share the generated `servers-public.json` (or host it on a raw GitHub Gist / Pastebin link) for remote players to paste into **Server list URL**.

---

## 3. Server Management

### Option 1: Native Scripts (Lightweight & Portable)
The compiled `rmg-netplay-server` binary is statically linked (`CGO_ENABLED=0`) and has zero runtime dependencies.

* **Start server in background**:
  ```bash
  ./start.sh
  ```
* **View live logs**:
  ```bash
  tail -f server.log
  ```
* **Stop server**:
  ```bash
  ./stop.sh
  ```
* **Refresh IP files (`servers*.json`)**:
  ```bash
  ./update-ip.sh
  ```

### Option 2: Containerized Execution (Podman / Docker Compose)
Ideal for deploying to a dedicated server or VPS (`network_mode: host` is used to preserve UDP broadcast and dynamic port range binding):
```bash
# Start container in background
podman-compose up -d   # or: docker compose up -d

# Follow container logs
podman logs -f rmg-netplay-server

# Stop container
podman-compose down    # or: docker compose down
```

### Option 3: Systemd User Service
To run the server automatically as a background user service:
```bash
./install-service.sh
systemctl --user start rmg-netplay-server
systemctl --user status rmg-netplay-server
systemctl --user enable rmg-netplay-server  # Optional: auto-start on login
```

---

## 4. Configuring the RMG Client

1. Open **RMG** and go to **Settings** -> **Netplay**.
2. In **Server list URL**, enter the absolute path to the appropriate JSON file on that machine (or an `http://` / `https://` raw URL):
   ```text
   /path/to/servers-tailscale.json
   ```
   > **Note:** When using a local file path, provide the standard filesystem path (`/home/user/...`) **without** a `file://` prefix.
3. Click **Save**.
4. Open **Netplay** -> **Create Session** (Host) or **Join Session** (Client) and select the server from the dropdown.
5. **ROM Verification:** All players joining a room must use the exact same ROM file (RMG validates that the ROM's MD5 checksum matches the room creator's ROM).
