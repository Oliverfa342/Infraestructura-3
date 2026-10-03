# Configuración completa y pruebas - Infraestructura 3

## USER-PC-1

El usuario obtiene dirección mediante DHCP en VLAN 10 y utiliza strongSwan + xl2tpd para establecer la VPN L2TP/IPsec hacia `203.0.113.165`.

Archivos principales:

- `/etc/ipsec.conf`
- `/etc/ipsec.secrets` (PSK redactada)
- `/etc/xl2tpd/xl2tpd.conf`
- `/etc/ppp/options.l2tpd.client` (password redactado)

Para conectar:

```bash
ipsec up VPN-REMOTE-SSH
echo "c fortigate" > /var/run/xl2tpd/l2tp-control
sleep 5
ip route replace 10.15.73.128/28 dev ppp0
```

Para comprobar:

```bash
ip addr show ppp0
ip route get 10.15.73.130
ssh oliver@10.15.73.130
```

Para desconectar:

```bash
echo "d fortigate" > /var/run/xl2tpd/l2tp-control
sleep 2
ipsec down VPN-REMOTE-SSH
```

## ISP / R1

El router entrega DHCP a VLAN 10, funciona como gateway `10.15.73.1/25`, realiza router-on-a-stick sobre `Fa0/0.10` y NAT overload hacia `Fa1/0` (`203.0.113.166/30`).

El running-config completo se encuentra en `running-configs/ISP_running-config.txt`.

## SW-USERS

- `Gi0/0`: access VLAN 10 hacia USER-PC-1.
- `Gi0/1`: trunk 802.1Q permitiendo VLAN 10 hacia ISP.
- PortFast edge y BPDU Guard habilitados en el puerto del usuario.

## FortiGate

La configuración del FortiGate se realizó por GUI. La versión pública incluida en el repositorio está sanitizada.

Elementos principales:

- `WAN-FG (port3)`: `203.0.113.165/30`
- `SERVER-LAN (port2)`: `10.15.73.129/28`
- VIP `WEB-HTTPS-PUBLIC`: `203.0.113.165:443 -> 10.15.73.130:443`
- VPN `VPN-REMOTE-SSH`: IKEv1, L2TP/IPsec, propuesta DES-SHA1, DH group 2
- Pool L2TP: `10.212.135.200-10.212.135.210`
- Política `WAN-to-WEB-HTTPS`
- Políticas creadas para L2TP/IPsec y acceso a la red del servidor

## WEB-SRV-1

- IP: `10.15.73.130/28`
- Gateway: `10.15.73.129`
- Nginx HTTPS en TCP/443 con certificado autofirmado
- OpenSSH en TCP/22
- Usuario de laboratorio `oliver` (password no publicado)

## Pruebas

Con VPN activa:

```bash
ip addr show ppp0
ip route get 10.15.73.130
ssh oliver@10.15.73.130
```

Sin VPN:

```bash
ssh oliver@10.15.73.130
wget --no-check-certificate -O- https://203.0.113.165
traceroute 10.15.73.130
```

El objetivo final es demostrar que HTTPS se publica por la WAN sin depender de la VPN, mientras que el acceso SSH al servidor se realiza a través del túnel Remote Access.
