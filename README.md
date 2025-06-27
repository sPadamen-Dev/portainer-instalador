🛠️ Instalador Automático do Portainer com Traefik e SSL
Este projeto automatiza a instalação completa de um ambiente com:

Docker + Docker Compose

Portainer com SSL via Let's Encrypt

Proxy reverso usando Traefik (opcional)

Instalação interativa via CLI

Configuração baseada em subdomínios para múltiplos serviços

✅ Pré-requisitos
Uma VPS com Linux (Ubuntu/Debian recomendado)

Domínio com DNS gerenciável (Cloudflare, Registro.br, etc)

A porta 80 e 443 liberadas

Docker não precisa estar instalado (o script cuida disso)

🌐 Configuração DNS
Crie os seguintes registros tipo A, todos apontando para o IP público da sua VPS:

Nome DNS	   Tipo 	Valor (Exemplo)

portainer

www.portainer	A	   192.0.2.10


treefik

www.traefik 	A 	 192.0.2.10



edge

www.edge      A	  192.0.2.10


🚀 Instalação

Execute este comando na sua VPS:

```bash
sudo apt update && sudo apt install -y git && git clone https://github.com/sPadamen-Dev/portainer-instalador.git && cd portainer-instalador && sudo chmod +x install.sh && ./install.sh

