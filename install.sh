#!/bin/bash

clear
echo "==============================="
echo "🔧 Instalador Interativo - Portainer + Docker"
echo "==============================="

# Função: instala o Docker
instalar_docker() {
  echo "📦 Verificando Docker..."
  if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    curl -fsSL https://get.docker.com | bash
    systemctl enable docker
    systemctl start docker
    echo "✅ Docker instalado com sucesso!"
  else
    echo "✅ Docker já está instalado."
  fi

  if ! command -v docker-compose &> /dev/null; then
    echo "Instalando Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose instalado com sucesso!"
  else
    echo "✅ Docker Compose já está instalado."
  fi
}

# Função: instala o Portainer com proxy reverso
instalar_portainer() {
  echo "🔧 Configurando Portainer com domínio personalizado"

  read -p "🌐 Digite o domínio (ex: portainer.seudominio.com): " DOMAIN
  read -p "📧 Digite seu e-mail para SSL (Let's Encrypt): " EMAIL

  echo "🔧 Criando rede docker: proxy (se não existir)"
  docker network create proxy &> /dev/null || echo "Rede já existe."

  echo "📁 Criando diretório de trabalho ~/portainer-setup"
  mkdir -p ~/portainer-setup && cd ~/portainer-setup

  echo "📝 Gerando docker-compose.yml"
  cat > docker-compose.yml <<EOF
version: '3'

services:
  nginx-proxy:
    image: jwilder/nginx-proxy
    container_name: nginx-proxy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /etc/nginx/certs:/etc/nginx/certs:ro
      - /etc/nginx/vhost.d
      - /usr/share/nginx/html
      - /var/run/docker.sock:/tmp/docker.sock:ro
    networks:
      - proxy

  letsencrypt:
    image: jrcs/letsencrypt-nginx-proxy-companion
    container_name: nginx-letsencrypt
    restart: always
    environment:
      - DEFAULT_EMAIL=$EMAIL
    volumes:
      - /etc/nginx/certs:/etc/nginx/certs
      - /etc/nginx/vhost.d
      - /usr/share/nginx/html
      - /var/run/docker.sock:/var/run/docker.sock:ro
    depends_on:
      - nginx-proxy
    networks:
      - proxy

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: always
    environment:
      - VIRTUAL_HOST=$DOMAIN
      - LETSENCRYPT_HOST=$DOMAIN
      - LETSENCRYPT_EMAIL=$EMAIL
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    networks:
      - proxy

volumes:
  portainer_data:

networks:
  proxy:
    external: true
EOF

  echo "🚀 Subindo os containers com Docker Compose..."
  docker-compose up -d

  echo "✅ Instalação finalizada com sucesso!"
  echo "🔗 Acesse o Portainer em: https://$DOMAIN"
}

# Menu interativo
while true; do
  echo ""
  echo "==============================="
  echo "Selecione uma opção:"
  select opt in "Instalar Docker" "Instalar Portainer com domínio" "Sair"; do
    case $REPLY in
      1) instalar_docker; break ;;
      2) instalar_portainer; break ;;
      3) echo "🚪 Saindo..."; exit 0 ;;
      *) echo "❌ Opção inválida. Tente novamente." ;;
    esac
  done
done

