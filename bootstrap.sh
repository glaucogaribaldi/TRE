#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="https://github.com/glaucogaribaldi/TRE.git"
INSTALL_DIR="$HOME/TRE"
CURRENT_USER="${SUDO_USER:-$USER}"

log(){ printf '\n\033[1;36m[TRE]\033[0m %s\n' "$*"; }
fail(){ echo "ERRORE: $*" >&2; exit 1; }

[[ "$(uname -s)" == Linux ]] || fail "Questo bootstrap è previsto per Ubuntu Linux"
command -v sudo >/dev/null || fail "sudo non disponibile"
sudo -v

log "Aggiornamento pacchetti e installazione componenti di base"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git curl ca-certificates jq age zenity openssh-client openssh-server \
  ufw xrdp xfce4 xfce4-goodies dbus-x11 policykit-1

log "Installazione Tailscale"
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
sudo systemctl enable --now tailscaled ssh xrdp

log "Configurazione desktop remoto sulla sola rete Tailscale"
printf 'startxfce4\n' > "$HOME/.xsession"
chmod 600 "$HOME/.xsession"
sudo adduser xrdp ssl-cert >/dev/null 2>&1 || true
sudo ufw --force enable
sudo ufw allow in on tailscale0 to any port 22 proto tcp comment 'TRE SSH via Tailscale' || true
sudo ufw allow in on tailscale0 to any port 3389 proto tcp comment 'TRE RDP via Tailscale' || true
sudo ufw deny 3389/tcp || true
sudo ufw deny 22/tcp || true
sudo systemctl restart xrdp

log "Download repository TRE"
if [[ -d "$INSTALL_DIR/.git" ]]; then
  git -C "$INSTALL_DIR" pull --ff-only
else
  rm -rf "$INSTALL_DIR"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

log "Installazione vault cifrato"
sudo install -d -m 700 /etc/tre /var/lib/tre/vault /var/log/tre
if [[ ! -s /etc/tre/age.key ]]; then
  sudo age-keygen -o /etc/tre/age.key
fi
sudo chmod 600 /etc/tre/age.key
sudo install -m 755 "$INSTALL_DIR/scripts/tre-vault" /usr/local/bin/tre-vault
sudo install -m 755 "$INSTALL_DIR/scripts/tre-secrets-gui" /usr/local/bin/tre-secrets-gui
sudo /usr/local/bin/tre-vault init

log "Installazione OpenClaw"
if ! command -v openclaw >/dev/null 2>&1; then
  curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --no-onboard
fi

log "Creazione identità e workspace TRE"
mkdir -p "$HOME/.openclaw/workspace" "$HOME/.config/tre"
cp -f "$INSTALL_DIR/openclaw/IDENTITY.md" "$HOME/.openclaw/workspace/IDENTITY.md"
cp -f "$INSTALL_DIR/openclaw/SECURITY.md" "$HOME/.openclaw/workspace/SECURITY.md"
cp -f "$INSTALL_DIR/openclaw/TOOLS.md" "$HOME/.openclaw/workspace/TOOLS.md"
cp -f "$INSTALL_DIR/openclaw/MEMORY.md" "$HOME/.openclaw/workspace/MEMORY.md"
chown -R "$CURRENT_USER":"$CURRENT_USER" "$HOME/.openclaw" "$HOME/.config/tre" "$INSTALL_DIR"
chmod 700 "$HOME/.openclaw" "$HOME/.config/tre"

cat > "$HOME/.config/tre/config.json" <<EOF
{
  "agent_name": "TRE",
  "host_name": "u50-tre",
  "vault_command": "sudo /usr/local/bin/tre-vault",
  "remote_desktop": {
    "protocol": "RDP",
    "port": 3389,
    "network": "tailscale-only"
  },
  "model_router": {
    "primary": "gemini",
    "alternatives": ["nemotron"]
  }
}
EOF
chmod 600 "$HOME/.config/tre/config.json"

log "Avvio configurazione grafica TRE"
/usr/local/bin/tre-secrets-gui

log "Configurazione iniziale OpenClaw"
echo
printf 'Il vault è pronto. Completa ora l’onboarding di OpenClaw.\n'
printf 'Quando richiesto, il nome dell’agente è TRE.\n\n'
openclaw onboard --install-daemon

log "Bootstrap completato"
TS_IP="$(tailscale ip -4 2>/dev/null | head -n1 || true)"
echo "IP Tailscale: ${TS_IP:-non disponibile}"
echo "Da Windows App usa: ${TS_IP:-IP_TAILSCALE}:3389"
echo "Credenziali RDP: utente Ubuntu '$CURRENT_USER' e relativa password Ubuntu"
echo "Gestione segreti: sudo tre-vault help"
