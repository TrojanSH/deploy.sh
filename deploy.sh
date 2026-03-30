#!/bin/bash
# 🏛️ TROJANPAGE - PRE-FLIGHT CONTROLLER
# ------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
CONFIG="/root/config.json"

show_status() {
    clear
    echo -e "${BLUE}--- [ TROJANPAGE: SYSTEM STATUS ] ---${NC}"
    
    # 1. Check Telegram
    TG_TOKEN=$(grep -oP '(?<="telegramToken": ")[^"]*' $CONFIG)
    if curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe" | grep -q "\"ok\":true"; then
        echo -e "[+] Telegram API:   ${GREEN}ONLINE${NC}"
        TG_STATUS="OK"
    else
        echo -e "[+] Telegram API:   ${RED}OFFLINE / INVALID${NC}"
        TG_STATUS="ERR"
    fi

    # 2. Check Cloudflare
    CF_TOKEN=$(grep -oP '(?<="cloudflareToken": ")[^"]*' $CONFIG 2>/dev/null || grep -oP '(?<="cfToken": ")[^"]*' $CONFIG)
    if curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer $CF_TOKEN" | grep -q "\"status\":\"active\""; then
        echo -e "[+] Cloudflare API: ${GREEN}ONLINE${NC}"
        CF_STATUS="OK"
    else
        echo -e "[+] Cloudflare API: ${RED}OFFLINE / INVALID${NC}"
        CF_STATUS="ERR"
    fi

    # 3. Check MongoDB Atlas
    M_URI=$(grep -oP '(?<="mongodb": ")[^"]*' $CONFIG)
    if mongosh "$M_URI" --eval "db.adminCommand('ping')" --quiet > /dev/null 2>&1; then
        echo -e "[+] MongoDB Atlas:  ${GREEN}CONNECTED${NC}"
        DB_STATUS="OK"
    else
        echo -e "[+] MongoDB Atlas:  ${RED}DISCONNECTED${NC}"
        DB_STATUS="ERR"
    fi
    echo " ------------------------------------------------"
}

# --- MAIN LOGIC ---
while true; do
    show_status

    if [[ "$TG_STATUS" == "OK" && "$CF_STATUS" == "OK" && "$DB_STATUS" == "OK" ]]; then
        echo -e "${GREEN}[success] All systems GO. Launching YAML Interface...${NC}"
        sleep 2
        # Clean ports and start
        sudo fuser -k 80/tcp 443/tcp 2>/dev/null
        pkill -9 proxy
        cd /root/engine/dist/
        ./proxy -config /root/config.json
        exit 0
    else
        echo -e "${RED}[!] CRITICAL ERROR: Some services are unreachable.${NC}"
        echo -e "YAML Interface cannot start until credentials are fixed."
        echo ""
        echo "1) Edit Telegram Token"
        echo "2) Edit Cloudflare Token"
        echo "3) Edit MongoDB Settings"
        echo "4) Retry Connection"
        echo "5) Exit"
        read -p "Select an option: " OPT
        
        case $OPT in
            1) read -p "New TG Token: " NEW_TG; sed -i "s|\"telegramToken\": \".*\"|\"telegramToken\": \"$NEW_TG\"|g" $CONFIG ;;
            2) read -p "New CF Token: " NEW_CF; sed -i "s|\"cfToken\": \".*\"|\"cfToken\": \"$NEW_CF\"|g" $CONFIG ;;
            3) echo "Run deploy.sh again to re-configure MongoDB."; exit 1 ;;
            4) continue ;;
            5) exit 1 ;;
        esac
    fi
done
