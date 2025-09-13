#!/bin/bash

sleepTime=2

echo "Installing iptables and iptables-persistent..."
sleep $sleepTime
apt update -y && apt install iptables -y
sleep $sleepTime

echo "Blocking invalid IP addresses for routing..."
sleep $sleepTime
# Block certain invalid IP addresses for outward routing
iptables -A OUTPUT -o eth0 -d 0.0.0.0/8 -j DROP
iptables -A OUTPUT -o eth0 -d 10.0.0.0/8 -j DROP
iptables -A OUTPUT -o eth0 -d 100.64.0.0/10 -j DROP
iptables -A OUTPUT -o eth0 -d 127.0.0.0/8 -j DROP
iptables -A OUTPUT -o eth0 -d 169.254.0.0/16 -j DROP
iptables -A OUTPUT -o eth0 -d 172.16.0.0/12 -j DROP
iptables -A OUTPUT -o eth0 -d 192.0.2.0/24 -j DROP
iptables -A OUTPUT -o eth0 -d 192.168.0.0/16 -j DROP
iptables -A OUTPUT -o eth0 -d 198.18.0.0/15 -j DROP
iptables -A OUTPUT -o eth0 -d 224.0.0.0/4 -j DROP
iptables -A OUTPUT -o eth0 -d 240.0.0.0/4 -j DROP
iptables -A OUTPUT -o eth0 -d 203.0.113.0/24 -j DROP
iptables -A OUTPUT -o eth0 -d 224.0.0.0/3 -j DROP
iptables -A OUTPUT -o eth0 -d 198.51.100.0/24 -j DROP
iptables -A OUTPUT -o eth0 -d 192.88.99.0/24 -j DROP
iptables -A OUTPUT -o eth0 -d 192.0.0.0/24 -j DROP
iptables -A OUTPUT -o eth0 -d 223.202.0.0/16 -j DROP
iptables -A OUTPUT -o eth0 -d 194.5.192.0/19 -j DROP
iptables -A OUTPUT -o eth0 -d 209.237.192.0/18 -j DROP
iptables -A OUTPUT -o eth0 -d 169.254.0.0/16 -j DROP
iptables -A OUTPUT -d 102.0.0.0/8 -j DROP
echo "Done!"
sleep $sleepTime

# Block certain botnet or untrustworthy IP addresses
echo "Blocking untrustworthy and botnet IP addresses..."
sleep $sleepTime
bash <(curl -Ls https://raw.githubusercontent.com/Adymob123/V2RaySetup/refs/heads/main/NG.sh)
echo "Done!"
sleep $sleepTime

# Block public torrent addresses to prevent flagging and blacklisting
echo "Blocking public torrents to avoid flagging and abuse..."
sleep $sleepTime
wget https://github.com/Heclalava/blockpublictorrent-iptables/raw/main/bt.sh && chmod +x bt.sh && bash bt.sh
echo "Done!"
sleep $sleepTime

echo "Loading abuse IPs loaded into ipset and blocking via iptables/ip6tables"
sleep $sleepTime
bash <(curl -Ls https://raw.githubusercontent.com/Adymob123/V2RaySetup/refs/heads/main/block-abuse-ips.sh)
echo "Done!"
sleep $sleepTime

CRON_CMD="bash <(curl -Ls https://raw.githubusercontent.com/Adymob123/V2RaySetup/refs/heads/main/block-abuse-ips.sh) >/dev/null 2>&1"
CRON_JOB="0 3 * * * $CRON_CMD"

# Check if job already exists
( crontab -l 2>/dev/null | grep -F "$CRON_CMD" ) >/dev/null || {
  ( crontab -l 2>/dev/null; echo "$CRON_JOB" ) | crontab -
  echo "✅ Installed daily cron job (03:00 UTC) to refresh abuse IPs"
}

echo "Installing X-UI..."
sleep $sleepTime
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
echo "Done!"
sleep $sleepTime
