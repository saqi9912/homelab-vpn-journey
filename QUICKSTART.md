# 🚀 Homelab VPN Quick Start Guide

**Get your homelab accessible from anywhere - the easy way!**

This is a condensed, step-by-step guide based on my week-long journey setting up VPN access to my homelab server behind CGNAT. For the full story, see [README.md](./README.md).

---

## 🎯 What This Guide Does

By the end of this guide, you'll be able to:
- ✅ Access your home server from anywhere in the world
- ✅ SSH and RDP to your homelab securely
- ✅ Route internet traffic through your home (exit node)
- ✅ Bypass CGNAT limitations

**Time Required:** 15-30 minutes  
**Cost:** Free (Tailscale personal use)  
**Difficulty:** Beginner-friendly

---

## Step 1: Check if You're Behind CGNAT

Before choosing a VPN solution, you need to know if you're behind CGNAT.

### Quick Check (2 minutes)

**Option A: Use the script**
```bash
# Download and run the CGNAT detection script
curl -o check-cgnat.sh https://raw.githubusercontent.com/yourusername/homelab-vpn/main/check-cgnat.sh
chmod +x check-cgnat.sh
./check-cgnat.sh
```

**Option B: Manual check**

1. **Get your public IP:**
   ```bash
   curl ifconfig.me
   # Note this down: _______________
   ```

2. **Check router's WAN IP:**
   - Log into your router admin panel (usually `http://192.168.0.1` or `http://192.168.1.1`)
   - Navigate to Status → WAN or Internet Status
   - Find "WAN IP Address" or "Internet IP"
   - Note this down: _______________

3. **Compare:**
   - ✅ **If they MATCH** → You have a public IP (can use traditional VPN)
   - ❌ **If they're DIFFERENT** → You're behind CGNAT (use Tailscale)

### Understanding the Result

```
Public IP:  206.84.x.x
Router WAN: 206.84.x.x
Result:     ✅ NO CGNAT - Traditional VPN works

Public IP:  206.84.x.x
Router WAN: 172.18.x.x (or 10.x.x.x, 100.64-127.x.x)
Result:     ❌ CGNAT DETECTED - Use Tailscale
```

---

## Step 2: Choose Your Solution

Based on Step 1 result:

| Your Situation | Recommended Solution | Setup Guide |
|----------------|---------------------|-------------|
| **Behind CGNAT** | Tailscale (easiest!) | Continue below ⬇️ |
| **No CGNAT + Want simple** | Tailscale | Continue below ⬇️ |
| **No CGNAT + Want to learn** | WireGuard | See [VPN.md](./docs/wireguard/VPN.md) |
| **Advanced user** | VPS Relay | See [VPN.md Appendix A](./docs/wireguard/VPN.md#appendix-a) |

**For 95% of users:** Continue with Tailscale below!

---

## Step 3: Install Tailscale on Home Server

Log into your home server (locally or via SSH on local network) and run:

### Ubuntu/Debian/Linux Mint

```bash
# Install Tailscale (one-line installer)
curl -fsSL https://tailscale.com/install.sh | sh

# Enable IP forwarding (required for exit node)
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

# Start Tailscale with exit node and subnet routing
sudo tailscale up --advertise-exit-node --advertise-routes=192.168.x.0/24

# ⚠️ Change 192.168.x.0/24 to match YOUR network:
#    - 192.168.x.0/24 if your devices use 192.168.0.x
#    - 192.168.1.0/24 if your devices use 192.168.1.x
#    - Check with: ip addr show
```

**What happens:**
- Browser window opens with authentication link
- Sign in with Google, GitHub, or Microsoft account
- Server registers to your Tailscale network

**Get your Tailscale IP:**
```bash
tailscale ip -4
# Note this down: 100.x.x.x
```

---

## Step 4: Configure Tailscale Admin Panel

Visit https://login.tailscale.com/admin/machines

### Enable Exit Node

1. Find your home server in the machines list
2. Click the **"⋯"** menu next to it
3. Select **"Edit route settings..."**
4. ✅ Check **"Use as exit node"**
5. ✅ Check **"Approve subnet routes"** (if shown)
6. Click **"Save"**

Your server is now ready to accept VPN connections!

---

## Step 5: Install Tailscale on Client Devices

### Laptop (Windows)

1. Download: https://tailscale.com/download/windows
2. Run installer
3. Click **"Connect"**
4. Sign in with the SAME account you used for the server
5. Done!

### Laptop (Mac)

1. Download: https://tailscale.com/download/mac
2. Install and open
3. Click **"Sign in"**
4. Use the SAME account
5. Done!

### Laptop (Linux)

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
# Sign in with same account
```

### Phone (iOS/Android)

1. Install "Tailscale" from App Store or Play Store
2. Open app and tap **"Sign in"**
3. Use the SAME account
4. Done!

---

## Step 6: Test Everything

### Test 1: Can you see your server?

```bash
# Ping your server (use the IP from Step 3)
ping 100.x.x.x

# Should see responses! ✅
```

### Test 2: SSH Access

```bash
# SSH to your server
ssh your-username@100.x.x.x

# Or use Tailscale's MagicDNS (server hostname)
ssh your-username@your-server-name
```

**Expected result:** You should be able to SSH in! ✅

### Test 3: RDP Access (if you have xRDP/RDP enabled)

**Windows Remote Desktop:**
1. Open "Remote Desktop Connection"
2. Computer: `100.x.x.x:3389`
3. Connect!

**Mac (Microsoft Remote Desktop):**
1. Open Microsoft Remote Desktop
2. Add PC: `100.x.x.x`
3. Connect!

**Expected result:** RDP connection should work! ✅

### Test 4: Exit Node (Browse Internet Through Home)

**Linux/Mac:**
```bash
# Enable exit node
tailscale up --exit-node=your-server-name

# Or use the Tailscale IP:
tailscale up --exit-node=100.x.x.x

# Verify (should show your HOME public IP)
curl ifconfig.me

# Disable exit node
tailscale up --exit-node=""
```

**Windows:**
1. Right-click Tailscale tray icon
2. Select **"Exit Node"** → **your-server-name**
3. Visit https://whatismyipaddress.com
   - Should show your HOME public IP! ✅

**iOS/Android:**
1. Open Tailscale app
2. Tap **"Exit Node"**
3. Select your server
4. Browse internet - you're routing through home! ✅

---

## 🎉 You're Done!

### What You Can Do Now

✅ **Access from anywhere:**
- SSH to server: `ssh user@100.x.x.x`
- RDP to server: `100.x.x.x:3389`
- Access any service running on home network

✅ **Exit node (when needed):**
- Toggle on/off to route internet through home
- Great for traveling, public WiFi, accessing region-locked content

✅ **Access other home devices:**
- Thanks to subnet routing, access any device on 192.168.x.x network
- Example: `ssh pi@192.168.0.5` (Raspberry Pi on home network)

---

## 🔧 Common Issues & Solutions

### Issue: Can't ping server

**Check:**
```bash
# On client device - check Tailscale status
tailscale status

# Should show server as "active" and "direct" or "relay"
```

**Solution:**
- Make sure both devices signed in with SAME account
- Check if firewall blocking Tailscale (allow UDP 41641)
- Wait 30 seconds and try again

---

### Issue: SSH works but RDP doesn't

**Check firewall on server:**
```bash
# Allow RDP through firewall
sudo ufw allow from 100.64.0.0/10 to any port 3389

# Or allow from entire Tailscale network
sudo ufw status
```

**Verify xRDP is running:**
```bash
sudo systemctl status xrdp
```

---

### Issue: Exit node not working

**On server - verify configuration:**
```bash
# Check if advertising exit node
tailscale status

# Should show: "Offers exit node"
```

**In admin panel:**
- Visit https://login.tailscale.com/admin/machines
- Make sure "Use as exit node" is ENABLED ✅

**On client - make sure you selected it:**
```bash
tailscale status | grep -i exit
```

---

### Issue: Slow connection

**Check connection type:**
```bash
tailscale status

# Look for "direct" vs "relay"
# Direct = peer-to-peer (fast) ✅
# Relay = through Tailscale servers (slower but works)
```

**Optimize:**
- Direct P2P works in ~70-80% of cases
- If using relay, still works but adds ~30-80ms latency
- This is normal and expected for some network types

---

## 📚 Next Steps

### Learn More

- **Full story:** [README.md](./README.md) - My journey and lessons learned
- **Architecture:** [ARCHITECTURE-DIAGRAMS.md](./ARCHITECTURE-DIAGRAMS.md) - How it all works
- **Detailed guide:** [TAILSCALE-COMPLETE-GUIDE.md](./docs/tailscale/TAILSCALE-COMPLETE-GUIDE.md) - All 7 steps explained
- **Compare solutions:** [SOLUTIONS-COMPARISON.md](./docs/SOLUTIONS-COMPARISON.md) - All VPN options

### Security Hardening

Once basic setup works, consider:

1. **Configure ACL policies** (Access Control Lists)
   - Limit which devices can access which services
   - See [TAILSCALE-COMPLETE-GUIDE.md → Step 5](./docs/tailscale/TAILSCALE-COMPLETE-GUIDE.md#step-5-security-hardening)

2. **Enable key expiry**
   - Devices automatically disconnect after X days
   - Require re-authentication

3. **Tag devices**
   - Organize by type: laptop, mobile, server
   - Create rules based on tags

4. **Set up firewall rules**
   - Only allow Tailscale IPs (100.64.0.0/10)
   - Block everything else

### Add More Services

Now that VPN works, you can:
- 🐳 Run Docker containers (Nextcloud, Jellyfin, etc.)
- 📊 Set up monitoring (Grafana, Prometheus)
- 🔒 Add more security layers (fail2ban, intrusion detection)
- 📹 Set up media server (Plex, Jellyfin)
- ☁️ Personal cloud (Nextcloud, Seafile)

---

## 🆘 Need Help?

### Check These Resources

1. **Official docs:** https://tailscale.com/kb
2. **Community forum:** https://forum.tailscale.com
3. **This repo's issues:** Open an issue if you find errors

### Debugging Commands

```bash
# Check Tailscale status
tailscale status

# Check what IP Tailscale assigned you
tailscale ip -4

# See detailed network info
tailscale netcheck

# View logs (Linux)
sudo journalctl -u tailscaled -f

# Restart Tailscale (if needed)
sudo systemctl restart tailscaled
```

---

## 📊 Quick Reference

### Essential Commands

```bash
# Start Tailscale
sudo tailscale up

# Stop Tailscale
sudo tailscale down

# Check status
tailscale status

# Enable exit node
tailscale up --exit-node=server-name

# Disable exit node
tailscale up --exit-node=""

# Get your Tailscale IP
tailscale ip -4

# Ping another device
ping 100.x.x.x
```

### Access Your Services

```bash
# SSH
ssh user@100.x.x.x
ssh user@server-name

# RDP (in RDP client)
100.x.x.x:3389
server-name:3389

# Web services
http://100.x.x.x
http://server-name
```

---

## ✅ Checklist

Use this to verify your setup:

- [ ] Checked for CGNAT (Step 1)
- [ ] Tailscale installed on server (Step 3)
- [ ] Exit node enabled in admin panel (Step 4)
- [ ] Tailscale installed on laptop/phone (Step 5)
- [ ] Can ping server (Test 1)
- [ ] SSH works (Test 2)
- [ ] RDP works if needed (Test 3)
- [ ] Exit node works (Test 4)
- [ ] Firewall configured (Security)
- [ ] Tested from different locations

**All checked? Congratulations! 🎉 You now have a working VPN setup!**

---

## 💡 Pro Tips

### 1. Use MagicDNS Names

Instead of remembering IPs like `100.x.x.x`, use device names:
```bash
ssh user@my-server
# Much easier than: ssh user@100.94.23.51
```

### 2. Set Up SSH Keys

Avoid typing passwords:
```bash
# Generate key (if you don't have one)
ssh-keygen -t ed25519

# Copy to server
ssh-copy-id user@server-name
```

### 3. Create Aliases

Make access even easier:
```bash
# Add to ~/.bashrc or ~/.zshrc
alias home-ssh='ssh user@my-server'
alias home-rdp='xfreerdp /v:my-server /u:user /h:1080 /w:1920'

# Now just type:
home-ssh
```

### 4. Mobile Access

- Add server to home screen (iOS) or widget (Android)
- One-tap to enable/disable exit node
- Quick access to SSH (using Termius app)

### 5. Backup Your Config

Save your Tailscale state:
```bash
# Get your device key (keep this safe!)
sudo tailscale status --json | grep -i authkey

# Document your setup
echo "Server IP: $(tailscale ip -4)" > ~/tailscale-backup.txt
```

---

**Happy homelabbing! 🏠🔐**

*For questions, issues, or contributions, see the main [README.md](./README.md)*

---

**Last Updated:** November 23, 2025  
**Part of:** Homelab VPN Journey Project
