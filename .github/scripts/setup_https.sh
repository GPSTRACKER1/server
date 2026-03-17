#!/bin/bash
set -e

DOMAIN=$1
EMAIL=$2

echo "🔐 Configurando HTTPS para ${DOMAIN}..."

# ── Instalar Nginx si no está ─────────────────────────────────────────────────
if ! command -v nginx &> /dev/null; then
  echo "📦 Instalando Nginx..."
  sudo apt update -qq
  sudo apt install -y nginx
fi

# ── Instalar Certbot si no está ───────────────────────────────────────────────
if ! command -v certbot &> /dev/null; then
  echo "📦 Instalando Certbot..."
  sudo apt update -qq
  sudo apt install -y certbot python3-certbot-nginx
fi

# ── Escribir config de Nginx ──────────────────────────────────────────────────
sudo tee /etc/nginx/sites-available/gps-tracker > /dev/null << NGINX
server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
NGINX

sudo ln -sf /etc/nginx/sites-available/gps-tracker /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

echo "✅ Nginx configurado"

# ── Generar certificado SSL ───────────────────────────────────────────────────
echo "🔑 Generando certificado SSL..."
sudo certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos -m ${EMAIL} --keep-until-expiring

echo "✅ HTTPS listo en https://${DOMAIN}"