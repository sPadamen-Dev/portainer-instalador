# 🚀 Portainer Instalador

Instalador automatizado para Portainer com suporte a Traefik, HTTPS com Let's Encrypt, e integração com subdomínios personalizados via Docker.

Ideal para VPSs que desejam gerenciar containers com segurança, escalabilidade e painel web intuitivo.

---

## ✅ Pré-requisitos

- VPS com Ubuntu/Debian (ou compatível)
- Acesso root ou `sudo`
- Domínio com DNS configurável
- Portas 80 e 443 liberadas no firewall

---

## 🌐 Configuração DNS

Crie os seguintes registros **tipo A** apontando para o IP da sua VPS:

| Subdomínio         | Tipo | Valor              |
|--------------------|------|--------------------|
| `portianer` e `www.portainer` | A    | `SEU.IP.VPS`       | 
| `traefik` e `www.traefik`   | A    | `SEU.IP.VPS`       |
| `edge` e `www.edge`      | A    | `SEU.IP.VPS`       |

> ⚠️ No Cloudflare, mantenha o modo **"DNS Only"** (ícone de nuvem **cinza**) para funcionar com Let's Encrypt.

---

## 🚀 Instalação Rápida

Execute o comando abaixo na sua VPS:

```bash
sudo apt update && sudo apt install -y git && \
git clone https://github.com/sPadamen-Dev/portainer-instalador.git && \
cd portainer-instalador && sudo chmod +x install.sh && ./install.sh
