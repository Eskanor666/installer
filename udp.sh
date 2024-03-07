#!/bin/bash
# udp UDP Module installer
# Creator Zahid Islam

echo -e "Updating server"
sudo apt-get update && apt-get upgrade -y
systemctl stop udp.service 1> /dev/null 2> /dev/null
echo -e "Downloading UDP Service"
wget https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 -O /usr/local/bin/udp 1> /dev/null 2> /dev/null
chmod +x /usr/local/bin/udp
mkdir /etc/udp 1> /dev/null 2> /dev/null
wget https://raw.githubusercontent.com/Eskanor666/installer/main/config.json -O /etc/udp/config.json 1> /dev/null 2> /dev/null

echo "Generating cert files:"
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=udp" -keyout "/etc/udp/udp.key" -out "/etc/udp/udp.crt"
sysctl -w net.core.rmem_max=16777216 1> /dev/null 2> /dev/null
sysctl -w net.core.wmem_max=16777216 1> /dev/null 2> /dev/null
cat <<EOF > /etc/systemd/system/udp.service
[Unit]
Description=udp VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/udp
ExecStart=/usr/local/bin/udp -config /etc/udp/config.json server
Restart=always
RestartSec=3
Environment=udp_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

echo -e "UDP Usernames/Passwords"
read -p "Enter usernames separated by commas, example: user1,user2 (Press enter for Default 'hiroki'): " input_config

if [ -n "$input_config" ]; then
    IFS=',' read -r -a config <<< "$input_config"
    if [ ${#config[@]} -eq 1 ]; then
        config+=(${config[0]})
    fi
else
    config=("zi")
fi

new_config_str="\"config\": [$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')]"

sed -i -E "s/\"config\": ?\[[[:space:]]*\"zi\"[[:space:]]*\]/${new_config_str}/g" /etc/udp/config.json

systemctl enable udp.service
systemctl start udp.service
iptables -t nat -A PREROUTING -i $(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1) -p udp --dport 20000:50000 -j DNAT --to-destination :5666
ufw allow 20000:50000/udp
ufw allow 5666/udp
rm zi.* 1> /dev/null 2> /dev/null
echo -e "Installed"
echo -e "Information"
echo -e "Obfs: hirokivpn"
echo -e "Auth: hiroki"
