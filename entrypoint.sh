#!/bin/sh
set -e

# Cria diretórios de cron e log (Alpine não cria automaticamente)
mkdir -p /etc/periodic/15min /etc/periodic/hourly /var/log/nginx

# Inicia crond em background (Alpine usa crond, não o cron do Debian)
crond -b -l 8

# Gera certificado self-signed para o vhost default se não existir
if [ ! -f /etc/nginx/ssl/default.crt ]; then
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/default.key \
        -out /etc/nginx/ssl/default.crt \
        -subj "/CN=default"
fi

# Mantém nginx em foreground
exec nginx -g 'daemon off;'
