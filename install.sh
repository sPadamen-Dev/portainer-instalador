#!/bin/bash

clear
echo "🚀 Instalador Automático do Portainer + Traefik"
echo "----------------------------------------------"

# Verifica dependências
echo "🔍 Verificando dependências..."
which docker &> /dev/null || {
  echo "🐳 Instalando Docker..."
  curl -fsSL https://get.docker.com | sudo sh
}

which docker-compose &> /dev/null || {
  echo "🧩 Instalando Docker Compose..."
  sudo apt install -y docker-compose
}

# Coleta informações do usuário
read -p "🌐 Informe seu domínio base (ex: meudominio.com): " BASE_DOMAIN
read -p "📧 Informe seu e-mail para SSL (Let's Encrypt): " EMAIL

PORTAINER_HOST="portainer.$BASE_DOMAIN"
TRAEFIK_HOST="traefik.$BASE_DOMAIN"

# Cria estrutura de pastas
mkdir -p portainer-traefik/{letsencrypt,volumes}
cd portainer-traefik || exit

# Gera docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    restart: always
    command:
      - "--api.dashboard=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--providers.docker=true"
      - "--certificatesresolvers.myresolver.acme.email=$EMAIL"
      - "--certificatesresolvers.myresolver.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./letsencrypt:/letsencrypt"
    networks:
      - web

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: always
    command: -H unix:///var/run/docker.sock
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer.rule=Host(\`$PORTAINER_HOST\`)"
      - "traefik.http.routers.portainer.entrypoints=websecure"
      - "traefik.http.routers.portainer.tls.certresolver=myresolver"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "./volumes/portainer_data:/data"
    networks:
      - web

networks:
  web:
    external: false
EOF

echo "📦 Criando containers..."
docker-compose up -d

echo "✅ Instalação finalizada com sucesso!"
echo "🌐 Acesse o Portainer em: https://$PORTAINER_HOST"
echo "📊 Dashboard do Traefik: https://$TRAEFIK_HOST"

