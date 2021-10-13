#!/bin/bash
echo "Stopping...s6...$(date)" >> /data/log.txt
ifdown wlan0 &>> /data/log.txt
ip link set wlan0 down &>> /data/log.txt
ip addr flush dev wlan0 &>> /data/log.txt
# We need to add this because default route won't flush, but idk how
# ip route flush dev eth0 >> /data/log.txt
nmcli dev set wlan0 managed yes &>> /data/log.txt

# Clean up route
ip route del default via 192.168.5.1 dev eth0  metric 100  &>> /data/log.txt
systemctl restart wpa_supplicant &>> /data/log.tt
echo "Done stopping hostapd $(date)" >> /data/log.txt

exit 0
