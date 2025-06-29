#!/usr/bin/env bash
#
# install-portainer-traefik.sh
# Instalação automatizada do Portainer CE + Traefik (com domínio opcional)

set -euo pipefail

# ===== VARIÁVEIS PADRÃO =====
PORTAINER_VOLUME="portainer_data"
TRAEFIK_DIR="/opt/traefik"
NETWORK_NAME="traefik"
TRAEFIK_CONTAINER="traefik"
PORTAINER_CONTAINER="portainer"
UI_PORT=9443
EDGE_PORT=8000
LEGACY_PORT=9000

# ===== COLETAR CONFIG VIA MENU =====
echo "🌐 Configuração Traefik:"
read -rp "👉 Deseja usar domínio personalizado (s/n)? " use_domain

if [[ "$use_domain" =~ ^[Ss]$ ]]; then
  read -rp "🔤 Digite o domínio (ex: portainer.seudominio.com): " DOMAIN
  read -rp "📧 Digite o e-mail para Let's Encrypt: " EMAIL
  USE_TLS=true
else
  DOMAIN="localhost"
  EMAIL="dev@localhost"
  USE_TLS=false
fi

echo ""
echo "📦 Instalação para domínio: $DOMAIN"
echo "📨 E-mail Let's Encrypt: $EMAIL"
echo ""

# ===== INSTALAR DOCKER (se necessário) =====
if ! command -v docker &>/dev/null; then
  echo "➡️ Instalando Docker..."
  apt-get update
  apt-get install -y ca-certificates curl gnupg lsb-release
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
    $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io
  echo "✔️ Docker instalado com sucesso."
else
  echo "✔️ Docker já está instalado."
fi

# ===== CRIAR REDE DOCKER =====
docker network inspect "$NETWORK_NAME" >/dev/null 2>&1 || docker network create "$NETWORK_NAME"

# ===== INSTALAR TRAEFIK =====
echo "⚙️ Configurando Traefik em: $TRAEFIK_DIR"
mkdir -p "$TRAEFIK_DIR/letsencrypt"
touch "$TRAEFIK_DIR/letsencrypt/acme.json"
chmod 600 "$TRAEFIK_DIR/letsencrypt/acme.json"

cat > "$TRAEFIK_DIR/traefik.yml" <<EOF
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  docker:
    exposedByDefault: false

api:
  dashboard: true
EOF

if [[ "$USE_TLS" == true ]]; then
cat >> "$TRAEFIK_DIR/traefik.yml" <<EOF
certificatesResolvers:
  letsencrypt:
    acme:
      email: $EMAIL
      storage: /letsencrypt/acme.json
      tlsChallenge: true
EOF
fi

# Remove Traefik antigo se existir
docker rm -f "$TRAEFIK_CONTAINER" 2>/dev/null || true

echo "🚀 Subindo Traefik..."
docker run -d \
  --name "$TRAEFIK_CONTAINER" \
  --restart=always \
  -p 80:80 \
  -p 443:443 \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v "$TRAEFIK_DIR/letsencrypt:/letsencrypt" \
  -v "$TRAEFIK_DIR/traefik.yml:/etc/traefik/traefik.yml" \
  --network "$NETWORK_NAME" \
  traefik:v2.11

# ===== INSTALAR PORTAINER =====
docker rm -f "$PORTAINER_CONTAINER" 2>/dev/null || true
docker volume create "$PORTAINER_VOLUME" || true

echo "🚀 Subindo Portainer..."
if [[ "$USE_TLS" == true ]]; then
  docker run -d \
    --name "$PORTAINER_CONTAINER" \
    --restart=always \
    --network "$NETWORK_NAME" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PORTAINER_VOLUME:/data" \
    -l "traefik.enable=true" \
    -l "traefik.http.routers.portainer.rule=Host(\`$DOMAIN\`)" \
    -l "traefik.http.routers.portainer.entrypoints=websecure" \
    -l "traefik.http.routers.portainer.tls.certresolver=letsencrypt" \
    -l "traefik.http.services.portainer.loadbalancer.server.port=$UI_PORT" \
    portainer/portainer-ce:latest
else
  docker run -d \
    --name "$PORTAINER_CONTAINER" \
    --restart=always \
    -p "$LEGACY_PORT:9000" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PORTAINER_VOLUME:/data" \
    portainer/portainer-ce:latest
fi

# ===== FINAL =====
echo ""
echo "✅ Portainer instalado com sucesso!"
if [[ "$USE_TLS" == true ]]; then
  echo "🌐 Acesse: https://$DOMAIN"
else
  echo "🌐 Acesse: http://localhost:9000"
fi
echo "ℹ️  Dashboard Traefik (se habilitado): http://localhost:8080/dashboard/"

