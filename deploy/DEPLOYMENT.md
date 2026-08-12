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

## Deploying an update

This is the one canonical procedure — do not improvise variants. Two facts
make the obvious shortcuts fail:

- `systemctl restart timeless-web` alone does NOT deploy new code. The unit
  runs `podman-compose down` + `up` with no `--build`, so it restarts the
  old image.
- `podman-compose up -d --build` alone does NOT replace the running
  container. podman-compose builds the image, then fails with
  `container name "deploy_app_1" is already in use`.

The working flow builds first (the old app keeps serving during the build),
then lets the systemd unit do the swap, so systemd stays the container's
owner. Never run `podman-compose up`/`down` by hand while the unit is
active — the unit's foreground `up` exits when the containers go away and
the service drops to `inactive`, leaving the next container unmanaged.

```bash
# 1. On your machine: bump deps in mix.exs, mix deps.update <pkgs>,
#    mix test, commit, push to main.

# 2. On the server:
cd /opt/timeless_web && sudo git pull --ff-only
cd deploy && sudo podman-compose build   # old app still serving
sudo systemctl restart timeless-web      # unit swaps to the fresh image

# 3. Verify:
sudo systemctl is-active timeless-web    # active
sudo podman ps                           # deploy_app_1 Up
sudo podman logs deploy_app_1 | grep -E "extension|Running"
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5880/       # 200
curl -s -o /dev/null -w '%{http_code}\n' https://timelessmetrics.com/ # 200
```

Optional deeper check — engine stats on the live node (raw blocks should
trend to 0 within a couple minutes as auto-optimize drains any backlog):

```bash
sudo podman exec deploy_app_1 /app/bin/timeless_web rpc \
  'TimelessLogs.LibsqlEngine.stats() |> IO.inspect()'
```

## Managing the deployment

```bash
# Status
sudo systemctl status timeless-web
sudo systemctl status caddy

# Logs
sudo journalctl -u timeless-web -f
sudo journalctl -u caddy -f
```

## Backups

Before major upgrades, archive the named volumes:

```bash
sudo tar -C /var/lib/containers/storage/volumes/timeless_web_db_data/_data -cf timeless_web_db_data.tar .
sudo tar -C /var/lib/containers/storage/volumes/timeless_web_observability_data/_data -cf timeless_web_observability_data.tar .
```
