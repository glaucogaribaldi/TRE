#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="https://github.com/glaucogaribaldi/TRE.git"
INSTALL_DIR="$HOME/TRE"
CURRENT_USER="${SUDO_USER:-$USER}"

log(){ printf '\n\033[1;36m[TRE]\033[0m %s\n' "$*"; }
fail(){ echo "ERRORE: $*" >&2; exit 1; }
trap 'echo "[TRE] Errore alla riga $LINENO" >&2' ERR

[[ "$(uname -s)" == Linux ]] || fail "Bootstrap previsto per Ubuntu Linux"
command -v sudo >/dev/null || fail "sudo non disponibile"
sudo -v

log "Aggiornamento Ubuntu e strumenti di base"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git curl wget ca-certificates gnupg lsb-release jq age zenity \
  openssh-client openssh-server ufw xrdp xfce4 xfce4-goodies \
  dbus-x11 polkitd pkexec build-essential python3 python3-venv python3-pip \
  sqlite3 postgresql-client redis-tools htop btop tmux unzip zip rsync \
  net-tools dnsutils ripgrep fd-find acl fail2ban

log "Installazione GitHub CLI"
if ! command -v gh >/dev/null 2>&1; then
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update && sudo apt-get install -y gh
fi

log "Installazione Docker Engine e Compose"
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sudo sh
fi
sudo systemctl enable --now docker
sudo usermod -aG docker "$CURRENT_USER"

log "Verifica Tailscale"
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
sudo systemctl enable --now tailscaled

log "Configurazione SSH, desktop remoto e firewall Tailscale-only"
sudo systemctl enable --now ssh xrdp fail2ban
printf 'startxfce4\n' > "$HOME/.xsession"
chmod 600 "$HOME/.xsession"
sudo adduser xrdp ssl-cert >/dev/null 2>&1 || true
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0 to any port 22 proto tcp comment 'TRE SSH Tailscale'
sudo ufw allow in on tailscale0 to any port 3389 proto tcp comment 'TRE RDP Tailscale'
sudo ufw --force enable
sudo systemctl restart xrdp

log "Download o aggiornamento repository TRE"
if [[ -d "$INSTALL_DIR/.git" ]]; then
  git -C "$INSTALL_DIR" pull --ff-only
else
  rm -rf "$INSTALL_DIR"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

log "Installazione vault cifrato TRE"
sudo install -d -m 700 /etc/tre /var/lib/tre/vault /var/log/tre
if [[ ! -s /etc/tre/age.key ]]; then
  sudo age-keygen -o /etc/tre/age.key
fi
sudo chmod 600 /etc/tre/age.key
sudo install -m 755 "$INSTALL_DIR/scripts/tre-vault" /usr/local/bin/tre-vault
sudo install -m 755 "$INSTALL_DIR/scripts/tre-secrets-gui" /usr/local/bin/tre-secrets-gui
sudo /usr/local/bin/tre-vault init

log "Configurazione sudo operativo per il profilo TRE"
echo "$CURRENT_USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/90-tre-openclaw >/dev/null
sudo chmod 440 /etc/sudoers.d/90-tre-openclaw
sudo visudo -cf /etc/sudoers.d/90-tre-openclaw >/dev/null

log "Installazione OpenClaw ufficiale"
export PATH="$HOME/.npm-global/bin:$PATH"
if ! command -v openclaw >/dev/null 2>&1; then
  curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --no-onboard
  export PATH="$HOME/.npm-global/bin:$PATH"
  hash -r
fi
command -v openclaw >/dev/null 2>&1 || fail "OpenClaw installato ma non disponibile nel PATH"

log "Creazione workspace e identità TRE"
mkdir -p "$HOME/.openclaw/workspace" "$HOME/.config/tre" "$HOME/tre-data"/{postgres,redis,qdrant,backups,logs}
for f in IDENTITY SECURITY TOOLS MEMORY; do
  cp -f "$INSTALL_DIR/openclaw/$f.md" "$HOME/.openclaw/workspace/$f.md"
done
chown -R "$CURRENT_USER:$CURRENT_USER" "$HOME/.openclaw" "$HOME/.config/tre" "$HOME/tre-data" "$INSTALL_DIR"
chmod 700 "$HOME/.openclaw" "$HOME/.config/tre" "$HOME/tre-data"

cat > "$HOME/.config/tre/config.json" <<EOF
{
  "agent_name": "TRE",
  "host_name": "u50-tre",
  "vault_command": "sudo /usr/local/bin/tre-vault",
  "remote_desktop": {"protocol":"RDP","port":3389,"network":"tailscale-only"},
  "model_router": {"primary":"gemini","alternatives":["nemotron"]},
  "memory": {
    "phase":1,
    "postgres":{"host":"127.0.0.1","port":55432},
    "redis":{"host":"127.0.0.1","port":56379},
    "qdrant":{"host":"127.0.0.1","port":56333}
  }
}
EOF
chmod 600 "$HOME/.config/tre/config.json"

log "Installazione servizi dati locali"
cat > "$HOME/TRE/docker-compose.core.yml" <<'EOF'
services:
  postgres:
    image: pgvector/pgvector:pg16
    restart: unless-stopped
    environment:
      POSTGRES_USER: tre
      POSTGRES_PASSWORD: tre-local-bootstrap-change-me
      POSTGRES_DB: tre_memory
    volumes:
      - ${HOME}/tre-data/postgres:/var/lib/postgresql/data
    ports:
      - "127.0.0.1:55432:5432"
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: ["redis-server", "--appendonly", "yes"]
    volumes:
      - ${HOME}/tre-data/redis:/data
    ports:
      - "127.0.0.1:56379:6379"
  qdrant:
    image: qdrant/qdrant:latest
    restart: unless-stopped
    volumes:
      - ${HOME}/tre-data/qdrant:/qdrant/storage
    ports:
      - "127.0.0.1:56333:6333"
EOF

sudo docker compose -f "$HOME/TRE/docker-compose.core.yml" down --remove-orphans || true
sudo docker compose -f "$HOME/TRE/docker-compose.core.yml" up -d

log "Configurazione grafica di credenziali e VPS"
/usr/local/bin/tre-secrets-gui

log "Onboarding OpenClaw"
echo "Completa l'onboarding. Nome agente: TRE. Modello iniziale: Gemini 2.5 Flash."
openclaw onboard --install-daemon
openclaw doctor || true

log "Controllo finale"
TS_IP="$(tailscale ip -4 2>/dev/null | head -n1 || true)"
echo ""
echo "TRE INSTALLATO"
echo "IP Tailscale: ${TS_IP:-non disponibile}"
echo "Windows App / RDP: ${TS_IP:-IP_TAILSCALE}:3389"
echo "Dashboard OpenClaw locale: http://127.0.0.1:18789/"
echo "Repository locale: $INSTALL_DIR"
echo "Vault: sudo tre-vault help"
echo "PostgreSQL TRE: 127.0.0.1:55432"
echo "Redis TRE: 127.0.0.1:56379"
echo "Qdrant TRE: 127.0.0.1:56333"
echo "Nota: esegui logout/login una volta per applicare il gruppo Docker."
