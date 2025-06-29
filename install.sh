#!/bin/bash

set -e

# Função para exibir banner
function banner() {
  clear
  figlet -f slant "sPadamen-Dev" | lolcat
  echo "======================================================"
  echo " 🚀 Instalador CLI Automático do sPadamen-Dev"
  echo "======================================================"
  echo
}

# Instala docker e dependências
function install_dependencies() {
  echo "Atualizando sistema..."
  sudo apt update && sudo apt upgrade -y
  echo "Instalando Docker, Docker Compose, figlet, lolcat, jq, curl..."
  sudo apt install -y docker.io docker-compose figlet lolcat jq curl

  sudo systemctl enable docker
  sudo systemctl start docker
}

# Checa se domínio aponta para este servidor
function check_domain_dns() {
  local DOMAIN=$1
  echo "🔍 Checando DNS do domínio $DOMAIN..."

  SERVER_IP=$(curl -s https://api.ipify.org)
  DOMAIN_IP=$(dig +short "$DOMAIN" | tail -n1)

  echo "➡ IP do servidor: $SERVER_IP"
  echo "➡ IP do domínio: $DOMAIN_IP"

  if [[ "$SERVER_IP" == "$DOMAIN_IP" ]]; then
    echo "✅ O domínio está apontando corretamente para este servidor."
  else
    echo "⚠️ O domínio NÃO está apontando para este servidor."
    echo "   Verifique o apontamento DNS (A record) antes de prosseguir."
    read -p "Deseja continuar mesmo assim? (s/N): " CONT
    if [[ "$CONT" != "s" && "$CONT" != "S" ]]; then
      echo "Abortando..."
      exit 1
    fi
  fi
}

# Instala o Traefik
function install_traefik() {
  read -p "Informe o e-mail para Let's Encrypt: " LETSENCRYPT_EMAIL

  mkdir -p ~/sPadamen-Dev
  cd ~/sPadamen-Dev

  echo "Criando traefik.yml..."
  cat <<EOF > traefik.yml
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  docker:
    exposedByDefault: false

certificatesResolvers:
  letsencrypt:
    acme:
      email: $LETSENCRYPT_EMAIL
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
EOF

  mkdir -p ./letsencrypt
  touch ./letsencrypt/acme.json
  chmod 600 ./letsencrypt/acme.json

  echo "Gerando docker-compose.yml inicial do Traefik..."
  cat <<EOF > docker-compose.yml
version: "3"

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik.yml:/traefik.yml
      - ./letsencrypt:/letsencrypt
EOF

  docker compose up -d traefik

  banner
  echo "✅ Traefik instalado e configurado com SSL automático."
}

# Instala o Portainer
function install_portainer() {
  read -p "Informe o domínio para o Portainer (ex: portainer.seudominio.com): " DOMAIN

  check_domain_dns "$DOMAIN"

  cd ~/sPadamen-Dev

  echo "Adicionando serviço Portainer ao docker-compose.yml..."
  cat <<EOF >> docker-compose.yml

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer.rule=Host(\`$DOMAIN\`)"
      - "traefik.http.routers.portainer.entrypoints=websecure"
      - "traefik.http.routers.portainer.tls.certresolver=letsencrypt"
      - "traefik.http.services.portainer.loadbalancer.server.port=9443"

volumes:
  portainer_data:
EOF

  docker compose up -d portainer

  banner
  echo "✅ Portainer instalado!"
  echo "🌐 Acesse via: https://$DOMAIN"
}

# Logs do Traefik
function logs_traefik() {
  docker logs -f traefik
}

# Logs do Portainer
function logs_portainer() {
  docker logs -f portainer
}

# Relatório final dos containers
function status_report() {
  banner
  echo "🚀 Status atual dos containers Docker:"
  echo
  docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
  echo
  echo "✅ Todos os serviços rodando. Use as opções de logs para monitorar."
}

# Menu CLI
function show_menu() {
  banner
  echo "1) Instalar Traefik (SSL + proxy)"
  echo "2) Instalar Portainer com domínio personalizado"
  echo "3) Ver logs do Traefik"
  echo "4) Ver logs do Portainer"
  echo "5) Ver relatório de status dos containers"
  echo "6) Sair"
  echo
}

# Execução principal
install_dependencies

while true; do
  show_menu
  read -p "Escolha uma opção: " OPTION
  case $OPTION in
    1) install_traefik ;;
    2) install_portainer ;;
    3) logs_traefik ;;
    4) logs_portainer ;;
    5) status_report ;;
    6) echo "👋 Saindo..."; exit 0 ;;
    *) echo "Opção inválida." ;;
  esac
done

