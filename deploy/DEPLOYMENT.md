# Deploying Timeless Web

Podman container for the Phoenix app, Caddy for HTTPS and reverse proxy, systemd to manage both.

## Prerequisites

- Debian Trixie server
- DNS A record for `timelessmetrics.com` pointing to the server
- Ports 80 and 443 open

## 1. Install Caddy and Podman

```bash
sudo apt update && sudo apt install -y caddy podman podman-compose
```

## 2. Clone the repo

```bash
sudo git clone https://github.com/awksedgreep/timeless_web.git /opt/timeless_web
```

## 3. Configure the app

```bash
cd /opt/timeless_web/deploy
sudo cp .env.example .env
sudo vi .env
```

Set both values:
- `PHX_HOST=timelessmetrics.com`
- `SECRET_KEY_BASE=` — generate with `mix phx.gen.secret` or `openssl rand -base64 48`

## 4. Build and start the app

```bash
cd /opt/timeless_web/deploy
sudo podman-compose up -d --build
```

The deployment uses two named Podman volumes with fixed names:
- `timeless_web_db_data` for the SQLite database
- `timeless_web_observability_data` for Timeless metrics, logs, and traces

Those volumes survive container rebuilds and `podman-compose down`. Do not use
`podman-compose down -v` unless you intentionally want to delete persistent data.

## 5. Set up Caddy

```bash
sudo cp /opt/timeless_web/deploy/Caddyfile /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

Caddy automatically provisions a TLS certificate from Let's Encrypt and redirects HTTP to HTTPS.

## 6. Enable the app service

```bash
sudo cp /opt/timeless_web/deploy/timeless-web.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now timeless-web
```

## Managing the deployment

```bash
# Status
sudo systemctl status timeless-web
sudo systemctl status caddy

# Logs
sudo journalctl -u timeless-web -f
sudo journalctl -u caddy -f

# Restart after pulling updates
cd /opt/timeless_web
sudo git pull
sudo podman volume ls | grep timeless_web
cd /opt/timeless_web/deploy
sudo systemctl restart timeless-web

# Rebuild from scratch
cd /opt/timeless_web/deploy
sudo podman-compose down
sudo podman-compose up -d --build
```

## Backups

Before major upgrades, archive the named volumes:

```bash
sudo tar -C /var/lib/containers/storage/volumes/timeless_web_db_data/_data -cf timeless_web_db_data.tar .
sudo tar -C /var/lib/containers/storage/volumes/timeless_web_observability_data/_data -cf timeless_web_observability_data.tar .
```
