#!/bin/bash

# SIGTERM-handler this funciton will be executed when the container receives the SIGTERM signal (when stopping)
term_handler(){
	echo "Stopping...$(date)" >> /data/log.txt
        nmcli dev set wlan0 managed yes >> /data/log.txt
	#ifdown wlan0 >> /data/log.txt
	#ip link set wlan0 down >> /data/log.txt
	#ip addr flush dev wlan0 >> /data/log.txt
        echo "HERE" >> /data/log.txt
	exit 0
}

# Setup signal handlers
trap 'term_handler' EXIT HUP INT QUIT PIPE TERM

echo "Starting..."

echo "Set nmcli managed no"
nmcli dev set wlan0 managed no

CONFIG_PATH=/data/options.json

SSID=$(jq --raw-output ".ssid" $CONFIG_PATH)
WPA_PASSPHRASE=$(jq --raw-output ".wpa_passphrase" $CONFIG_PATH)
CHANNEL=$(jq --raw-output ".channel" $CONFIG_PATH)
ADDRESS=$(jq --raw-output ".address" $CONFIG_PATH)
NETMASK=$(jq --raw-output ".netmask" $CONFIG_PATH)
BROADCAST=$(jq --raw-output ".broadcast_address" $CONFIG_PATH)

# Enforces required env variables
required_vars=(SSID WPA_PASSPHRASE CHANNEL ADDRESS NETMASK BROADCAST)
for required_var in "${required_vars[@]}"; do
    if [[ -z ${!required_var} ]]; then
        error=1
        echo >&2 "Error: $required_var env variable not set."
    fi
done

if [[ -n $error ]]; then
    exit 1
fi

# Setup hostapd.conf
echo "Setup hostapd ..."
echo "ssid=$SSID"$'\n' >> /hostapd.conf
echo "wpa_passphrase=$WPA_PASSPHRASE"$'\n' >> /hostapd.conf
echo "channel=$CHANNEL"$'\n' >> /hostapd.conf

# Setup interface
echo "Setup interface ..."

#ip link set wlan0 down
#ip addr flush dev wlan0
#ip addr add ${IP_ADDRESS}/24 dev wlan0
#ip link set wlan0 up

echo "address $ADDRESS"$'\n' >> /etc/network/interfaces
echo "netmask $NETMASK"$'\n' >> /etc/network/interfaces
echo "broadcast $BROADCAST"$'\n' >> /etc/network/interfaces

ip link set wlan0 down
ip link set wlan0 up

# IP Table rules for forwarding to modem
iptables -t mangle -A POSTROUTING -j TTL --ttl-set 65
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT

echo "Starting DHCP Server"
/run-dhcp.sh &
DHCP_PID=${!}
sleep 5
if ! kill -0 ${DHCP_PID} &> /dev/null; then
  echo "ERROR: DHCP Service failed to start"
  exit 1
fi

# Add route
ip route add default via 192.168.5.1 dev eth0  metric 100 

echo "Starting HostAP daemon ..."
hostapd -d /hostapd.conf & wait ${!}

