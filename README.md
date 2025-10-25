## DerbyNet with Docker on Windows + Tailscale (recommended)

Quickstart (TL;DR)

Follow these 4 steps on a Windows machine that will host DerbyNet (install Docker Desktop first):

1) Open PowerShell and verify Docker is available:

```powershell
docker version
docker compose version
```

2) Prepare the repository and `.env`:

```powershell
cd C:\Derbynet
Copy-Item .env.example .env -ErrorAction SilentlyContinue
notepad .env   # set TIMER_PASSWORD, PHOTO_PASSWORD, DATA_DIR (and HTTP_PORT if you want a non-default port)
```

3) Start DerbyNet using the helper script (this runs `docker compose up -d` and opens the site):

```powershell
.\start-derbynet.ps1
```

4) Confirm DerbyNet is running and watch logs if needed:

```powershell
docker compose ps
docker compose logs --tail 200 derbynet
```

This README contains more detailed guidance (Tailscale, LAN, firewall notes) below.

This guide removes the containerized Tailscale instructions and focuses on the recommended Windows setup: run DerbyNet in Docker Desktop and run Tailscale natively on the Windows host. Other machines on the same Tailnet will be able to reach DerbyNet using the host's Tailscale IP.

Note about security and exposed ports

- DerbyNet exposes an HTTP port (default 8050) from the container to the host. If your host is only accessible on a private LAN or via Tailscale/VPN, this is usually low risk for local event use.
- If the host will be reachable from untrusted networks (public Internet), change the role passwords in `.env` to strong values and consider additional protections (firewall rules, VPN-only access, or placing the service behind a reverse proxy with authentication).
- You can limit exposure by adding a Windows firewall rule that allows access only from your LAN subnet (see the `Router / firewall steps` section), or by using Tailscale to avoid exposing the port to the public internet.

Files in this folder:

- `docker-compose.yml` — runs the DerbyNet container (service: `derbynet`).
- `.env.example` — copy to `.env` and edit passwords/ports/data dir.
- `start-derbynet.ps1` — helper script to copy `.env.example` to `.env` (if missing), start the compose stack, show status, and open the local URL.

Prerequisites

- Docker Desktop for Windows (required). Make sure Docker Desktop is installed, running, and you can use the `docker` and `docker compose` commands from PowerShell. If you don't have Docker Desktop, download and install it from https://www.docker.com/products/docker-desktop.
- Tailscale desktop app for Windows (download from https://tailscale.com/download).

Step-by-step (Windows host)

1) Prepare env and start the DerbyNet container (Windows)

   - Ensure Docker Desktop is installed and running. Open PowerShell and verify Docker is accessible:

   ```powershell
   docker version
   docker compose version
   ```

   - From an Administrator or regular PowerShell session (depending on your Docker Desktop setup), prepare the `.env` file and start DerbyNet:

   ```powershell
   cd C:\Derbynet
   # If you don't have a .env yet, copy the example. This will be a no-op if .env already exists.
      Copy-Item .env.example .env -ErrorAction SilentlyContinue

       # Edit .env to set TIMER_PASSWORD, PHOTO_PASSWORD, DATA_DIR, and (optionally) HTTP_PORT
       notepad .env

       # Use the helper script to start the stack. Note: `start-derbynet.ps1` will automatically copy
       # `.env.example` to `.env` if `.env` does not exist, run `docker compose up -d`, show the containers
       # and open the site in your browser. Because of that behavior, an additional interactive
       # `make-env.ps1` helper is optional — it can make initial values easier to type, but is not
       # strictly required.
       .\start-derbynet.ps1
   ```

   - Confirm the container is running and inspect logs if needed:

   ```powershell
   docker compose ps
   docker compose logs --tail 200 derbynet
   ```

2) Install Tailscale on the Windows host

   - Download and install the Tailscale Windows app: https://tailscale.com/download
   - After install, sign in with your Tailscale account (use the same account/team for all devices that need access).
   - Once signed in, click the Tailscale tray icon and note the IPv4 address listed (it typically looks like 100.x.y.z). That is the address other Tailnet machines will use.

3) (Optional) Allow Docker-hosted port through Windows Firewall

   If other devices cannot reach your DerbyNet site via the Tailscale IP, add a firewall rule to allow inbound traffic on the HTTP port you chose (default 8050). Note: Docker Desktop may also be using Windows networking features that interact with the firewall.

   Example PowerShell command (run as Administrator):

   ```powershell
   New-NetFirewallRule -DisplayName "Allow DerbyNet HTTP" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8050
   ```

4) From another machine on the same Tailnet

   - Open a browser and visit:

   ```text
   http://<tailscale-ip>:8050
   ```

   - Use the DerbyNet passwords you configured in `.env` for the timer, photo, and race-crew clients.

Notes about clients (timer, replay, next-in-line)

- DerbyNet uses role passwords (TIMER_PASSWORD, PHOTO_PASSWORD, etc.). Make sure each client uses the same password from your `.env` file.
- If a client is a Raspberry Pi running a replay or timer client, install Tailscale on the Pi and use the Pi's Tailscale client (or just point the Pi's browser to the host's Tailscale IP and port).

Troubleshooting

- If DerbyNet appears healthy locally but remote Tailnet machines can't connect:
  - Verify the Windows host is listed and online in the Tailscale admin console and note its Tailnet IP.
  - Ensure Windows firewall allows inbound traffic on the DerbyNet port (8050).
  - Run `docker compose logs derbynet` to spot application-level errors.

- If you want clients to reach the container via a static DNS name, consider using Tailscale's MagicDNS (enable in the admin console) and use the host's Tailnet DNS name.

Security

- Do not publish your Tailscale auth key. Installing Tailscale on the Windows host via the desktop app avoids needing to expose any auth key.
- Keep DerbyNet backups by ensuring the data volume (`/var/lib/derbynet`) is persisted to a host folder (`DATA_DIR` in `.env`).

If you'd like, I can:

- add an interactive `make-env.ps1` script that prompts for role passwords and writes `.env` securely, or
- create a short Pi/Raspberry-Pi playbook to install Tailscale and set up a replay client pointing to the host's Tailnet IP.

Applying password changes

If you edit `.env` to change role passwords, note that the running DerbyNet instance will not automatically pick up those values if a `config-roles.inc` already exists in your data directory (`DATA_DIR` / `/var/lib/derbynet`). To apply changes you have two safe options:

- Manual edit: update the mounted `config-roles.inc` file directly (host path `L:\Derbynet\data\config-roles.inc`) and then restart the service:

```powershell
notepad L:\Derbynet\data\config-roles.inc
docker compose restart derbynet
```

- Regenerate from `.env`: run a script (see `generate-config-roles.ps1` example in this repo) that writes `/var/lib/derbynet/config-roles.inc` based on current `.env`, then recreate the container so the new file is used. Use this command to recreate containers and ensure new env/file values are applied:

```powershell
docker compose up -d --force-recreate
```

Use `--force-recreate` whenever you change `.env` (and the container’s startup behavior depends on env values) to ensure the container is started with the new environment.

Separate router / local LAN (three-computer setup)

If you have a separate router handling connectivity for three local machines (recommended for performance and isolation), you can run DerbyNet on the main host and have the replay kiosk and race-crew display connect over the LAN rather than via Tailscale. Below is a suggested network setup and steps to verify connectivity.

Topology

- Main host (DerbyNet server) — Windows machine running Docker Desktop. Also connected: timer device and camera.
- Replay kiosk — Windows or Linux machine attached to a TV for instant replay.
- Race-crew display — small PC or tablet that shows next-in-line.

ASCII topology (simple)

```
                        +------------------+
                        |     Router /     |
                        |  Event Network   |
                        +--------+---------+
                                     |
            +----------------+----------------+
            |                |                |
   +-----v----+     +-----v----+     +-----v----+
   |  Main    |     | Replay   |     | Race-    |
   |  Host    |     | Kiosk    |     | Crew     |
   | (DerbyNet)|    | (TV)     |     | Display  |
   | timer/cam|     |          |     |          |
   +----------+     +----------+     +----------+

   - Main Host runs Docker Desktop and hosts the DerbyNet container.
   - Replay Kiosk and Race-Crew Display connect to the Main Host over the router/LAN.
```

Recommendations

- Use static DHCP leases on your router (assign by MAC address) or configure static IPs on each machine so addresses do not change during an event.
- Choose an HTTP port for DerbyNet (default 8050) and ensure the router and Windows firewall allow traffic on that port between these LAN hosts.
- Prefer local LAN addressing for lowest latency. Tailscale adds convenience for remote access but local LAN is simpler and faster for same-network devices.

Router / firewall steps

1. Reserve static DHCP leases for each device in your router admin UI (or set static IP on the device).

2. On the Windows host (DerbyNet server), allow inbound traffic on the DerbyNet port from the LAN subnet (run as Administrator).

Replace <LAN_SUBNET> below with your local subnet (for example `192.168.1.0/24`) or omit `-RemoteAddress` to allow from any remote address.

```powershell
# allow access from the local LAN (replace <LAN_SUBNET> with your subnet)
New-NetFirewallRule -DisplayName "Allow DerbyNet LAN" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8050 -RemoteAddress "<LAN_SUBNET>"
```

3. If your router has client isolation features (AP/client isolation, guest mode), disable them for the DerbyNet event network so devices can reach the host.

Verification

- From the replay kiosk or race-crew display, check you can reach the main host's DerbyNet web UI in a browser (replace <main-host-ip> with the host's LAN IP):

```text
http://<main-host-ip>:8050
```

- Use PowerShell or a terminal to test HTTP reachability (replace IP with your host IP):

```powershell
# PowerShell (from replay kiosk/race-crew machine)
Test-NetConnection -ComputerName <main-host-ip> -Port 8050

# Or using curl (Windows 10/11 PowerShell or Linux)
curl -v http://<main-host-ip>:8050/
```

Notes about mixed Tailscale + LAN access

- You can run Tailscale on all machines and still use local LAN addresses for best performance. If Tailscale is installed, users can reach the host either at `http://<lan-ip>:8050` or `http://<tailscale-ip>:8050` depending on which network path they prefer.
- If you rely on the Windows host's Tailscale IP for remote access, ensure the router's firewall does not block outbound Tailscale traffic; typically Tailscale works over HTTPS/UDP and should traverse NAT.

Camera and timer connectivity notes

- If the timer and camera are physically connected to the main host (USB or local capture devices), make sure the Docker container has access to any necessary host resources (the current compose file assumes the DerbyNet service serves the web UI and uses host-mounted data for persisted files).
- If the camera or timer expose network endpoints, ensure they are reachable from the host (test with curl or vendor tools) and that any required ports are permitted.

Security reminder

- When using a LAN for clients, lock down the network during events (use a separate VLAN or Wi-Fi SSID if possible) so only authorized devices can reach the DerbyNet host.