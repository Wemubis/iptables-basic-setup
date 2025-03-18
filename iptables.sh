#!/bin/bash

echo "[+] Flushing existing iptables rules..."
sudo iptables -F
sudo iptables -X
sudo iptables -Z
sudo iptables -t nat -F

echo "[+] Setting default policies..."
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

echo "[+] Allowing established and related connections..."
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "[+] Allowing loopback interface traffic..."
sudo iptables -A INPUT -i lo -j ACCEPT

echo "[+] Allowing SSH with rate-limiting..."
sudo iptables -A INPUT -p tcp --dport <port> -m conntrack --ctstate NEW -m recent --set --name SSH
sudo iptables -A INPUT -p tcp --dport <port> -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 5 --name SSH -j DROP
sudo iptables -A INPUT -p tcp --dport <port> -m conntrack --ctstate NEW -j ACCEPT

#echo "[+] Allowing web traffic (HTTP/HTTPS)..."
#sudo iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
#sudo iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT

echo "[+] Enabling SYN flood protection..."
sudo iptables -A INPUT -p tcp --syn -m limit --limit 5/s --limit-burst 10 -j ACCEPT
sudo iptables -A INPUT -p tcp --syn -j DROP

echo "[+] Blocking excessive ping requests..."
sudo iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s --limit-burst 1 -j ACCEPT
sudo iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

echo "[+] Blocking stealth port scans..."
sudo iptables -N port-scanning
sudo iptables -A port-scanning -p tcp --tcp-flags SYN,ACK SYN,ACK -m limit --limit 1/s --limit-burst 3 -j RETURN
sudo iptables -A port-scanning -j DROP

echo "[+] Hiding services & dropping malformed packets..."
sudo iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags FIN,PSH,URG FIN,PSH,URG -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP

echo "[+] Allowing Docker traffic..."
sudo iptables -A FORWARD -i docker0 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o docker0 -j ACCEPT

echo "[+] Blocking invalid packets..."
sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

echo "[+] Logging & dropping all remaining traffic..."
sudo iptables -A INPUT -j LOG --log-prefix "iptables blocked: " --log-level 7
sudo iptables -A INPUT -j DROP

echo "[+] Saving iptables rules..."
sudo iptables-save | sudo tee /etc/iptables.rules > /dev/null

echo "[+] Making rules persistent on reboot..."
echo '#!/bin/sh' | sudo tee /etc/network/if-pre-up.d/iptables > /dev/null
echo "iptables-restore < /etc/iptables.rules" | sudo tee -a /etc/network/if-pre-up.d/iptables > /dev/null
sudo chmod +x /etc/network/if-pre-up.d/iptables

echo "[✔] iptables security rules applied and saved."

