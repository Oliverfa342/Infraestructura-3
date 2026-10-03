#!/bin/sh
# USER-PC-1 - Infraestructura 3
# Cliente Alpine Linux para VPN Remote Access L2TP/IPsec.
# Sustituir <VPN_PSK> y <VPN_USER_PASSWORD> solamente en un entorno privado.

# DHCP en VLAN 10
ip addr flush dev eth0
ip route flush dev eth0
ip link set eth0 up
udhcpc -i eth0

# Paquetes utilizados
apk update
apk add strongswan xl2tpd ppp openssh-client

# strongSwan
cat > /etc/ipsec.conf <<'EOC'
config setup
    uniqueids=no

conn VPN-REMOTE-SSH
    keyexchange=ikev1
    type=transport
    authby=psk
    left=%defaultroute
    leftprotoport=17/1701
    right=203.0.113.165
    rightid=%any
    rightprotoport=17/1701
    ike=des-sha1-modp1024!
    esp=des-sha1!
    ikelifetime=86400s
    lifetime=3600s
    dpdaction=clear
    dpddelay=30s
    keyingtries=3
    auto=add
EOC

cat > /etc/ipsec.secrets <<'EOC'
: PSK "<VPN_PSK>"
EOC
chmod 600 /etc/ipsec.secrets

# xl2tpd
mkdir -p /etc/xl2tpd
cat > /etc/xl2tpd/xl2tpd.conf <<'EOC'
[global]
port = 1701

[lac fortigate]
lns = 203.0.113.165
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOC

# PPP
mkdir -p /etc/ppp
cat > /etc/ppp/options.l2tpd.client <<'EOC'
ipcp-accept-local
ipcp-accept-remote
noauth
refuse-eap
noccp
nodefaultroute
mtu 1280
mru 1280
name vpnuser
password <VPN_USER_PASSWORD>
EOC

# Levantar servicios y VPN
ipsec restart
sleep 2
mkdir -p /var/run/xl2tpd
xl2tpd
sleep 2
ipsec up VPN-REMOTE-SSH
echo "c fortigate" > /var/run/xl2tpd/l2tp-control
sleep 5

# Ruta hacia la red del servidor por PPP
ip route replace 10.15.73.128/28 dev ppp0
