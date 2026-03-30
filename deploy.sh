#!/bin/bash
# 🏛️ TROJANPAGE - MASTER KEY EDITION (FIXED)
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
# THIS IS YOUR UNIVERSAL KEY
MASTER_KEY="TROJAN-PRO-2026"
HWID=$(hostnamectl | grep "Static hostname" | awk '{print $3}')-$(lscpu | grep "Model" | md5sum | cut -c1-8 | tr '[:lower:]' '[:upper:]')

# --- 3. THE 3-STRIKE SENTRY ---
ATTEMPTS=0
while [ $ATTEMPTS -lt 3 ]; do
    show_header
    echo -e "${GREEN}[+] SYSTEM HWID:${NC} $HWID"
    echo -e "${BLUE}[!] Unauthorized. Enter the Master Activation Key.${NC}"
    echo " ----------------------------------------------------------------------------------"
    
    read -p "ENTER KEY: " USER_INPUT
    # Convert input to Uppercase and remove any spaces
    CLEAN_INPUT=$(echo "$USER_INPUT" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')

    if [ "$CLEAN_INPUT" == "$MASTER_KEY" ]; then
        echo -e "${GREEN}[success] Access Granted.${NC}"
        sleep 1
        break
    else
        ATTEMPTS=$((ATTEMPTS + 1))
        echo -e "${RED}[error] Invalid Key. ($ATTEMPTS/3)${NC}"
        sleep 1
    fi

    if [ $ATTEMPTS -eq 3 ]; then
        echo -e "${RED}[critical] Self-destructing...${NC}"
        rm -- "$0"
        history -c
        exit 1
    fi
done

# --- 4. VERIFIED SETUP WIZARD ---
# [Insert your Telegram, Cloudflare, and Mongo Checks here...]

# --- 5. CREATE THE PERMANENT RUN SCRIPT ---
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
# [Header logic...]

if [ -f "$LICENSE_FILE" ]; then
    EXPIRY_DATE=$(cat "$LICENSE_FILE" | cut -d':' -f2)
    if [ "$CURRENT_DATE" -lt "$EXPIRY_DATE" ]; then
        # Launch engine...
        exit 0
    fi
fi

echo -e "${RED}[error] Unauthorized Access. Enter Master Key.${NC}"
read -p "ENTER KEY: " USER_INPUT
CLEAN_INPUT=$(echo "$USER_INPUT" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')

if [ "$CLEAN_INPUT" == "$MASTER_KEY" ]; then
    EXPIRY=$(($(date +%s) + 7776000))
    echo "$HWID:$EXPIRY" > "$LICENSE_FILE"
    sync
    echo -e "${GREEN}[success] Activated!${NC}"
    exec /root/run.sh
else
    echo -e "${RED}[error] Invalid Master Key.${NC}"
    exit 1
fi
EOF
chmod +x /root/run.sh
ln -sf /root/run.sh /usr/local/bin/Run
ln -sf /root/run.sh /usr/local/bin/run
