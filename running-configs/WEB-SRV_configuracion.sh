#!/bin/sh
# WEB-SRV-1 - Infraestructura 3
# Alpine Linux + Nginx HTTPS + OpenSSH
# Password de laboratorio redactado.

# Direccionamiento
ip addr flush dev eth0
ip addr add 10.15.73.130/28 dev eth0
ip link set eth0 up
ip route del default 2>/dev/null
ip route add default via 10.15.73.129

# Nginx + OpenSSL + SSH
apk update
apk add nginx openssl curl openssh

mkdir -p /var/www/html /etc/nginx/ssl
cat > /var/www/html/index.html <<'EOC'
<h1>WEB-SRV - Infraestructura 3</h1>
<p>HTTPS funcionando correctamente.</p>
EOC

openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/web.key \
  -out /etc/nginx/ssl/web.crt \
  -days 365 \
  -subj "/C=DO/O=ITLA-LAB/OU=Cybersecurity/CN=web.lab"

cat > /etc/nginx/http.d/default.conf <<'EOC'
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name _;
    root /var/www/html;
    index index.html;

    ssl_certificate /etc/nginx/ssl/web.crt;
    ssl_certificate_key /etc/nginx/ssl/web.key;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOC

nginx -t
nginx

# SSH
ssh-keygen -A
adduser -D oliver
echo 'oliver:<SSH_PASSWORD>' | chpasswd
mkdir -p /run/sshd
/usr/sbin/sshd -t
/usr/sbin/sshd
