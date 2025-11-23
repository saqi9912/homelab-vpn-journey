# 🔐 Self-Hosted WireGuard VPN Setup Guide
## Secure Remote Access to Ubuntu Server via SSH/RDP from Anywhere

**Last Updated:** November 23, 2025  
**VPN Solution:** WireGuard with Docker Compose  
**Target Server:** Ubuntu with xRDP  
**Router:** Home Router  
**DNS:** DuckDNS

---

## 📋 Table of Contents

1. [Overview](#-overview)
2. [Architecture](#-architecture)
3. [Security Features](#-security-features)
4. [Prerequisites](#-prerequisites)
5. [Network Configuration](#-network-configuration)
6. [WireGuard VPN Setup](#-wireguard-vpn-setup)
7. [Security Hardening](#-security-hardening)
8. [Client Configuration](#-client-configuration)
9. [Monitoring & Logging](#-monitoring--logging)
10. [Backup & Recovery](#-backup--recovery)
11. [Troubleshooting](#-troubleshooting)
12. [Maintenance](#-maintenance)

---

## 🎯 Overview

This guide provides a **comprehensive, security-focused setup** for a self-hosted WireGuard VPN server running on Docker. This setup allows you to:

### Primary Use Cases:
1. **Remote Server Access**: Securely access your Ubuntu server (192.168.x.x) via SSH and xRDP from anywhere in the world
2. **Secure Internet Browsing**: Route your internet traffic through your home network when traveling internationally
3. **Privacy Protection**: Encrypt all traffic between your devices and home network
4. **Multi-Device Support**: Connect from Windows, macOS, iOS, and Android devices

### Why WireGuard?
- **Modern Cryptography**: Uses state-of-the-art encryption (ChaCha20, Curve25519)
- **Extremely Fast**: 4-5x faster than OpenVPN
- **Minimal Attack Surface**: Only ~4,000 lines of code (vs 100,000+ in OpenVPN)
- **Battery Efficient**: Ideal for mobile devices
- **Easy to Audit**: Simple codebase makes security audits feasible
- **Built-in Roaming**: Seamlessly switches between networks

---

## 🏗️ Architecture

### Network Topology

```
Internet
    ↓
DuckDNS (your-domain.duckdns.org)
    ↓
Home Router Router (Port 51820/UDP forwarded)
    ↓
Ubuntu Server (192.168.x.x)
    ├── WireGuard VPN Server (Docker Container)
    │   └── VPN Network: 10.13.13.0/24
    ├── xRDP Service (Port 3389)
    ├── SSH Service (Port 22)
    └── Other Services
    ↓
VPN Clients (10.13.13.2, 10.13.13.3, ...)
    ├── Windows PC
    ├── macOS Laptop
    ├── iPhone/iPad
    └── Android Phone
```

### How It Works

1. **VPN Gateway**: Your Ubuntu server acts as both the VPN gateway and the target server
2. **Dual Purpose**: 
   - When you connect to VPN, you can access the server itself (SSH/RDP)
   - All your internet traffic routes through the VPN for privacy
3. **Device Authentication**: Only devices with valid cryptographic keys can connect
4. **Encrypted Tunnel**: All traffic encrypted with ChaCha20-Poly1305

---

## 🛡️ Security Features

This setup implements multiple layers of security:

### 1. **Network Security**
- ✅ WireGuard's modern cryptographic protocols
- ✅ Minimal port exposure (only UDP 51820)
- ✅ No open SSH/RDP ports to internet
- ✅ DuckDNS for dynamic IP management
- ✅ Router-level port forwarding

### 2. **Access Control**
- ✅ Public/Private key authentication only (no passwords)
- ✅ Device-based access control (limited peer connections)
- ✅ Unique keys per device
- ✅ Easy device revocation

### 3. **System Hardening**
- ✅ Fail2ban for intrusion prevention
- ✅ UFW firewall with strict rules
- ✅ SSH key-only authentication
- ✅ Automatic security updates
- ✅ System audit logging

### 4. **Monitoring & Alerts**
- ✅ Connection logging
- ✅ Traffic monitoring
- ✅ Failed connection attempts tracking
- ✅ System health monitoring

### 5. **Data Protection**
- ✅ End-to-end encryption
- ✅ Perfect forward secrecy
- ✅ Configuration backups
- ✅ Key backup procedures

---

## ✅ Prerequisites

Before starting, ensure you have the following ready.

### 🖥️ Hardware Requirements

| Component | Requirement | Your Setup |
|-----------|-------------|------------|
| **Ubuntu Server** | Ubuntu 20.04+ (64-bit) | 192.168.x.x |
| **RAM** | Minimum 1GB, Recommended 2GB+ | Check with `free -h` |
| **Storage** | Minimum 10GB free space | Check with `df -h` |
| **Router** | Admin access required | Home Router |
| **Internet** | Public IP or DDNS support | DuckDNS configured |
| **Network** | Static local IP for server | 192.168.x.x (static) |

### 📦 Software Requirements

#### On Ubuntu Server (192.168.x.x):

**Required Software:**
- Docker Engine (20.10+)
- Docker Compose V2 (2.0+)
- xRDP (already installed)
- SSH Server (OpenSSH)

**Check if already installed:**

```bash
# Check Ubuntu version
lsb_release -a

# Check Docker version
docker --version

# Check Docker Compose version (V2 syntax)
docker compose version

# Check xRDP status
sudo systemctl status xrdp

# Check SSH status
sudo systemctl status ssh

# Check available disk space
df -h /

# Check memory
free -h

# Check if server has static IP
ip addr show | grep "192.168.x.x"
```

**Expected Output Examples:**
```
Docker version 24.0.0 or higher ✅
Docker Compose version v2.20.0 or higher ✅
xrdp.service - active (running) ✅
ssh.service - active (running) ✅
```

### 🌐 Network Requirements

#### 1. **DuckDNS Account & Domain**
- [ ] DuckDNS account created at [www.duckdns.org](https://www.duckdns.org)
- [ ] Subdomain created (e.g., `yourname.duckdns.org`)
- [ ] DuckDNS token obtained
- [ ] Current IP verified on DuckDNS

**Quick Setup:**
1. Go to https://www.duckdns.org
2. Login with Google/GitHub/Reddit account
3. Create a subdomain (e.g., `myserver.duckdns.org`)
4. Note your token (you'll need this later)

#### 2. **Router Information**
- [ ] Router admin username/password
- [ ] Router IP address (usually `192.168.0.1` or `192.168.1.1`)
- [ ] Port forwarding capability confirmed
- [ ] Current public IP address

**Find your router IP:**
```bash
# On Ubuntu server
ip route | grep default
# Look for: default via 192.168.0.1
```

#### 3. **Network Configuration**
- [ ] Server has static local IP: `192.168.x.x`
- [ ] Local network range: `192.168.0.0/24`
- [ ] Router's local IP (gateway): `192.168.0.1` (assumed)
- [ ] DNS servers noted (for troubleshooting)

**Verify network settings:**
```bash
# Check IP configuration
ip addr show

# Check gateway
ip route

# Check DNS settings
cat /etc/resolv.conf

# Test internet connectivity
ping -c 4 8.8.8.8

# Test DNS resolution
nslookup google.com
```

### 🔐 Access Requirements

#### 1. **SSH Access**
You'll need SSH access to your Ubuntu server. Test from another device on your local network:

```bash
# From your laptop/desktop on the same network
ssh your-username@192.168.x.x
```

**Security Note:** After VPN setup, you should ONLY access SSH through the VPN tunnel, never directly expose SSH to the internet.

#### 2. **Sudo Privileges**
Your user account must have sudo privileges:

```bash
# Test sudo access
sudo whoami
# Should output: root
```

### 📱 Client Device Preparation

Prepare the devices you'll use to connect to the VPN:

| Device Type | Requirement | Notes |
|-------------|-------------|-------|
| **Windows PC** | Windows 10/11 | Need admin rights to install WireGuard |
| **macOS** | macOS 10.14+ | Need admin rights to install WireGuard |
| **iOS** | iOS 12+ | Download WireGuard from App Store |
| **Android** | Android 5.0+ | Download WireGuard from Play Store |

### 📝 Information Gathering Checklist

Before proceeding, gather this information and keep it handy:

```
=== SERVER INFORMATION ===
Ubuntu Server Local IP: 192.168.x.x
Ubuntu Username: _______________
Server Hostname: _______________

=== NETWORK INFORMATION ===
Router IP (Gateway): 192.168.0.1 (verify: _______)
Network Range: 192.168.0.0/24
Public IP Address: _____________ (check at https://whatismyipaddress.com)

=== DUCKDNS INFORMATION ===
DuckDNS Domain: _______________.duckdns.org
DuckDNS Token: _________________________________

=== ROUTER ACCESS ===
Router Admin URL: http://192.168.0.1 (verify: _______)
Router Admin User: _______________
Router Admin Pass: _______________

=== CLIENT DEVICES (list devices you want to connect) ===
Device 1: _____________ (e.g., "Work Laptop - Windows")
Device 2: _____________ (e.g., "iPhone 13")
Device 3: _____________ (e.g., "MacBook Pro")
Device 4: _____________ (e.g., "Android Tablet")
(Add more as needed - each needs a unique VPN configuration)
```

### 🔍 Pre-Installation System Check

Run these commands on your Ubuntu server to verify readiness:

```bash
#!/bin/bash
# Save this as: pre-check.sh

echo "=== SYSTEM PRE-INSTALLATION CHECK ==="
echo ""

echo "1. Ubuntu Version:"
lsb_release -a | grep Description

echo ""
echo "2. Docker Status:"
if command -v docker &> /dev/null; then
    docker --version
    echo "✅ Docker is installed"
else
    echo "❌ Docker is NOT installed - needs installation"
fi

echo ""
echo "3. Docker Compose Status:"
if docker compose version &> /dev/null; then
    docker compose version
    echo "✅ Docker Compose V2 is installed"
else
    echo "❌ Docker Compose V2 is NOT installed - needs installation"
fi

echo ""
echo "4. Available Disk Space:"
df -h / | grep -v Filesystem

echo ""
echo "5. Available Memory:"
free -h | grep Mem

echo ""
echo "6. Current IP Address:"
ip addr show | grep "inet " | grep -v 127.0.0.1

echo ""
echo "7. Default Gateway:"
ip route | grep default

echo ""
echo "8. xRDP Status:"
sudo systemctl is-active xrdp || echo "❌ xRDP not running"

echo ""
echo "9. SSH Status:"
sudo systemctl is-active ssh || echo "❌ SSH not running"

echo ""
echo "10. Internet Connectivity:"
if ping -c 2 8.8.8.8 &> /dev/null; then
    echo "✅ Internet connection OK"
else
    echo "❌ No internet connection"
fi

echo ""
echo "=== CHECK COMPLETE ==="
```

**Run the check:**
```bash
# Copy the script above, then run:
nano pre-check.sh
# Paste the script, save (Ctrl+X, Y, Enter)

chmod +x pre-check.sh
./pre-check.sh
```

### 🚨 Important Security Notes BEFORE Starting

#### 1. **Backup Current Configuration**
```bash
# Create backup directory
mkdir -p ~/vpn-backup-$(date +%Y%m%d)

# Backup network configuration
sudo cp /etc/netplan/*.yaml ~/vpn-backup-$(date +%Y%m%d)/

# Backup SSH configuration
sudo cp /etc/ssh/sshd_config ~/vpn-backup-$(date +%Y%m%d)/

# Backup firewall rules (if UFW is active)
sudo ufw status > ~/vpn-backup-$(date +%Y%m%d)/ufw-rules.txt

echo "Backup created in ~/vpn-backup-$(date +%Y%m%d)/"
```

#### 2. **Ensure Physical/Local Access**
⚠️ **CRITICAL**: Make sure you have alternative access to your server (keyboard/monitor or local network access) in case something goes wrong with network configuration.

#### 3. **Document Current State**
```bash
# Document current iptables rules
sudo iptables -L -n -v > ~/vpn-backup-$(date +%Y%m%d)/iptables-before.txt

# Document current network state
ip addr > ~/vpn-backup-$(date +%Y%m%d)/ip-addr-before.txt
ip route > ~/vpn-backup-$(date +%Y%m%d)/ip-route-before.txt
```

---

## 🔧 Installing Missing Prerequisites

If the pre-check revealed missing components, install them now.

### Install Docker (if not installed)

```bash
# Update package index
sudo apt update

# Install prerequisites
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine and Docker Compose V2
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to docker group (avoid using sudo for docker commands)
sudo usermod -aG docker $USER

# Apply group changes (or logout/login)
newgrp docker

# Verify installation
docker --version
docker compose version
```

### Install/Configure xRDP (if not installed)

```bash
# Install xRDP
sudo apt update
sudo apt install -y xrdp

# Start and enable xRDP
sudo systemctl enable xrdp
sudo systemctl start xrdp

# Verify status
sudo systemctl status xrdp

# Configure xRDP to use your desktop environment
echo "startxfce4" > ~/.xsession
sudo systemctl restart xrdp
```

### Ensure SSH is Running

```bash
# Install OpenSSH server if needed
sudo apt install -y openssh-server

# Start and enable SSH
sudo systemctl enable ssh
sudo systemctl start ssh

# Verify status
sudo systemctl status ssh
```

---

**✅ Prerequisites Section Complete!**

You should now have:
- ✅ All system requirements verified
- ✅ Docker and Docker Compose V2 installed
- ✅ Network information gathered
- ✅ DuckDNS account ready
- ✅ Backup of current configuration
- ✅ Pre-installation check passed

---

## 🌐 Network Configuration

This section covers setting up your network infrastructure for secure VPN access.

---

## 🚨 CRITICAL: Check for CGNAT First!

**BEFORE** you proceed with any setup, you MUST verify that you have a routable public IP address. If you're behind CGNAT (Carrier-Grade NAT), traditional port forwarding **WILL NOT WORK**.

### What is CGNAT?

CGNAT is when your ISP places multiple customers behind a shared public IP address. This means:
- ❌ Port forwarding to your router will fail
- ❌ External devices cannot directly reach your server
- ❌ Your router's WAN IP is not the same as your actual public IP

### 🔍 Step 0: CGNAT Detection Test

Run this test **RIGHT NOW** before proceeding:

#### Option 1: Automated Script (Recommended)

```bash
# Download and run the CGNAT detection script
cd /Users/pnawale/Linux/VPN
chmod +x check-cgnat.sh
./check-cgnat.sh
```

The script will:
- ✅ Check your public IP
- ✅ Detect common CGNAT IP ranges
- ✅ Guide you through router comparison
- ✅ Tell you exactly what to do next

#### Option 2: Manual Check

```bash
# On your Ubuntu server, run:
curl ifconfig.me
```

Then compare with:
1. **Router Admin Panel** → Status/WAN → WAN IP Address
2. Write down both IPs

### Interpreting Results

#### ✅ Scenario 1: IPs Match (GOOD - No CGNAT)
```
Router WAN IP:    203.0.113.45
curl ifconfig.me: 203.0.113.45
```
**✅ You're good!** You have a routable public IP. Port forwarding will work.  
→ **Continue to Step 1 below**

#### ❌ Scenario 2: IPs Different (BAD - CGNAT Detected)
```
Router WAN IP:    100.64.15.234  (or 10.x.x.x, 172.16-31.x.x)
curl ifconfig.me: 203.0.113.45
```
**❌ You're behind CGNAT!** Port forwarding won't work.  
→ **See Alternative Solutions below**

### 🔧 Alternative Solutions for CGNAT

If you're behind CGNAT, you have several options:

#### **Option 1: Request Static Public IP from ISP** ⭐ RECOMMENDED
- **Contact your ISP** and request a static public IP or ask to be removed from CGNAT
- **Business internet plans** often include this automatically
- **Cost**: Usually $5-15/month extra
- **Pros**: Best performance, most reliable, full control
- **Cons**: Monthly cost, not all ISPs offer this

#### **Option 2: VPS + WireGuard Relay** ⭐ TECHNICAL SOLUTION
Use a cheap cloud VPS as a relay/jump server:

**How it works:**
```
Your Device → VPS (Public IP) → Your Home Server (behind CGNAT)
```

**Steps:**
1. Get a cheap VPS ($3-5/month):
   - DigitalOcean Droplet ($4/mo)
   - Vultr Cloud Compute ($3.50/mo)
   - Linode Nanode ($5/mo)
   - Oracle Cloud (FREE tier!)

2. Install WireGuard on VPS

3. Create TWO WireGuard tunnels:
   - Tunnel 1: Home Server → VPS (persistent connection from home)
   - Tunnel 2: Your Devices → VPS → Home Server

**Pros**: Works from anywhere, cheap, Oracle has free tier  
**Cons**: Extra hop adds ~20-50ms latency, requires VPS maintenance

**Tutorial**: See "APPENDIX A: CGNAT Workaround Guide" section at the end of this document

#### **Option 3: Cloudflare Tunnel** ☁️ PROFESSIONAL SOLUTION
- **Cloudflare Tunnel** (https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- **Free** with unlimited bandwidth

**How it works:**
```
Your Device → Cloudflare Edge → Tunnel → Your Home Server (behind CGNAT)
```

**Pros**: 
- Zero configuration, outbound-only connection
- Free DDoS protection and CDN
- Browser-based SSH/RDP access (no client needed!)
- Professional SSL certificates
- Perfect for web services and APIs
- Unlimited bandwidth

**Cons**: 
- Not ideal for exit node (browsing internet as if at home)
- Requires Cloudflare account
- Custom domain recommended

**Tutorial**: See "APPENDIX C: Cloudflare Tunnel Complete Setup Guide"

#### **Option 4: Tailscale/ZeroTier** 🌐 EASIEST
- **Tailscale** (https://tailscale.com) - Free for personal use
- **ZeroTier** (https://zerotier.com) - Free for up to 25 devices

**Pros**: 
- Zero configuration
- NAT traversal handles CGNAT automatically
- Works anywhere
- Free for personal use
- Exit node feature (browse as if at home)

**Cons**: 
- Relies on third-party service
- Less control
- May have bandwidth limits on free tier

**Tutorial**: See "APPENDIX B: Tailscale Complete Setup Guide"

#### **Option 5: IPv6** 🌐 IF AVAILABLE
If your ISP provides IPv6:
1. Enable IPv6 on router
2. Use IPv6 address for VPN
3. Configure WireGuard to listen on IPv6

**Pros**: No CGNAT on IPv6, usually  
**Cons**: Not all networks support IPv6, harder to remember addresses

---

### 📊 Quick Decision Matrix

| Your Situation | Best Solution |
|----------------|---------------|
| Need 100% control, willing to pay ISP | Option 1: Static IP ($5-15/mo) |
| Tech-savvy, want self-hosted VPN | Option 2: VPS Relay (FREE-$5/mo) |
| Hosting web services, need DDoS protection | Option 3: Cloudflare Tunnel (FREE) |
| Want simplest setup + exit node | Option 4: Tailscale (FREE) |
| ISP provides IPv6 | Option 5: IPv6 (FREE) |

### 🎯 Detailed Feature Comparison

| Feature | Static IP | VPS Relay | Cloudflare | Tailscale | IPv6 |
|---------|-----------|-----------|------------|-----------|------|
| **Setup Time** | 1 day | 30 min | 10 min | 5 min | 15 min |
| **Monthly Cost** | $5-15 | $0-5 | FREE | FREE | FREE |
| **SSH/RDP** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Web Services** | ✅ | ✅ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ✅ |
| **Exit Node** | ✅ | ✅ | ❌ | ⭐⭐⭐⭐⭐ | ✅ |
| **DDoS Protection** | ❌ | ❌ | ⭐⭐⭐⭐⭐ | ❌ | ❌ |
| **No Client Needed** | ❌ | ❌ | ⭐⭐⭐⭐⭐ | ❌ | ❌ |
| **Learning Value** | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Full Control** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

### 💡 Recommendations by Use Case

**Just need SSH/RDP access:**
→ **Tailscale** (5 min setup, works everywhere)

**Hosting websites or APIs:**
→ **Cloudflare Tunnel** (free CDN, DDoS protection, SSL)

**Want to browse internet as if at home:**
→ **Tailscale** with exit node (toggle on/off easily)

**Want to learn VPN internals:**
→ **VPS Relay** (hands-on WireGuard experience)

**Need best performance, willing to pay:**
→ **Static IP from ISP** (no added latency)

**Want both web hosting AND exit node:**
→ **Cloudflare + Tailscale** (run both together! 🎉)

---

### ⚠️ STOP HERE if CGNAT Detected

If you confirmed CGNAT, **DO NOT continue** with the standard setup below. Choose one of the alternative solutions above first.

If you have a **routable public IP** (IPs matched), continue to Step 1 below! 👇

---

### Overview of Network Configuration Steps

1. **Set Static IP** for Ubuntu server (192.168.x.x)
2. **Configure DuckDNS** for dynamic DNS updates
3. **Configure Home Router** router port forwarding
4. **Test network connectivity**
5. **Document your public IP**

---

## 📍 Step 1: Configure Static IP on Ubuntu Server

Your server MUST have a static IP so port forwarding always works.

### Method 1: Using Netplan (Ubuntu 18.04+)

**1. Identify your network interface:**
```bash
ip link show
# Look for interface like: eth0, enp0s3, ens33, etc.
# Ignore 'lo' (loopback)
```

**2. Check current configuration:**
```bash
ls /etc/netplan/
# You'll see a file like: 01-netcfg.yaml or 50-cloud-init.yaml
```

**3. Backup existing configuration:**
```bash
sudo cp /etc/netplan/*.yaml ~/vpn-backup-$(date +%Y%m%d)/
```

**4. Edit netplan configuration:**
```bash
# Replace with your actual filename
sudo nano /etc/netplan/01-netcfg.yaml
```

**5. Configure static IP (example configuration):**

```yaml
# /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:  # REPLACE with your interface name (from step 1)
      dhcp4: no
      addresses:
        - 192.168.x.x/24  # Your static IP
      routes:
        - to: default
          via: 192.168.0.1  # Your router's IP (gateway)
      nameservers:
        addresses:
          - 8.8.8.8      # Google DNS (primary)
          - 8.8.4.4      # Google DNS (secondary)
          - 192.168.0.1  # Your router (optional)
```

**6. Apply the configuration:**
```bash
# Test configuration (doesn't apply, just validates)
sudo netplan try

# If validation passes, apply:
sudo netplan apply

# Verify new IP
ip addr show

# Test connectivity
ping -c 4 8.8.8.8
ping -c 4 google.com
```

### Method 2: Reserve IP in Router (Alternative)

If you prefer, configure DHCP reservation in your home router instead:
1. Router admin → DHCP → Address Reservation
2. Add reservation for server's MAC address → 192.168.x.x
3. Reboot server to get reserved IP

---

## 🦆 Step 2: Configure DuckDNS Dynamic DNS

DuckDNS will keep your domain pointing to your current public IP address.

### 2.1: Create DuckDNS Account and Domain

**1. Visit DuckDNS:**
```
https://www.duckdns.org
```

**2. Login with your preferred account:**
- Google, GitHub, Reddit, or Twitter

**3. Create a subdomain:**
- Enter your desired subdomain (e.g., `myserver`)
- Full domain will be: `myserver.duckdns.org`
- Click "add domain"

**4. Note your token:**
- On the main page, you'll see your token (a long string)
- **SAVE THIS TOKEN** - you'll need it for automatic updates

**5. Verify current IP:**
- DuckDNS will show your current public IP
- Confirm it matches your actual public IP (check at https://whatismyipaddress.com)

### 2.2: Set Up Automatic DuckDNS IP Updates on Ubuntu

**Create update script:**

```bash
# Create DuckDNS directory
mkdir -p ~/duckdns
cd ~/duckdns

# Create update script
nano duck.sh
```

**Add the following content:**
```bash
#!/bin/bash
# DuckDNS IP Update Script

# REPLACE with your actual values:
DOMAIN="myserver"  # Your subdomain (without .duckdns.org)
TOKEN="your-duckdns-token-here"  # Your DuckDNS token

# Update DuckDNS
echo url="https://www.duckdns.org/update?domains=${DOMAIN}&token=${TOKEN}&ip=" | curl -k -o ~/duckdns/duck.log -K -

# Log the update
echo "[$(date)] DuckDNS update completed" >> ~/duckdns/duck.log
```

**Make it executable:**
```bash
chmod +x ~/duckdns/duck.sh
```

**Test the script:**
```bash
~/duckdns/duck.sh

# Check the log
cat ~/duckdns/duck.log
# Should show: OK
```

### 2.3: Set Up Automatic Updates with Cron

**Edit crontab:**
```bash
crontab -e
# If asked, choose nano (option 1)
```

**Add this line at the end:**
```bash
# Update DuckDNS every 5 minutes
*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1
```

**Save and exit** (Ctrl+X, Y, Enter)

**Verify cron job:**
```bash
crontab -l
# Should show your new cron entry

# Check if cron service is running
sudo systemctl status cron
```

**Test by waiting 5 minutes and checking log:**
```bash
# Wait 5 minutes, then:
tail ~/duckdns/duck.log
# Should show recent update entries
```

### 2.4: Verify DuckDNS Resolution

**Test DNS resolution:**
```bash
# Replace with your actual domain
nslookup myserver.duckdns.org

# Should return your public IP address

# Alternative test
dig myserver.duckdns.org +short
# Should show your public IP
```

---

## 🔀 Step 3: Configure Home Router Router Port Forwarding

You need to forward UDP port 51820 to your Ubuntu server (192.168.x.x).

### 3.1: Access Router Admin Panel

**1. Open browser and navigate to router:**
```
http://192.168.0.1
```
Or try: `http://tplinkwifi.net`

**2. Login credentials:**
- Default Username: `admin`
- Default Password: `admin` (or check router label)
- If changed, use your custom credentials

### 3.2: Configure Port Forwarding

**Step-by-step for Home Router:**

**1. Navigate to Port Forwarding:**
```
Advanced → NAT Forwarding → Virtual Servers
```

**2. Click "Add" or "Add New"**

**3. Enter the following configuration:**

| Field | Value | Description |
|-------|-------|-------------|
| **Service Type** | Custom | Or "Other" if available |
| **Service Name** | WireGuard-VPN | Descriptive name |
| **External Port** | 51820 | Port from internet |
| **Internal IP** | 192.168.x.x | Your Ubuntu server |
| **Internal Port** | 51820 | Port on your server |
| **Protocol** | UDP | ⚠️ IMPORTANT: UDP, not TCP |
| **Status** | Enabled | Enable the rule |

**4. Save the configuration**

**5. Verify the rule appears in the list**

### 3.3: Home Router Specific Screenshots Guide

Since I can't show actual screenshots, here's what you'll see:

**Login Screen:**
- Router logo at top
- Username and Password fields
- "Login" button

**Main Dashboard:**
- Top menu: Basic, Advanced, System Tools
- Click **"Advanced"** tab

**Advanced Menu (left sidebar):**
- Network
- Wireless
- USB Settings
- **NAT Forwarding** ← Click this
- Security
- etc.

**NAT Forwarding submenu:**
- Port Triggering
- **Virtual Servers** ← Click this
- DMZ
- UPnP

**Virtual Servers page:**
- Table showing existing port forwards
- **"Add"** button at bottom
- Form fields as described in table above

### 3.4: Additional Router Security Settings

While in router settings, configure these security options:

**1. Disable Remote Management:**
```
System Tools → Administration → Remote Management
→ Set to "Disabled"
```
**Why:** Prevents external access to router admin panel

**2. Change Default Router Password:**
```
System Tools → Administration → Account Management
→ Change admin password to strong password
```
**Why:** Default credentials are publicly known

**3. Disable WPS (if not using):**
```
Wireless → WPS
→ Disable WPS
```
**Why:** WPS has known security vulnerabilities

**4. Enable Firewall:**
```
Security → Firewall
→ Enable SPI Firewall
```
**Why:** Adds stateful packet inspection

**5. Update Router Firmware:**
```
System Tools → Firmware Upgrade
→ Check for updates
```
**Why:** Security patches and improvements

---

## 🔥 Step 4: Configure Initial Firewall Rules

Before starting WireGuard, set up basic firewall rules.

### 4.1: Install and Configure UFW (Uncomplicated Firewall)

**1. Install UFW:**
```bash
sudo apt update
sudo apt install -y ufw
```

**2. Configure default policies:**
```bash
# Default: deny all incoming, allow all outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

**3. Allow essential services:**
```bash
# Allow SSH from local network ONLY (for safety)
# IMPORTANT: This allows SSH only from local network
sudo ufw allow from 192.168.0.0/24 to any port 22 proto tcp comment 'SSH from local network'

# Allow xRDP from local network ONLY (we'll access via VPN)
sudo ufw allow from 192.168.0.0/24 to any port 3389 proto tcp comment 'xRDP from local network'

# Allow WireGuard VPN (this is exposed to internet)
sudo ufw allow 51820/udp comment 'WireGuard VPN'

# Allow traffic from WireGuard network (we'll create this network as 10.13.13.0/24)
sudo ufw allow from 10.13.13.0/24 comment 'WireGuard tunnel network'
```

**4. Enable UFW:**
```bash
# ⚠️ IMPORTANT: Make sure SSH rule is added before enabling!
sudo ufw enable

# Confirm "yes" when prompted
```

**5. Verify firewall rules:**
```bash
sudo ufw status verbose
```

**Expected output:**
```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    192.168.0.0/24    # SSH from local network
3389/tcp                   ALLOW IN    192.168.0.0/24    # xRDP from local network
51820/udp                  ALLOW IN    Anywhere          # WireGuard VPN
Anywhere                   ALLOW IN    10.13.13.0/24     # WireGuard tunnel network
```

### 4.2: Enable IP Forwarding (Required for VPN)

**1. Enable IP forwarding permanently:**
```bash
# Edit sysctl configuration
sudo nano /etc/sysctl.conf
```

**2. Uncomment or add these lines:**
```bash
# Uncomment the following line (remove the #):
net.ipv4.ip_forward=1

# For IPv6 support (optional):
net.ipv6.conf.all.forwarding=1
```

**3. Apply the changes:**
```bash
sudo sysctl -p

# Verify it's enabled (should return 1)
cat /proc/sys/net/ipv4/ip_forward
```

**4. Configure NAT for WireGuard:**

We'll add this later in the WireGuard setup, but note that UFW needs to allow routing:

```bash
# Edit UFW before rules
sudo nano /etc/ufw/before.rules
```

**Add this at the TOP of the file (after the header comments, before *filter):**
```bash
# START WireGuard rules
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Forward traffic from WireGuard to internet
-A POSTROUTING -s 10.13.13.0/24 -o eth0 -j MASQUERADE
COMMIT
# END WireGuard rules
```

**⚠️ IMPORTANT:** Replace `eth0` with your actual internet interface name (from `ip link show`)

**5. Allow forwarding in UFW:**
```bash
# Edit UFW sysctl
sudo nano /etc/ufw/sysctl.conf
```

**Uncomment or add:**
```bash
net/ipv4/ip_forward=1
net/ipv6/conf/default/forwarding=1
net/ipv6/conf/all/forwarding=1
```

**6. Restart UFW:**
```bash
sudo ufw disable
sudo ufw enable
sudo systemctl restart ufw
```

---

## 🧪 Step 5: Test Network Configuration

Before proceeding to WireGuard setup, verify everything works.

### 5.1: Local Network Tests

```bash
# 1. Verify static IP
ip addr show | grep "192.168.x.x"
# Should show: inet 192.168.x.x/24

# 2. Test gateway connectivity
ping -c 4 192.168.0.1
# Should get responses

# 3. Test internet connectivity
ping -c 4 8.8.8.8
# Should get responses

# 4. Test DNS resolution
nslookup google.com
# Should resolve to IP addresses

# 5. Test DuckDNS resolution
nslookup myserver.duckdns.org  # Replace with your domain
# Should show your public IP
```

### 5.2: Check Open Ports

```bash
# Check what's listening
sudo ss -tulpn

# Should see:
# - ssh on port 22
# - xrdp on port 3389
# - No port 51820 yet (we haven't started WireGuard)
```

### 5.3: Verify Firewall Rules

```bash
# Check UFW status
sudo ufw status numbered

# Check iptables (underlying rules)
sudo iptables -L -n -v

# Check NAT rules
sudo iptables -t nat -L -n -v
```

### 5.4: Test from External Network (Optional)

If you have a mobile device with cellular data (not on WiFi):

**Test 1: Verify DuckDNS works from outside**
```bash
# From mobile browser or another network:
# Open: https://www.duckdns.org
# Your domain should show correct public IP
```

**Test 2: Port checker (before WireGuard is running)**
```
# Visit: https://www.yougetsignal.com/tools/open-ports/
# Enter your DuckDNS domain: myserver.duckdns.org
# Enter port: 51820
# Should show: CLOSED (this is expected - WireGuard not running yet)
```

### 5.5: Document Your Configuration

Create a configuration file for reference:

```bash
cat > ~/vpn-config-info.txt << 'EOF'
=== VPN NETWORK CONFIGURATION ===
Date: $(date)

SERVER INFORMATION:
- Local IP: 192.168.x.x
- Gateway: 192.168.0.1
- Network Interface: eth0 (verify with: ip link show)
- Public IP: (check at: curl ifconfig.me)

DUCKDNS:
- Domain: myserver.duckdns.org
- Token: [SAVED SECURELY]
- Auto-update: Enabled via cron (every 5 min)

ROUTER:
- Model: Home Router
- Admin IP: 192.168.0.1
- Port Forward: UDP 51820 → 192.168.x.x:51820

FIREWALL:
- UFW: Enabled
- SSH: Allowed from local network only (192.168.0.0/24)
- xRDP: Allowed from local network only (192.168.0.0/24)
- WireGuard: Port 51820/UDP allowed from anywhere
- IP Forwarding: Enabled

VPN NETWORK (WireGuard):
- VPN Subnet: 10.13.13.0/24
- Server VPN IP: 10.13.13.1
- Client IPs: 10.13.13.2, 10.13.13.3, etc.
EOF

# View the file
cat ~/vpn-config-info.txt
```

---

**✅ Network Configuration Complete!**

You should now have:
- ✅ Static IP configured (192.168.x.x)
- ✅ DuckDNS automatic updates working
- ✅ Router port forwarding configured (UDP 51820)
- ✅ Firewall rules in place
- ✅ IP forwarding enabled
- ✅ Network connectivity verified

**SECURITY CHECKPOINT:**
- ✅ SSH accessible only from local network
- ✅ xRDP accessible only from local network
- ✅ Only VPN port (51820) exposed to internet
- ✅ Router admin panel not accessible from internet
- ✅ Firewall enabled and configured

---

## 🔐 WireGuard VPN Docker Setup

Now we'll deploy WireGuard VPN using Docker Compose with **wg-easy**, a web-based management interface.

### Why wg-easy?

- **Web UI**: Easy client management through browser
- **QR Codes**: Instant mobile device setup
- **Security**: Built on official WireGuard
- **Ease of Use**: No manual configuration files
- **Device Management**: Easy to add/remove devices

---

## 📁 Step 1: Create Project Directory Structure

**1. Create WireGuard project directory:**
```bash
# Create directory structure
mkdir -p ~/wireguard-vpn
cd ~/wireguard-vpn

# Create subdirectories for organization
mkdir -p config
mkdir -p scripts
mkdir -p logs
mkdir -p backups

# Verify structure
tree ~/wireguard-vpn
# Or if tree not installed:
ls -la ~/wireguard-vpn/
```

**2. Set proper permissions:**
```bash
# Set ownership
sudo chown -R $USER:$USER ~/wireguard-vpn

# Set permissions (secure but accessible)
chmod 755 ~/wireguard-vpn
chmod 700 ~/wireguard-vpn/config
```

---

## 📝 Step 2: Create Docker Compose Configuration

**1. Create the docker-compose.yml file:**
```bash
cd ~/wireguard-vpn
nano docker-compose.yml
```

**2. Add the following configuration:**

```yaml
# WireGuard VPN with wg-easy Web UI
# docker-compose.yml
version: "3.8"

services:
  wg-easy:
    image: ghcr.io/wg-easy/wg-easy:latest
    container_name: wg-easy
    
    # Security: Run with limited capabilities
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    
    # Security: Drop all other capabilities
    cap_drop:
      - ALL
    
    environment:
      # REQUIRED: Change this to a strong password
      # This protects the web UI
      - PASSWORD=YourSecurePasswordHere123!
      
      # Your WireGuard endpoint (DuckDNS domain)
      # REPLACE with your actual DuckDNS domain
      - WG_HOST=myserver.duckdns.org
      
      # WireGuard listening port
      - WG_PORT=51820
      
      # Default DNS for VPN clients (using Cloudflare + Google)
      - WG_DEFAULT_DNS=1.1.1.1,8.8.8.8
      
      # VPN subnet (10.13.13.x)
      - WG_DEFAULT_ADDRESS=10.13.13.x
      
      # Maximum transmission unit (leave default)
      - WG_MTU=1420
      
      # Persistent keepalive (helps with NAT)
      - WG_PERSISTENT_KEEPALIVE=25
      
      # Allowed IPs - IMPORTANT FOR ROUTING
      # 0.0.0.0/0 = Route ALL traffic through VPN (for internet access when traveling)
      # Use 192.168.0.0/24 to only access local network
      - WG_ALLOWED_IPS=0.0.0.0/0
      
      # Pre/Post up/down scripts (optional)
      # - WG_PRE_UP=echo "WireGuard Starting"
      # - WG_POST_UP=echo "WireGuard Started"
      # - WG_PRE_DOWN=echo "WireGuard Stopping" 
      # - WG_POST_DOWN=echo "WireGuard Stopped"
      
      # Web UI settings
      - UI_TRAFFIC_STATS=true
      - UI_CHART_TYPE=0  # 0=disabled, 1=linear, 2=area
      
      # Language (optional)
      - LANG=en
      
      # Timezone
      - TZ=America/New_York  # REPLACE with your timezone
    
    volumes:
      # Persistent storage for WireGuard configuration
      - ./config:/etc/wireguard
      
      # Persistent storage for wg-easy data
      - ./data:/app/data
    
    ports:
      # WireGuard VPN port (UDP)
      - "51820:51820/udp"
      
      # Web UI port (accessible from local network only)
      # We'll access this at http://192.168.x.x:51821
      - "51821:51821/tcp"
    
    restart: unless-stopped
    
    # Security: Read-only root filesystem (commented for compatibility)
    # read_only: true
    
    # Logging configuration
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    
    # Security: Use specific sysctls
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
    
    # Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:51821"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

# Optional: Create a custom network (commented - uses default)
# networks:
#   wireguard_network:
#     driver: bridge
```

**3. Save the file** (Ctrl+X, Y, Enter)

---

## 🔧 Step 3: Customize Configuration

**IMPORTANT: You MUST customize these values before starting!**

**1. Edit the docker-compose.yml:**
```bash
nano docker-compose.yml
```

**2. Update these critical values:**

| Variable | What to Change | Example |
|----------|---------------|---------|
| `PASSWORD` | Strong password for Web UI | `MyStr0ng!VPN#Pass2024` |
| `WG_HOST` | Your DuckDNS domain | `myserver.duckdns.org` |
| `TZ` | Your timezone | `America/Los_Angeles` |

**3. Find your timezone:**
```bash
# List available timezones
timedatectl list-timezones | grep -i america
# Or for your current timezone:
timedatectl
```

**4. Password Security Best Practices:**
```bash
# Generate a strong random password (optional)
openssl rand -base64 24
# Use this as your Web UI password
```

**5. Understanding WG_ALLOWED_IPS:**

This is CRITICAL for your use case:

```yaml
# Option 1: Route ALL traffic through VPN (recommended for you)
# Use this to access internet through your home connection when traveling
- WG_ALLOWED_IPS=0.0.0.0/0

# Option 2: Only access local network and server
# Use this if you only want to access your server, not route internet
- WG_ALLOWED_IPS=192.168.0.0/24,10.13.13.0/24

# Option 3: Split tunnel - access specific networks
# You can combine multiple networks
- WG_ALLOWED_IPS=192.168.0.0/24,10.13.13.0/24,8.8.8.8/32
```

**For your needs (internet access when traveling), use Option 1: `0.0.0.0/0`**

---

## 🚀 Step 4: Deploy WireGuard VPN

**1. Verify your configuration:**
```bash
cd ~/wireguard-vpn

# Check docker-compose.yml syntax
docker compose config

# Should display your configuration without errors
```

**2. Pull the Docker image:**
```bash
# Download the wg-easy image
docker compose pull

# This may take a few minutes
```

**3. Start WireGuard VPN:**
```bash
# Start in detached mode (background)
docker compose up -d

# Watch the startup logs
docker compose logs -f wg-easy
```

**4. Expected output:**
```
Creating wg-easy ... done
Attaching to wg-easy
wg-easy    | WireGuard Easy - Web UI for WireGuard
wg-easy    | ====================================
wg-easy    | Server started on http://0.0.0.0:51821
wg-easy    | WireGuard is up and running!
```

**5. Verify container is running:**
```bash
# Check container status
docker compose ps

# Should show:
# NAME      STATE     PORTS
# wg-easy   running   51820/udp, 51821/tcp

# Check detailed status
docker ps
```

**6. Check WireGuard interface:**
```bash
# List network interfaces
ip addr show

# You should see a new 'wg0' interface:
# wg0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420
#     inet 10.13.13.1/24 scope global wg0
```

**7. Verify WireGuard is listening:**
```bash
# Check listening ports
sudo ss -ulnp | grep 51820

# Should show:
# UNCONN 0  0  0.0.0.0:51820  0.0.0.0:*  users:(("wg-easy",pid=XXXX,fd=X))
```

---

## 🌐 Step 5: Access Web UI

**1. From a device on your local network:**

Open browser and navigate to:
```
http://192.168.x.x:51821
```

**2. Login with your password:**
- Enter the password you set in `docker-compose.yml`
- Click "Login"

**3. You should see the wg-easy dashboard:**
- Clean interface with "Add Client" button
- Empty client list (we'll add clients next)
- Server statistics

### 🔒 IMPORTANT SECURITY NOTES:

⚠️ **The Web UI (port 51821) is currently accessible from your local network only!**

**DO NOT expose port 51821 to the internet!** 

To access the Web UI remotely:
1. First connect to VPN
2. Then access http://10.13.13.1:51821 (server's VPN IP)

---

## 👤 Step 6: Create VPN Client Configurations

Now let's create configurations for your devices.

### 6.1: Add First Client (Windows PC Example)

**1. In the Web UI, click "Add Client"**

**2. Enter client details:**
- **Client Name**: `Windows-Laptop` (descriptive name)
- Click "Create"

**3. Client configuration is generated automatically!**

**4. Download or view configuration:**
- Click "Download" to get .conf file
- Click "QR Code" to show QR for mobile devices
- Click "Show" to see configuration text

### 6.2: Understanding Client Configuration

When you create a client, wg-easy generates something like:

```ini
[Interface]
PrivateKey = <auto-generated>
Address = 10.13.13.2/32
DNS = 1.1.1.1,8.8.8.8

[Peer]
PublicKey = <server-public-key>
PresharedKey = <auto-generated>
Endpoint = myserver.duckdns.org:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

**Key components:**
- **Address**: Client's VPN IP (auto-increments: .2, .3, .4, etc.)
- **Endpoint**: Your DuckDNS domain and port
- **AllowedIPs**: What traffic goes through VPN (0.0.0.0/0 = everything)
- **PersistentKeepalive**: Keeps connection alive through NAT

### 6.3: Create Clients for All Your Devices

Create a client for each device you want to connect:

**Examples:**
```
Client Name: Windows-Work-Laptop (10.13.13.2)
Client Name: MacBook-Pro (10.13.13.3)
Client Name: iPhone-13 (10.13.13.4)
Client Name: Android-Tablet (10.13.13.5)
Client Name: Windows-Desktop (10.13.13.6)
```

**Best Practices:**
- Use descriptive names
- Document which device has which IP
- Don't create more clients than you need (security)
- Each device should have its own unique configuration

### 6.4: Recommended Number of Clients

For security (limiting VPN access by device), create ONLY clients for:
- ✅ Devices you personally own and control
- ✅ Devices you regularly use for remote access
- ❌ Don't create "guest" or "shared" clients
- ❌ Don't share client configs between devices

---

## 📋 Step 7: Document Your Setup

Create a reference document:

```bash
cd ~/wireguard-vpn
nano CLIENT-LIST.md
```

**Add your client information:**
```markdown
# WireGuard VPN Clients

## Server Information
- Server VPN IP: 10.13.13.1
- External Access: myserver.duckdns.org:51820
- Web UI: http://192.168.x.x:51821 (local only)
- Web UI Password: [STORED SECURELY]

## Client Configurations

### Client 1: Windows-Work-Laptop
- VPN IP: 10.13.13.2
- Created: 2025-11-06
- Config File: Windows-Work-Laptop.conf
- Status: Active

### Client 2: MacBook-Pro
- VPN IP: 10.13.13.3
- Created: 2025-11-06
- Config File: MacBook-Pro.conf
- Status: Active

### Client 3: iPhone-13
- VPN IP: 10.13.13.4
- Created: 2025-11-06
- Config: QR Code imported
- Status: Active

### Client 4: Android-Tablet
- VPN IP: 10.13.13.5
- Created: 2025-11-06
- Config: QR Code imported
- Status: Active

## Notes
- Maximum clients: 10 (adjust based on security needs)
- Each device has unique keys
- To revoke access: Delete client from Web UI
```

---

## 🔍 Step 8: Verify WireGuard Server Status

**1. Check container logs:**
```bash
cd ~/wireguard-vpn

# View real-time logs
docker compose logs -f wg-easy

# View last 50 lines
docker compose logs --tail 50 wg-easy
```

**2. Check WireGuard status:**
```bash
# Execute command inside container
docker compose exec wg-easy wg show

# Should display:
# interface: wg0
#   public key: <server-public-key>
#   private key: (hidden)
#   listening port: 51820
#
# (Peers will show here when clients connect)
```

**3. Monitor in real-time:**
```bash
# Watch WireGuard status (updates every 2 seconds)
watch -n 2 'docker compose exec wg-easy wg show'

# Press Ctrl+C to exit
```

**4. Check server resource usage:**
```bash
# Container resource usage
docker stats wg-easy

# Press Ctrl+C to exit
```

---

## 🧪 Step 9: Test VPN Server (Before Client Setup)

**1. Test from external network:**

Use your mobile phone's cellular data (not WiFi):

**Option A: Online Port Checker**
```
Visit: https://www.yougetsignal.com/tools/open-ports/
Domain: myserver.duckdns.org
Port: 51820
Protocol: UDP (note: some checkers only test TCP)
```

**Option B: Command-line test (from another server/VPS)**
```bash
# If you have access to another Linux server
nc -vzu myserver.duckdns.org 51820
```

**2. Test DuckDNS resolution from outside:**
```bash
# From mobile or another network
nslookup myserver.duckdns.org

# Should return your public IP
```

**3. Check firewall logs:**
```bash
# Check if packets are reaching the server
sudo tail -f /var/log/ufw.log

# Should see incoming connections on port 51820
```

---

## 🔄 Step 10: Managing WireGuard VPN

### Starting and Stopping

```bash
cd ~/wireguard-vpn

# Stop VPN
docker compose down

# Start VPN
docker compose up -d

# Restart VPN
docker compose restart

# View status
docker compose ps
```

### Updating wg-easy

```bash
cd ~/wireguard-vpn

# Pull latest image
docker compose pull

# Recreate container with new image
docker compose up -d

# Remove old images
docker image prune -f
```

### Viewing Logs

```bash
# Real-time logs
docker compose logs -f

# Last 100 lines
docker compose logs --tail 100

# Logs for last hour
docker compose logs --since 1h

# Save logs to file
docker compose logs > ~/wireguard-vpn/logs/vpn-logs-$(date +%Y%m%d).log
```

### Adding/Removing Clients via Web UI

**Add Client:**
1. Access Web UI (http://192.168.x.x:51821)
2. Click "Add Client"
3. Enter name → Create
4. Download or scan QR code

**Remove Client:**
1. Access Web UI
2. Find client in list
3. Click trash icon
4. Confirm deletion
5. Client immediately loses access

---

## 🛡️ Step 11: WireGuard Security Configuration

### Enable Additional Security Features

**1. Add rate limiting (prevent brute force):**

Edit docker-compose.yml and add:
```yaml
    environment:
      # ... existing environment variables ...
      
      # Rate limiting
      - WG_RATE_LIMIT=100  # Max 100 attempts per minute
```

**2. Restrict Web UI access to local network only:**

Update UFW rules:
```bash
# Remove any existing rule for 51821
sudo ufw delete allow 51821

# Add rule for local network only
sudo ufw allow from 192.168.0.0/24 to any port 51821 proto tcp comment 'WireGuard Web UI - local only'

# Reload firewall
sudo ufw reload
```

**3. Enable container auto-updates (optional but recommended):**

Install Watchtower for automatic container updates:
```bash
# Add to docker-compose.yml or run separately:
docker run -d \
  --name watchtower \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --cleanup \
  --interval 86400 \
  wg-easy
```

---

**✅ WireGuard VPN Setup Complete!**

You should now have:
- ✅ WireGuard VPN server running in Docker
- ✅ wg-easy Web UI accessible locally
- ✅ Client configurations ready to deploy
- ✅ Server listening on port 51820 (UDP)
- ✅ VPN network (10.13.13.0/24) configured
- ✅ All traffic routing enabled (0.0.0.0/0)

**SECURITY CHECKPOINT:**
- ✅ Web UI password protected
- ✅ Web UI accessible only from local network
- ✅ Each client has unique cryptographic keys
- ✅ Container running with limited capabilities
- ✅ Automatic keepalive configured
- ✅ Logging enabled

**Next Steps:**
- Configure clients (Windows, Mac, iOS, Android)
- Test VPN connections
- Implement additional security hardening

---

## 🛡️ Security Hardening

This section implements multiple layers of security to protect your VPN server and Ubuntu system.

### Security Hardening Overview

We'll implement:
1. **Fail2ban** - Intrusion prevention system
2. **SSH Hardening** - Secure SSH configuration
3. **Advanced Firewall Rules** - Stricter UFW configuration
4. **Automatic Security Updates** - Keep system patched
5. **Security Audit Script** - Regular security checks
6. **Key Management** - Secure key rotation procedures

---

## 🚫 Step 1: Install and Configure Fail2ban

Fail2ban monitors logs and blocks IPs with suspicious activity.

### 1.1: Install Fail2ban

```bash
# Update package list
sudo apt update

# Install fail2ban
sudo apt install -y fail2ban

# Start and enable fail2ban
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

# Verify status
sudo systemctl status fail2ban
```

### 1.2: Configure Fail2ban for SSH Protection

**1. Create local configuration file:**
```bash
# Don't edit jail.conf directly - create jail.local
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
```

**2. Edit jail.local:**
```bash
sudo nano /etc/fail2ban/jail.local
```

**3. Find and modify the [DEFAULT] section:**
```ini
[DEFAULT]
# Ban time: 1 hour (3600 seconds)
bantime = 3600

# Find time: 10 minutes window
findtime = 600

# Max retry: 5 attempts before ban
maxretry = 5

# Ignore local network (don't ban yourself!)
ignoreip = 127.0.0.1/8 ::1 192.168.0.0/24

# Email alerts (optional - configure later)
# destemail = your-email@example.com
# sendername = Fail2Ban
# action = %(action_mwl)s
```

**4. Configure SSH jail (find [sshd] section):**
```ini
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
```

**5. Save and restart fail2ban:**
```bash
# Test configuration
sudo fail2ban-client -t

# Restart fail2ban
sudo systemctl restart fail2ban

# Check status
sudo fail2ban-client status
```

### 1.3: Create Custom Fail2ban Filter for WireGuard (Optional)

**1. Create WireGuard filter:**
```bash
sudo nano /etc/fail2ban/filter.d/wireguard.conf
```

**2. Add filter rules:**
```ini
# Fail2Ban filter for WireGuard
[Definition]

# Match failed handshake attempts
failregex = ^.*wg0:.*Invalid handshake initiation from.*<HOST>.*$
            ^.*wg0:.*Could not create new session.*<HOST>.*$

ignoreregex =
```

**3. Create jail for WireGuard:**
```bash
sudo nano /etc/fail2ban/jail.d/wireguard.conf
```

**4. Add jail configuration:**
```ini
[wireguard]
enabled = true
port = 51820
protocol = udp
filter = wireguard
logpath = /var/log/syslog
maxretry = 3
bantime = 7200
findtime = 600
```

**5. Restart fail2ban:**
```bash
sudo systemctl restart fail2ban
sudo fail2ban-client status wireguard
```

### 1.4: Monitoring Fail2ban

**Check active jails:**
```bash
# List all jails
sudo fail2ban-client status

# Check specific jail
sudo fail2ban-client status sshd

# Check WireGuard jail
sudo fail2ban-client status wireguard
```

**View banned IPs:**
```bash
# Current bans for SSH
sudo fail2ban-client status sshd | grep "Banned IP"

# Manually ban an IP (testing)
sudo fail2ban-client set sshd banip 1.2.3.4

# Manually unban an IP
sudo fail2ban-client set sshd unbanip 1.2.3.4
```

**Check fail2ban logs:**
```bash
# View fail2ban log
sudo tail -f /var/log/fail2ban.log

# View recent bans
sudo grep "Ban" /var/log/fail2ban.log | tail -20
```

---

## 🔐 Step 2: SSH Hardening

Secure your SSH server to prevent unauthorized access.

### 2.1: Backup SSH Configuration

```bash
# Create backup
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)

# Verify backup
ls -la /etc/ssh/sshd_config.backup.*
```

### 2.2: Generate SSH Key Pair (If Not Already Done)

**On your client machine (laptop/desktop), NOT on server:**

```bash
# Windows (PowerShell):
ssh-keygen -t ed25519 -C "your-email@example.com"

# Mac/Linux:
ssh-keygen -t ed25519 -C "your-email@example.com"

# Or use RSA 4096 if ed25519 not supported:
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Save to default location (~/.ssh/id_ed25519)
# Set a strong passphrase!
```

### 2.3: Copy SSH Key to Server

**From your client machine:**

```bash
# Copy public key to server
ssh-copy-id -i ~/.ssh/id_ed25519.pub your-username@192.168.x.x

# Test SSH key login (should not ask for password)
ssh -i ~/.ssh/id_ed25519 your-username@192.168.x.x
```

**If ssh-copy-id doesn't work:**
```bash
# Manual method:
# 1. Display your public key
cat ~/.ssh/id_ed25519.pub

# 2. On server, add to authorized_keys:
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
# Paste the public key, save

# 3. Set permissions
chmod 600 ~/.ssh/authorized_keys
```

### 2.4: Harden SSH Configuration

**⚠️ IMPORTANT: Test each change before disconnecting your current SSH session!**

**1. Edit SSH configuration:**
```bash
sudo nano /etc/ssh/sshd_config
```

**2. Apply these security settings:**

```bash
# SSH Hardened Configuration

# Change default port (optional but recommended)
# Port 22  # Change to custom port like 2222
Port 22  # Keep as 22 for now, change after testing

# Disable root login
PermitRootLogin no

# Disable password authentication (use keys only)
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no

# Only allow specific user (replace with your username)
AllowUsers your-username

# Or allow specific group
# AllowGroups ssh-users

# Disable empty passwords
PermitEmptyPasswords no

# Limit authentication attempts
MaxAuthTries 3
MaxSessions 2

# Enable public key authentication
PubkeyAuthentication yes

# Disable X11 forwarding (unless you need it)
X11Forwarding no

# Disable unnecessary features
PermitUserEnvironment no
AllowTcpForwarding no
AllowStreamLocalForwarding no
GatewayPorts no
PermitTunnel no

# Use protocol 2 only (should be default)
Protocol 2

# Stronger encryption algorithms
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256

# Set idle timeout (15 minutes)
ClientAliveInterval 300
ClientAliveCountMax 2

# Log level
LogLevel VERBOSE

# Banner (optional - warns unauthorized users)
# Banner /etc/ssh/banner.txt

# Strict mode
StrictModes yes

# Host keys (use only strong algorithms)
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
```

**3. Test configuration:**
```bash
# Test SSH configuration syntax
sudo sshd -t

# Should return nothing if OK
# If errors, fix them before restarting
```

**4. Restart SSH (ONLY if test passed):**
```bash
# Restart SSH service
sudo systemctl restart sshd

# Verify it's running
sudo systemctl status sshd
```

**5. Test SSH login in NEW terminal (don't close current one!):**
```bash
# From another terminal on your local network:
ssh -i ~/.ssh/id_ed25519 your-username@192.168.x.x

# Should login without password using key
```

**⚠️ If you get locked out:**
- Use physical access or console to fix
- Revert to backup: `sudo cp /etc/ssh/sshd_config.backup.YYYYMMDD /etc/ssh/sshd_config`
- This is why we keep current session open!

### 2.5: Create SSH Warning Banner (Optional)

```bash
# Create banner file
sudo nano /etc/ssh/banner.txt
```

**Add warning text:**
```
***************************************************************************
                          UNAUTHORIZED ACCESS PROHIBITED
***************************************************************************
This system is for authorized users only. All activity is monitored and
logged. Unauthorized access attempts will be prosecuted to the fullest
extent of the law.
***************************************************************************
```

**Enable banner in sshd_config:**
```bash
sudo nano /etc/ssh/sshd_config

# Add or uncomment:
Banner /etc/ssh/banner.txt

# Restart SSH
sudo systemctl restart sshd
```

---

## 🔥 Step 3: Advanced Firewall Configuration

Enhance UFW with stricter rules and logging.

### 3.1: Enhanced UFW Rules

```bash
# Reset UFW to default (optional - only if needed)
# sudo ufw --force reset

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default deny routed

# Enable logging (medium level)
sudo ufw logging medium

# Allow SSH from local network only
sudo ufw allow from 192.168.0.0/24 to any port 22 proto tcp comment 'SSH - Local network only'

# Allow xRDP from local network only
sudo ufw allow from 192.168.0.0/24 to any port 3389 proto tcp comment 'xRDP - Local network only'

# Allow WireGuard VPN (must be accessible from internet)
sudo ufw allow 51820/udp comment 'WireGuard VPN'

# Allow WireGuard Web UI from local network only
sudo ufw allow from 192.168.0.0/24 to any port 51821 proto tcp comment 'WireGuard Web UI - Local only'

# Allow from VPN network to access services
sudo ufw allow from 10.13.13.0/24 to any comment 'WireGuard VPN clients'

# Allow Docker subnet (if needed)
sudo ufw allow from 172.16.0.0/12 comment 'Docker networks'

# Rate limiting for SSH (prevent brute force)
sudo ufw limit from 192.168.0.0/24 to any port 22 proto tcp comment 'SSH rate limit'
```

### 3.2: Configure UFW for Docker and WireGuard

**1. Edit UFW default forward policy:**
```bash
sudo nano /etc/default/ufw
```

**2. Change DEFAULT_FORWARD_POLICY:**
```bash
# Before:
# DEFAULT_FORWARD_POLICY="DROP"

# After:
DEFAULT_FORWARD_POLICY="ACCEPT"
```

**3. Configure NAT for WireGuard (if not already done):**
```bash
sudo nano /etc/ufw/before.rules
```

**4. Add at the TOP (after initial comments, before *filter):**
```bash
# NAT table rules for WireGuard
*nat
:POSTROUTING ACCEPT [0:0]

# Get your network interface name first: ip link show
# Replace eth0 with your actual interface (e.g., enp0s3, ens33, etc.)
-A POSTROUTING -s 10.13.13.0/24 -o eth0 -j MASQUERADE

COMMIT

# Don't delete or modify the following required lines:
*filter
```

**5. Enable forwarding in UFW sysctl:**
```bash
sudo nano /etc/ufw/sysctl.conf
```

**6. Uncomment or add:**
```bash
net/ipv4/ip_forward=1
net/ipv4/conf/all/forwarding=1
net/ipv6/conf/all/forwarding=1
```

**7. Reload UFW:**
```bash
sudo ufw disable
sudo ufw enable
sudo systemctl restart ufw
```

### 3.3: Create Firewall Status Script

```bash
mkdir -p ~/wireguard-vpn/scripts
nano ~/wireguard-vpn/scripts/firewall-status.sh
```

**Add script content:**
```bash
#!/bin/bash
# Firewall Status Check Script

echo "=================================="
echo "UFW Firewall Status"
echo "=================================="
echo ""

echo "1. UFW Status:"
sudo ufw status verbose
echo ""

echo "2. UFW Application Profiles:"
sudo ufw app list
echo ""

echo "3. Active Connections:"
sudo ss -tunap | head -20
echo ""

echo "4. Recent UFW Log Entries:"
sudo tail -20 /var/log/ufw.log
echo ""

echo "5. IP Forwarding Status:"
echo "IPv4 forwarding: $(cat /proc/sys/net/ipv4/ip_forward)"
echo ""

echo "6. NAT Rules:"
sudo iptables -t nat -L -n -v
echo ""

echo "7. Filter Rules:"
sudo iptables -L -n -v | head -30
echo ""

echo "=================================="
echo "Firewall check complete"
echo "=================================="
```

**Make executable and run:**
```bash
chmod +x ~/wireguard-vpn/scripts/firewall-status.sh
~/wireguard-vpn/scripts/firewall-status.sh
```

---

## 🔄 Step 4: Automatic Security Updates

Configure unattended upgrades for security patches.

### 4.1: Install Unattended Upgrades

```bash
# Install package
sudo apt update
sudo apt install -y unattended-upgrades apt-listchanges

# Enable automatic updates
sudo dpkg-reconfigure -plow unattended-upgrades
# Select "Yes" when prompted
```

### 4.2: Configure Unattended Upgrades

```bash
# Edit configuration
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

**Configure these options:**
```bash
// Automatically upgrade packages from these origins
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
    // "${distro_id}:${distro_codename}-updates";  // Uncomment for all updates
};

// Remove unused dependencies
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Remove unused kernel packages
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";

// Automatically reboot if required
Unattended-Upgrade::Automatic-Reboot "true";

// Reboot time (3 AM)
Unattended-Upgrade::Automatic-Reboot-Time "03:00";

// Send email reports (optional - configure email later)
// Unattended-Upgrade::Mail "your-email@example.com";

// Enable logging
Unattended-Upgrade::SyslogEnable "true";
```

### 4.3: Configure Update Schedule

```bash
sudo nano /etc/apt/apt.conf.d/20auto-upgrades
```

**Set update schedule:**
```bash
APT::Periodic::Update-Package-Lists "1";           # Update daily
APT::Periodic::Download-Upgradeable-Packages "1";  # Download daily
APT::Periodic::AutocleanInterval "7";              # Clean weekly
APT::Periodic::Unattended-Upgrade "1";             # Install daily
```

### 4.4: Test Unattended Upgrades

```bash
# Dry run (test without actually upgrading)
sudo unattended-upgrade --dry-run --debug

# Check logs
sudo tail -f /var/log/unattended-upgrades/unattended-upgrades.log
```

---

## 🔍 Step 5: Security Audit Script

Create a comprehensive security audit script.

```bash
nano ~/wireguard-vpn/scripts/security-audit.sh
```

**Add script content:**
```bash
#!/bin/bash
# Security Audit Script for VPN Server
# Run: sudo ./security-audit.sh

echo "========================================"
echo "VPN Server Security Audit"
echo "Date: $(date)"
echo "========================================"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

echo "1. SYSTEM INFORMATION"
echo "-------------------------------------"
echo "Hostname: $(hostname)"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo ""

echo "2. NETWORK CONFIGURATION"
echo "-------------------------------------"
echo "IP Address: $(ip addr show | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')"
echo "Public IP: $(curl -s ifconfig.me)"
echo "WireGuard Status: $(systemctl is-active docker)"
echo ""

echo "3. SSH SECURITY"
echo "-------------------------------------"
grep -E "^Port|^PermitRootLogin|^PasswordAuthentication|^PubkeyAuthentication" /etc/ssh/sshd_config | grep -v "#"
echo ""

echo "4. FIREWALL STATUS"
echo "-------------------------------------"
ufw status | head -15
echo ""

echo "5. FAIL2BAN STATUS"
echo "-------------------------------------"
if systemctl is-active --quiet fail2ban; then
    echo "Fail2ban: Active"
    fail2ban-client status | grep "Jail list"
    fail2ban-client status sshd | grep "Currently banned"
else
    echo "Fail2ban: Inactive or not installed"
fi
echo ""

echo "6. DOCKER SECURITY"
echo "-------------------------------------"
echo "Docker containers running:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "7. WIREGUARD STATUS"
echo "-------------------------------------"
if docker ps | grep -q wg-easy; then
    docker exec wg-easy wg show | head -10
else
    echo "WireGuard container not running"
fi
echo ""

echo "8. LISTENING PORTS"
echo "-------------------------------------"
ss -tulpn | grep LISTEN | grep -E ":(22|3389|51820|51821)" 
echo ""

echo "9. RECENT FAILED LOGIN ATTEMPTS"
echo "-------------------------------------"
grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5 || echo "No recent failures"
echo ""

echo "10. DISK USAGE"
echo "-------------------------------------"
df -h / | tail -1
echo ""

echo "11. MEMORY USAGE"
echo "-------------------------------------"
free -h | grep Mem
echo ""

echo "12. UPDATES AVAILABLE"
echo "-------------------------------------"
apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0"
echo ""

echo "13. SECURITY RECOMMENDATIONS"
echo "-------------------------------------"

# Check if root login enabled
if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
    echo "⚠️  WARNING: Root SSH login is enabled"
fi

# Check if password auth enabled
if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
    echo "⚠️  WARNING: SSH password authentication is enabled"
fi

# Check if fail2ban running
if ! systemctl is-active --quiet fail2ban; then
    echo "⚠️  WARNING: Fail2ban is not running"
fi

# Check if UFW enabled
if ! ufw status | grep -q "Status: active"; then
    echo "⚠️  WARNING: UFW firewall is not active"
fi

# Check for available updates
UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
if [ "$UPDATES" -gt 0 ]; then
    echo "⚠️  WARNING: $UPDATES package updates available"
fi

echo ""
echo "========================================"
echo "Audit Complete"
echo "========================================"
```

**Make executable:**
```bash
chmod +x ~/wireguard-vpn/scripts/security-audit.sh
```

**Run audit:**
```bash
sudo ~/wireguard-vpn/scripts/security-audit.sh
```

**Schedule regular audits:**
```bash
# Add to crontab
crontab -e

# Run security audit every Monday at 9 AM
0 9 * * 1 sudo /home/YOUR-USERNAME/wireguard-vpn/scripts/security-audit.sh > /home/YOUR-USERNAME/wireguard-vpn/logs/security-audit-$(date +\%Y\%m\%d).log 2>&1
```

---

## 🔑 Step 6: Key Management and Rotation

Best practices for managing WireGuard keys.

### 6.1: Backup WireGuard Keys

```bash
# Create secure backup directory
mkdir -p ~/wireguard-vpn/backups/keys
chmod 700 ~/wireguard-vpn/backups/keys

# Backup WireGuard configuration (includes keys)
sudo cp -r ~/wireguard-vpn/config ~/wireguard-vpn/backups/keys/config-backup-$(date +%Y%m%d)

# Create encrypted archive
cd ~/wireguard-vpn/backups
tar czf keys-backup-$(date +%Y%m%d).tar.gz keys/
gpg -c keys-backup-$(date +%Y%m%d).tar.gz  # Enter strong passphrase
rm keys-backup-$(date +%Y%m%d).tar.gz  # Remove unencrypted archive

# List encrypted backups
ls -lh ~/wireguard-vpn/backups/*.gpg
```

### 6.2: Key Rotation Best Practices

**When to rotate keys:**
- Every 90-180 days (recommended)
- When a device is compromised
- When a device is lost or stolen
- When an employee/user leaves

**How to rotate:**

**Option 1: Remove and recreate client (simplest):**
```
1. Access Web UI (http://192.168.x.x:51821)
2. Delete old client configuration
3. Create new client with same name
4. Deploy new configuration to device
```

**Option 2: Regenerate server keys (advanced):**
```bash
# Stop WireGuard
cd ~/wireguard-vpn
docker compose down

# Backup current config
sudo cp -r config config-backup-$(date +%Y%m%d)

# Remove old config (forces regeneration)
sudo rm -rf config/*
sudo rm -rf data/*

# Start WireGuard (new keys generated automatically)
docker compose up -d

# All clients must be recreated with new configurations!
```

### 6.3: Secure Key Storage

**Never:**
- ❌ Store keys in plain text on cloud storage
- ❌ Email keys unencrypted
- ❌ Share keys between multiple devices
- ❌ Store keys on public repositories

**Always:**
- ✅ Encrypt backups with GPG
- ✅ Use password managers for key storage
- ✅ Generate unique keys per device
- ✅ Revoke keys immediately when device is lost

---

## 📊 Step 7: Additional Security Measures

### 7.1: Enable AppArmor (if not already enabled)

```bash
# Check if AppArmor is active
sudo aa-status

# If not active, enable it
sudo systemctl enable apparmor
sudo systemctl start apparmor

# Check status again
sudo aa-status
```

### 7.2: Install and Configure Logwatch

```bash
# Install logwatch
sudo apt install -y logwatch

# Test logwatch (email yourself daily summary)
sudo logwatch --detail Low --mailto your-email@example.com --service all --range today

# Configure for daily emails
sudo nano /etc/cron.daily/00logwatch
```

### 7.3: Disable Unnecessary Services

```bash
# List all services
systemctl list-unit-files --type=service --state=enabled

# Disable unnecessary services (examples - verify before disabling!)
# sudo systemctl disable bluetooth.service
# sudo systemctl disable avahi-daemon.service
# sudo systemctl disable cups.service  # Printer service

# Only disable services you're certain you don't need!
```

### 7.4: Set File Permissions for WireGuard

```bash
# Secure WireGuard directories
chmod 700 ~/wireguard-vpn/config
chmod 700 ~/wireguard-vpn/backups
chmod 755 ~/wireguard-vpn/scripts
chmod 755 ~/wireguard-vpn/logs

# Secure scripts
chmod 750 ~/wireguard-vpn/scripts/*.sh

# Verify permissions
ls -la ~/wireguard-vpn/
```

---

**✅ Security Hardening Complete!**

You should now have:
- ✅ Fail2ban protecting SSH and WireGuard
- ✅ SSH hardened with key-only authentication
- ✅ Advanced UFW firewall rules
- ✅ Automatic security updates configured
- ✅ Security audit script for monitoring
- ✅ Key backup and rotation procedures
- ✅ Additional security measures enabled

**SECURITY CHECKPOINT:**
- ✅ SSH password authentication disabled
- ✅ Root SSH login disabled
- ✅ Fail2ban actively monitoring
- ✅ Firewall rules restricting access
- ✅ Automatic updates enabled
- ✅ Security auditing in place
- ✅ Keys backed up securely

**Your server is now significantly hardened against attacks!**

---

## 📱 Client Configuration Guide

This section covers setting up WireGuard VPN clients on all your devices.

### Client Setup Overview

For each device, you'll:
1. Install WireGuard client software
2. Import configuration from wg-easy Web UI
3. Connect to VPN
4. Test connectivity
5. Access your server via SSH/RDP through VPN

---

## 🪟 Windows Client Setup

### Step 1: Create Client Configuration on Server

**1. Access wg-easy Web UI:**
```
http://192.168.x.x:51821
```
Login with your password.

**2. Create new client:**
- Click "**Add Client**"
- Enter name: `Windows-Laptop` (or descriptive name for your PC)
- Click "**Create**"

**3. Download configuration:**
- Find your newly created client in the list
- Click the **Download** icon
- Save the `.conf` file (e.g., `Windows-Laptop.conf`)

### Step 2: Install WireGuard for Windows

**1. Download WireGuard:**
```
https://www.wireguard.com/install/
```
Or direct download:
```
https://download.wireguard.com/windows-client/wireguard-installer.exe
```

**2. Run the installer:**
- Double-click `wireguard-installer.exe`
- Click "**Yes**" for User Account Control
- Follow installation wizard
- Click "**Install**"
- Click "**Finish**"

### Step 3: Import Configuration

**Method 1: Import from file**

1. Open WireGuard application
2. Click "**Add Tunnel**" dropdown
3. Select "**Import tunnel(s) from file**"
4. Browse to your `.conf` file
5. Select and click "**Open**"
6. Configuration imported!

**Method 2: Manual import**

1. Click "**Add Tunnel**" → "**Add empty tunnel**"
2. Name it: `Windows-Laptop`
3. Copy configuration from wg-easy Web UI (click "Show" button)
4. Paste into WireGuard window
5. Click "**Save**"

### Step 4: Connect to VPN

**1. Select your tunnel:**
- In WireGuard app, click on `Windows-Laptop`

**2. Click "Activate"**
- Status should change to "Active"
- You'll see:
  - Latest handshake time
  - Transfer data (sent/received)

**3. Verify connection:**
- Status shows "Active"
- Latest handshake should show recent time (few seconds ago)
- Transfer counters should increment

### Step 5: Test VPN Connection

**1. Check your IP address:**
```powershell
# Open PowerShell
# Check public IP (should show your home IP)
curl ifconfig.me
```

**2. Test VPN network access:**
```powershell
# Ping server's VPN IP
ping 10.13.13.1

# Should get replies from 10.13.13.1
```

**3. Check routing:**
```powershell
# View routing table
route print | findstr "0.0.0.0"

# Should show route through WireGuard interface
```

### Step 6: Access Server via SSH

**1. Install SSH client (Windows 10/11 has it built-in):**
```powershell
# Test if SSH is available
ssh -V
```

**If not installed:**
- Settings → Apps → Optional Features
- Add "OpenSSH Client"

**2. Connect via VPN:**
```powershell
# SSH through VPN (using server's VPN IP)
ssh -i C:\Users\YourName\.ssh\id_ed25519 your-username@10.13.13.1

# Or using local IP (still through VPN tunnel)
ssh your-username@192.168.x.x
```

### Step 7: Access Server via RDP

**1. Open Remote Desktop Connection:**
- Press `Win + R`
- Type: `mstsc`
- Press Enter

**2. Connect to server:**
- Computer: `10.13.13.1` (server's VPN IP)
- Or: `192.168.x.x` (local IP)
- Click "**Connect**"

**3. Login:**
- Enter your Ubuntu username
- Enter your password
- Click "**OK**"

**4. You should now see your Ubuntu desktop via xRDP!**

### Step 8: Configure Auto-Start (Optional)

**Option 1: Start on boot**
1. Right-click WireGuard system tray icon
2. Click "**Run on startup**"

**Option 2: Tunnel-specific auto-connect**
1. In WireGuard app, click your tunnel
2. Check "**Activate on startup**"

### Windows Troubleshooting

**Connection fails:**
```powershell
# Check if service is running
Get-Service WireGuardTunnel*

# View logs
# In WireGuard app: Click tunnel → Click "Edit" → View log window
```

**DNS not working:**
- Edit tunnel configuration
- Add or verify DNS line:
```ini
DNS = 1.1.1.1, 8.8.8.8
```

**Can't access local network:**
- Verify AllowedIPs in configuration
- Should include: `0.0.0.0/0` for all traffic

---

## 🍎 macOS Client Setup

### Step 1: Create Client Configuration on Server

**1. Access wg-easy Web UI from Mac:**
```
http://192.168.x.x:51821
```

**2. Create new client:**
- Click "**Add Client**"
- Enter name: `MacBook-Pro`
- Click "**Create**"

**3. Download configuration:**
- Click **Download** icon
- Save `MacBook-Pro.conf` to Downloads

### Step 2: Install WireGuard for macOS

**Method 1: Mac App Store (Recommended)**
1. Open App Store
2. Search "**WireGuard**"
3. Click "**Get**" / "**Install**"
4. Enter Apple ID password if prompted

**Method 2: Direct Download**
```
https://apps.apple.com/us/app/wireguard/id1451685025
```

### Step 3: Import Configuration

**1. Open WireGuard app from Applications**

**2. Import tunnel:**
- Click "**Import tunnel(s) from file**"
- Or: File menu → Import Tunnel(s) from File
- Navigate to Downloads
- Select `MacBook-Pro.conf`
- Click "**Open**"

**3. Grant permissions:**
- macOS will ask to allow VPN configuration
- Click "**Allow**"
- Enter your Mac password
- Click "**OK**"

### Step 4: Connect to VPN

**1. In WireGuard app:**
- Find `MacBook-Pro` tunnel
- Toggle switch to "**On**"
- Status should show "Active"

**2. Menu bar icon:**
- WireGuard icon appears in menu bar
- Shows active connection status

### Step 5: Test VPN Connection

**1. Check public IP:**
```bash
# Open Terminal
curl ifconfig.me
# Should show your home public IP
```

**2. Test VPN connectivity:**
```bash
# Ping server VPN IP
ping -c 4 10.13.13.1

# Should get replies
```

**3. Test DNS:**
```bash
# DNS should work
nslookup google.com
```

### Step 6: Access Server via SSH

```bash
# Open Terminal

# SSH through VPN
ssh your-username@10.13.13.1

# Or using local IP
ssh your-username@192.168.x.x
```

### Step 7: Access Server via RDP

**Option 1: Microsoft Remote Desktop (Recommended)**

**1. Install Microsoft Remote Desktop:**
- App Store → Search "Microsoft Remote Desktop"
- Install the app

**2. Add connection:**
- Open Microsoft Remote Desktop
- Click "**+**" → "**Add PC**"
- PC name: `10.13.13.1` or `192.168.x.x`
- User account: Add your Ubuntu credentials
- Friendly name: `Ubuntu Server`
- Click "**Add**"

**3. Connect:**
- Double-click the connection
- Enter password if prompted
- Click "**Continue**"

**Option 2: Using built-in RDP client (requires third-party)**
- Install "**CoRD**" or "**Royal TSX**" from App Store

### Step 8: Auto-Connect on Boot (Optional)

**1. In WireGuard app:**
- Right-click (or Ctrl+click) on tunnel
- Select "**Activate on Launch**"

**2. Add WireGuard to Login Items:**
- System Preferences → Users & Groups
- Login Items tab
- Click "**+**"
- Add WireGuard app
- Check "**Hide**" option

### macOS Troubleshooting

**Permission issues:**
```bash
# Reset permissions
sudo rm -rf /var/root/Library/Preferences/com.wireguard.*
```

**Connection drops:**
- System Preferences → Battery → Prevent Mac from sleeping (when on power)

**Split tunnel not working:**
- Verify AllowedIPs in configuration includes `0.0.0.0/0`

---

## 📱 iOS/iPadOS Client Setup

### Step 1: Install WireGuard App

**1. Open App Store on iPhone/iPad**
**2. Search "WireGuard"**
**3. Install official WireGuard app by WireGuard Development Team**

### Step 2: Generate QR Code Configuration

**1. On your computer, access wg-easy Web UI:**
```
http://192.168.x.x:51821
```

**2. Create new client:**
- Click "**Add Client**"
- Name: `iPhone-13` (or your device)
- Click "**Create**"

**3. Display QR code:**
- Find your new client in the list
- Click the **QR Code** icon
- QR code appears on screen
- **Keep this window open**

### Step 3: Import Configuration via QR Code

**1. On iOS device, open WireGuard app**

**2. Add tunnel:**
- Tap "**+**" button (top right)
- Select "**Create from QR code**"

**3. Grant camera permission:**
- Tap "**OK**" to allow camera access

**4. Scan QR code:**
- Point camera at QR code on computer screen
- App automatically detects and imports

**5. Name the tunnel:**
- Suggested name appears (e.g., `iPhone-13`)
- Tap "**Save**"

### Step 4: Connect to VPN

**1. Toggle VPN on:**
- Find your tunnel in the list
- Tap the toggle switch
- Status changes to "**Active**"

**2. Grant VPN permission (first time only):**
- iOS asks permission to add VPN configuration
- Tap "**Allow**"
- Enter device passcode or use Face ID/Touch ID

**3. Verify connection:**
- VPN icon appears in status bar
- Latest handshake time updates
- Transfer data shows activity

### Step 5: Test VPN Connection

**1. Check IP address:**
- Safari → Visit: `https://ifconfig.me`
- Should show your home public IP

**2. Test VPN is working:**
- Settings → WireGuard → Your tunnel
- Verify "Latest handshake" shows recent time
- Transfer counters incrementing

### Step 6: Access Server via SSH

**Install SSH client app:**

**Option 1: Termius (Free, Recommended)**
1. App Store → Install "Termius"
2. Open Termius
3. Add new host:
   - Label: Ubuntu Server
   - Hostname: `10.13.13.1`
   - Username: your-username
   - Port: 22
4. Add SSH key or use password
5. Connect!

**Option 2: Blink Shell**
- More advanced, supports mosh
- Available in App Store

### Step 7: Access Server via RDP

**Install RDP client app:**

**Microsoft Remote Desktop (Free, Recommended)**
1. App Store → Install "Microsoft Remote Desktop"
2. Open the app
3. Tap "**+**" → "**Add PC**"
4. PC name: `10.13.13.1`
5. User account: Add credentials
6. Friendly name: `Ubuntu Server`
7. Tap "**Save**"
8. Tap connection to connect

### Step 8: Configure On-Demand VPN (Optional)

**Enable automatic connection when needed:**

1. WireGuard app → Tap your tunnel name (don't toggle)
2. Tap "**Edit**"
3. Toggle "**On-Demand Activation**"
4. Add rules:
   - **Wi-Fi**: Connect on specific Wi-Fi networks
   - **Cellular**: Connect on cellular
   - **Ethernet**: Connect when tethered
5. Tap "**Save**"

**Example configuration:**
- Connect on: Cellular (always)
- Connect on: Any Wi-Fi except home network
- This keeps you secure when traveling!

### iOS Troubleshooting

**VPN connects but no internet:**
- Check DNS settings in tunnel config
- Verify AllowedIPs = `0.0.0.0/0, ::/0`

**Battery drain:**
- Disable "On-Demand" when not needed
- Adjust persistent keepalive interval

**Connection drops:**
- Settings → General → VPN → Info button
- Enable "Connect On Demand"

---

## 🤖 Android Client Setup

### Step 1: Install WireGuard App

**1. Open Google Play Store**
**2. Search "WireGuard"**
**3. Install official WireGuard app by WireGuard Development Team**

### Step 2: Generate QR Code Configuration

**1. On computer, access wg-easy Web UI:**
```
http://192.168.x.x:51821
```

**2. Create client:**
- Click "**Add Client**"
- Name: `Android-Phone`
- Click "**Create**"

**3. Show QR code:**
- Click **QR Code** icon
- Keep window open for scanning

### Step 3: Import via QR Code

**1. Open WireGuard app on Android**

**2. Add tunnel:**
- Tap "**+**" button (bottom right)
- Select "**Scan from QR code**"

**3. Grant camera permission:**
- Tap "**Allow**" for camera access

**4. Scan QR code:**
- Point camera at QR code
- App automatically imports

**5. Name tunnel:**
- Enter name: `Android-Phone`
- Tap "**Create Tunnel**"

### Step 4: Connect to VPN

**1. Enable VPN:**
- Find your tunnel
- Tap toggle switch
- Status → "**Active**"

**2. Grant permission (first time):**
- Android VPN connection request
- Tap "**OK**"

**3. Verify:**
- Key icon in status bar
- Transfer statistics updating

### Step 5: Test Connection

**1. Check IP:**
- Browser → Visit `ifconfig.me`
- Should show home public IP

**2. In WireGuard app:**
- Tap tunnel name
- Verify handshake time
- Check transfer data

### Step 6: Access Server via SSH

**Install SSH client:**

**Termux (Full Linux terminal - Recommended)**
1. Play Store → Install "Termux"
2. Open Termux
3. Install OpenSSH:
```bash
pkg update
pkg install openssh
```
4. Connect:
```bash
ssh your-username@10.13.13.1
```

**JuiceSSH (GUI SSH client)**
1. Play Store → Install "JuiceSSH"
2. Open app → Connections
3. Add connection:
   - Nickname: Ubuntu Server
   - Address: `10.13.13.1`
   - Username: your-username
4. Connect

### Step 7: Access Server via RDP

**Microsoft Remote Desktop (Free)**
1. Play Store → Install "Microsoft Remote Desktop"
2. Open app
3. Tap "**+**"
4. Select "**Desktop**"
5. Configure:
   - PC name: `10.13.13.1`
   - User name: your-username
   - Friendly name: Ubuntu Server
6. Tap "**Save**"
7. Tap to connect

**Alternative: RD Client**
- Lighter alternative
- Available in Play Store

### Step 8: Configure Always-On VPN (Optional)

**1. Android Settings:**
- Settings → Network & Internet → VPN
- Tap ⚙️ (gear icon) next to WireGuard

**2. Configure:**
- Toggle "**Always-on VPN**"
- Toggle "**Block connections without VPN**" (optional)

**Note:** This keeps VPN always active, even after reboot.

### Android Troubleshooting

**Connection successful but no internet:**
```
1. Edit tunnel in WireGuard app
2. Check DNS servers present
3. Verify AllowedIPs = 0.0.0.0/0
```

**Battery optimization killing VPN:**
```
1. Settings → Apps → WireGuard
2. Battery → Unrestricted
3. Disable battery optimization for WireGuard
```

**Split tunneling needed:**
```
1. Edit tunnel configuration
2. Change AllowedIPs to specific networks:
   AllowedIPs = 192.168.0.0/24, 10.13.13.0/24
3. This routes only local traffic through VPN
```

---

## 🧪 Testing VPN Functionality

After setting up clients, perform these tests:

### Test 1: Verify IP Address Changes

**Without VPN:**
```bash
curl ifconfig.me
# Should show your current location's IP
```

**With VPN connected:**
```bash
curl ifconfig.me
# Should show your home public IP
```

### Test 2: Access Local Network Resources

**Ping server:**
```bash
ping 10.13.13.1
# Should get replies
```

**Access other local devices (if any):**
```bash
ping 192.168.0.1  # Router
ping 192.168.x.x  # Server
```

### Test 3: SSH Access Through VPN

```bash
# Connect via VPN IP
ssh your-username@10.13.13.1

# Should login successfully
# Check you're on the server:
hostname
ip addr show
```

### Test 4: RDP Access Through VPN

1. Connect VPN
2. Open RDP client
3. Connect to `10.13.13.1`
4. Should see Ubuntu desktop

### Test 5: Internet Access Through VPN

**Test browsing:**
- Open browser
- Visit websites
- Should work normally
- IP location shows your home location

**Test DNS:**
```bash
nslookup google.com
# Should resolve successfully
```

### Test 6: Speed Test

**Without VPN:**
```
Visit: https://fast.com or https://speedtest.net
Note download/upload speeds
```

**With VPN:**
```
Same speed test
Compare results
(Expect slight decrease due to encryption overhead)
```

### Test 7: VPN Server Monitoring

**On server, check connected clients:**
```bash
cd ~/wireguard-vpn
docker exec wg-easy wg show

# Should display:
# - interface: wg0
# - peer: (client public key)
# - endpoint: (client IP:port)
# - latest handshake: (seconds ago)
# - transfer: (data sent/received)
```

**Check Web UI:**
- Access http://192.168.x.x:51821
- View connected clients
- Check transfer statistics

---

## 📊 Client Comparison Matrix

| Feature | Windows | macOS | iOS | Android |
|---------|---------|-------|-----|---------|
| **Installation** | Installer | App Store | App Store | Play Store |
| **Config Import** | File/Manual | File | QR Code | QR Code |
| **Auto-start** | ✅ | ✅ | ✅ | ✅ |
| **Always-On** | ⚠️ Manual | ⚠️ Manual | ✅ Native | ✅ Native |
| **On-Demand** | ❌ | ❌ | ✅ | ⚠️ Limited |
| **Split Tunnel** | ✅ | ✅ | ✅ | ✅ |
| **Battery Impact** | N/A | Low | Low-Medium | Low-Medium |

---

## 🌍 Using VPN for International Travel

When traveling abroad and wanting to access internet as if you're home:

### Before Travel

**1. Test VPN connection works from external network:**
- Use mobile data (not home WiFi)
- Connect to VPN
- Verify it works

**2. Document credentials:**
- Save VPN configuration backup
- Note Web UI password
- Save SSH keys securely

**3. Set up automatic connection:**
- Enable "On-Demand" (iOS) or "Always-On" (Android)
- Configure to activate on any WiFi except home

### While Traveling

**1. Connect to hotel/public WiFi:**
- Connect to WiFi network
- **Before browsing, activate VPN**
- Verify connection in WireGuard app

**2. All traffic now routes through home:**
- Your IP = home IP
- Access geo-restricted content
- Bypass censorship (in some countries)
- Secure public WiFi usage

**3. Access your server:**
- SSH: `ssh user@10.13.13.1`
- RDP: Connect to `10.13.13.1`
- Access as if you're home!

### Security Tips When Traveling

**✅ DO:**
- Always connect VPN before browsing on public WiFi
- Use strong VPN password
- Keep WireGuard app updated
- Monitor connection status

**❌ DON'T:**
- Share VPN credentials
- Leave devices unlocked
- Connect to suspicious WiFi networks
- Store passwords in plain text

---

**✅ Client Configuration Complete!**

You should now have:
- ✅ WireGuard clients installed on all devices
- ✅ Configurations imported and tested
- ✅ SSH access working through VPN
- ✅ RDP access working through VPN
- ✅ Internet routing through VPN working
- ✅ Auto-connect configured (optional)

**All devices can now:**
- 🔒 Securely access your Ubuntu server from anywhere
- 🌍 Route internet through your home connection when traveling
- 📱 Connect from any network (WiFi, cellular, etc.)
- 🛡️ Protected by WireGuard's modern encryption

---

## 📊 Monitoring and Logging

This section covers comprehensive monitoring, logging, and alerting for your VPN infrastructure.

### Monitoring Overview

We'll implement:
1. **Real-time Connection Monitoring** - Track active VPN connections
2. **Log Management** - Centralized logging and rotation
3. **Performance Metrics** - Track bandwidth and system resources
4. **Alert System** - Notifications for important events
5. **Connection History** - Track who connected and when
6. **Traffic Analysis** - Monitor data usage per client

---

## 📈 Step 1: Real-time Connection Monitoring

### 1.1: Create VPN Status Monitoring Script

```bash
mkdir -p ~/wireguard-vpn/scripts
nano ~/wireguard-vpn/scripts/vpn-monitor.sh
```

**Add script content:**

```bash
#!/bin/bash
# WireGuard VPN Real-time Monitor
# Usage: ./vpn-monitor.sh

CONTAINER_NAME="wg-easy"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

clear

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  WireGuard VPN Monitor Dashboard${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if container is running
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo -e "${RED}ERROR: WireGuard container is not running!${NC}"
    exit 1
fi

# Server Information
echo -e "${GREEN}[SERVER INFORMATION]${NC}"
echo "Container Status: $(docker inspect -f '{{.State.Status}}' $CONTAINER_NAME)"
echo "Container Uptime: $(docker inspect -f '{{.State.StartedAt}}' $CONTAINER_NAME | cut -d'T' -f1)"
echo "Server VPN IP: 10.13.13.1"
echo "Public Endpoint: $(grep WG_HOST ~/wireguard-vpn/docker-compose.yml | cut -d'=' -f2)"
echo ""

# WireGuard Interface Status
echo -e "${GREEN}[WIREGUARD INTERFACE]${NC}"
docker exec $CONTAINER_NAME wg show wg0 | head -5
echo ""

# Connected Peers
echo -e "${GREEN}[CONNECTED CLIENTS]${NC}"
PEER_COUNT=$(docker exec $CONTAINER_NAME wg show wg0 peers 2>/dev/null | wc -l)
echo "Total Configured Peers: $PEER_COUNT"
echo ""

if [ $PEER_COUNT -gt 0 ]; then
    echo -e "${YELLOW}Active Connections:${NC}"
    docker exec $CONTAINER_NAME wg show wg0 dump | tail -n +2 | while IFS=$'\t' read -r public_key preshared_key endpoint allowed_ips latest_handshake transfer_rx transfer_tx persistent_keepalive; do
        if [ "$latest_handshake" != "0" ]; then
            # Calculate time since last handshake
            current_time=$(date +%s)
            time_diff=$((current_time - latest_handshake))
            
            # Consider active if handshake within last 3 minutes
            if [ $time_diff -lt 180 ]; then
                status="${GREEN}ACTIVE${NC}"
                
                # Convert bytes to human readable
                rx_mb=$((transfer_rx / 1048576))
                tx_mb=$((transfer_tx / 1048576))
                
                echo -e "  ${status}"
                echo "    Public Key: ${public_key:0:20}..."
                echo "    Endpoint: $endpoint"
                echo "    Last Seen: ${time_diff}s ago"
                echo "    Downloaded: ${rx_mb} MB"
                echo "    Uploaded: ${tx_mb} MB"
                echo ""
            fi
        fi
    done
else
    echo -e "${YELLOW}No clients configured yet.${NC}"
fi

# System Resources
echo -e "${GREEN}[SYSTEM RESOURCES]${NC}"
echo "CPU Usage: $(docker stats --no-stream --format "{{.CPUPerc}}" $CONTAINER_NAME)"
echo "Memory Usage: $(docker stats --no-stream --format "{{.MemUsage}}" $CONTAINER_NAME)"
echo ""

# Network Statistics
echo -e "${GREEN}[NETWORK STATISTICS]${NC}"
echo "Listening Port: 51820/UDP"
echo "Active Connections:"
sudo ss -unp | grep -c ":51820" || echo "0"
echo ""

# Recent Log Entries
echo -e "${GREEN}[RECENT LOG ENTRIES]${NC}"
docker logs $CONTAINER_NAME --tail 5 2>&1 | tail -5
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "Last Updated: $(date)"
echo -e "${BLUE}========================================${NC}"
```

**Make executable:**
```bash
chmod +x ~/wireguard-vpn/scripts/vpn-monitor.sh
```

**Run monitor:**
```bash
~/wireguard-vpn/scripts/vpn-monitor.sh
```

### 1.2: Create Continuous Monitoring Script

```bash
nano ~/wireguard-vpn/scripts/vpn-watch.sh
```

**Add content:**

```bash
#!/bin/bash
# Continuous VPN Monitoring (auto-refresh every 5 seconds)

REFRESH_INTERVAL=5

while true; do
    ~/wireguard-vpn/scripts/vpn-monitor.sh
    echo ""
    echo "Refreshing in ${REFRESH_INTERVAL} seconds... (Press Ctrl+C to exit)"
    sleep $REFRESH_INTERVAL
done
```

**Make executable:**
```bash
chmod +x ~/wireguard-vpn/scripts/vpn-watch.sh
```

**Run continuous monitor:**
```bash
~/wireguard-vpn/scripts/vpn-watch.sh
```

---

## 📝 Step 2: Log Management

### 2.1: Configure Centralized Logging

**Create logging directory structure:**
```bash
mkdir -p ~/wireguard-vpn/logs/{wireguard,system,access,security}
```

**Set up log rotation:**
```bash
sudo nano /etc/logrotate.d/wireguard-vpn
```

**Add configuration:**
```bash
/home/YOUR-USERNAME/wireguard-vpn/logs/*/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 YOUR-USERNAME YOUR-USERNAME
    sharedscripts
    postrotate
        docker restart wg-easy > /dev/null 2>&1 || true
    endscript
}

/var/log/wireguard.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    missingok
    create 0640 syslog adm
}
```

**Replace YOUR-USERNAME with your actual username!**

**Test logrotate configuration:**
```bash
sudo logrotate -d /etc/logrotate.d/wireguard-vpn
```

### 2.2: Create Log Collection Script

```bash
nano ~/wireguard-vpn/scripts/collect-logs.sh
```

**Add script:**

```bash
#!/bin/bash
# Collect and organize VPN logs

LOG_DIR=~/wireguard-vpn/logs
DATE=$(date +%Y%m%d)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "Collecting VPN logs..."

# WireGuard container logs
echo "- Collecting WireGuard logs..."
docker logs wg-easy > "${LOG_DIR}/wireguard/wireguard-${DATE}.log" 2>&1

# System logs related to VPN
echo "- Collecting system logs..."
sudo journalctl -u docker -n 1000 > "${LOG_DIR}/system/docker-${DATE}.log" 2>&1

# UFW logs (firewall)
echo "- Collecting firewall logs..."
sudo grep -i "wireguard\|51820" /var/log/ufw.log > "${LOG_DIR}/security/ufw-${DATE}.log" 2>&1 || true

# Fail2ban logs
echo "- Collecting fail2ban logs..."
sudo grep -i "ban\|unban" /var/log/fail2ban.log > "${LOG_DIR}/security/fail2ban-${DATE}.log" 2>&1 || true

# SSH authentication logs
echo "- Collecting SSH auth logs..."
sudo grep -i "sshd.*accept\|sshd.*fail" /var/log/auth.log > "${LOG_DIR}/access/ssh-${DATE}.log" 2>&1 || true

# Connection statistics
echo "- Generating connection stats..."
docker exec wg-easy wg show wg0 dump > "${LOG_DIR}/wireguard/connections-${TIMESTAMP}.dump" 2>&1

echo ""
echo "Logs collected in: ${LOG_DIR}"
echo "Latest logs:"
ls -lh ${LOG_DIR}/*/*.log | tail -10
```

**Make executable and run:**
```bash
chmod +x ~/wireguard-vpn/scripts/collect-logs.sh
~/wireguard-vpn/scripts/collect-logs.sh
```

**Schedule daily log collection:**
```bash
crontab -e

# Add this line (runs at 11:59 PM daily):
59 23 * * * ~/wireguard-vpn/scripts/collect-logs.sh > /dev/null 2>&1
```

### 2.3: Log Analysis Script

```bash
nano ~/wireguard-vpn/scripts/analyze-logs.sh
```

**Add content:**

```bash
#!/bin/bash
# Analyze VPN logs for insights

LOG_DIR=~/wireguard-vpn/logs
LATEST_LOG="${LOG_DIR}/wireguard/$(ls -t ${LOG_DIR}/wireguard/*.log 2>/dev/null | head -1 | xargs basename)"

echo "========================================"
echo "VPN Log Analysis Report"
echo "Date: $(date)"
echo "========================================"
echo ""

if [ ! -f "$LATEST_LOG" ]; then
    echo "No logs found!"
    exit 1
fi

# Connection attempts
echo "[CONNECTION STATISTICS]"
echo "Total log entries: $(wc -l < "$LATEST_LOG")"
echo ""

# Docker container restarts
echo "[CONTAINER HEALTH]"
echo "Container restarts today: $(grep -c "Starting" "$LATEST_LOG" 2>/dev/null || echo "0")"
echo "Errors logged: $(grep -ci "error" "$LATEST_LOG" 2>/dev/null || echo "0")"
echo "Warnings logged: $(grep -ci "warn" "$LATEST_LOG" 2>/dev/null || echo "0")"
echo ""

# Firewall activity
echo "[FIREWALL ACTIVITY]"
if [ -f "${LOG_DIR}/security/ufw-$(date +%Y%m%d).log" ]; then
    UFW_LOG="${LOG_DIR}/security/ufw-$(date +%Y%m%d).log"
    echo "Blocked packets: $(wc -l < "$UFW_LOG")"
    echo "Top 5 blocked IPs:"
    grep "SRC=" "$UFW_LOG" 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i~/^SRC=/) print $i}' | sort | uniq -c | sort -rn | head -5 || echo "None"
else
    echo "No firewall logs for today"
fi
echo ""

# Fail2ban activity
echo "[INTRUSION PREVENTION]"
if [ -f "${LOG_DIR}/security/fail2ban-$(date +%Y%m%d).log" ]; then
    F2B_LOG="${LOG_DIR}/security/fail2ban-$(date +%Y%m%d).log"
    echo "IPs banned today: $(grep -c "Ban" "$F2B_LOG" 2>/dev/null || echo "0")"
    echo "IPs unbanned today: $(grep -c "Unban" "$F2B_LOG" 2>/dev/null || echo "0")"
    if grep -q "Ban" "$F2B_LOG" 2>/dev/null; then
        echo ""
        echo "Banned IPs:"
        grep "Ban" "$F2B_LOG" | awk '{print $NF}' | sort -u
    fi
else
    echo "No fail2ban logs for today"
fi
echo ""

echo "========================================"
echo "Analysis Complete"
echo "========================================"
```

**Make executable:**
```bash
chmod +x ~/wireguard-vpn/scripts/analyze-logs.sh
```

**Run analysis:**
```bash
~/wireguard-vpn/scripts/analyze-logs.sh
```

---

## 🔔 Step 3: Alert System

### 3.1: Create Alert Script

```bash
nano ~/wireguard-vpn/scripts/vpn-alerts.sh
```

**Add script:**

```bash
#!/bin/bash
# VPN Alert System
# Checks VPN health and sends alerts

ALERT_LOG=~/wireguard-vpn/logs/alerts.log
CONTAINER_NAME="wg-easy"

# Function to log alerts
log_alert() {
    local level=$1
    local message=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$ALERT_LOG"
    echo "[$level] $message"
}

# Function to send notification (customize based on your needs)
send_notification() {
    local message=$1
    
    # Option 1: Log to file (always done)
    log_alert "ALERT" "$message"
    
    # Option 2: Send email (if configured)
    # echo "$message" | mail -s "VPN Alert" your-email@example.com
    
    # Option 3: Send to webhook (Slack, Discord, etc.)
    # curl -X POST -H 'Content-type: application/json' \
    #   --data "{\"text\":\"$message\"}" \
    #   YOUR_WEBHOOK_URL
    
    # Option 4: System notification
    # notify-send "VPN Alert" "$message"
}

# Check 1: Container running
if ! docker ps | grep -q $CONTAINER_NAME; then
    send_notification "CRITICAL: WireGuard container is not running!"
    exit 1
fi

# Check 2: Container health
CONTAINER_STATUS=$(docker inspect -f '{{.State.Health.Status}}' $CONTAINER_NAME 2>/dev/null)
if [ "$CONTAINER_STATUS" == "unhealthy" ]; then
    send_notification "WARNING: WireGuard container is unhealthy!"
fi

# Check 3: Network interface
if ! docker exec $CONTAINER_NAME ip link show wg0 &>/dev/null; then
    send_notification "CRITICAL: WireGuard interface (wg0) is down!"
fi

# Check 4: Port listening
if ! sudo ss -ulnp | grep -q ":51820"; then
    send_notification "CRITICAL: WireGuard is not listening on port 51820!"
fi

# Check 5: Disk space
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    send_notification "WARNING: Disk usage is at ${DISK_USAGE}%!"
fi

# Check 6: Memory usage
MEM_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
if [ "$MEM_USAGE" -gt 90 ]; then
    send_notification "WARNING: Memory usage is at ${MEM_USAGE}%!"
fi

# Check 7: DuckDNS status
DUCK_LOG=~/duckdns/duck.log
if [ -f "$DUCK_LOG" ]; then
    LAST_UPDATE=$(tail -1 "$DUCK_LOG")
    if [[ "$LAST_UPDATE" != *"OK"* ]]; then
        send_notification "WARNING: DuckDNS update failed!"
    fi
fi

# Check 8: Failed login attempts
FAILED_LOGINS=$(sudo grep "Failed password" /var/log/auth.log | grep "$(date '+%b %e')" | wc -l)
if [ "$FAILED_LOGINS" -gt 10 ]; then
    send_notification "WARNING: $FAILED_LOGINS failed SSH login attempts today!"
fi

log_alert "INFO" "Health check completed - All systems operational"
```

**Make executable:**
```bash
chmod +x ~/wireguard-vpn/scripts/vpn-alerts.sh
```

**Test alerts:**
```bash
~/wireguard-vpn/scripts/vpn-alerts.sh
```

**Schedule regular checks (every 15 minutes):**
```bash
crontab -e

# Add:
*/15 * * * * ~/wireguard-vpn/scripts/vpn-alerts.sh > /dev/null 2>&1
```

### 3.2: Configure Email Alerts (Optional)

**Install mail utilities:**
```bash
sudo apt update
sudo apt install -y mailutils
```

**Configure postfix (simple local delivery):**
```bash
sudo dpkg-reconfigure postfix
# Select: Local only
# System mail name: (your hostname)
# Accept defaults for other options
```

**Test email:**
```bash
echo "Test email from VPN server" | mail -s "Test Alert" your-email@example.com
```

**Uncomment email section in vpn-alerts.sh to enable email notifications.**

### 3.3: Webhook Integration (Discord/Slack)

**For Discord:**

```bash
# Get webhook URL from Discord:
# Server Settings → Integrations → Webhooks → New Webhook

# Test Discord notification:
DISCORD_WEBHOOK="YOUR_DISCORD_WEBHOOK_URL"

curl -X POST -H 'Content-type: application/json' \
  --data '{"content":"VPN Server Alert: Test notification"}' \
  "$DISCORD_WEBHOOK"
```

**For Slack:**

```bash
# Get webhook URL from Slack:
# Apps → Incoming Webhooks → Add to Slack

# Test Slack notification:
SLACK_WEBHOOK="YOUR_SLACK_WEBHOOK_URL"

curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"VPN Server Alert: Test notification"}' \
  "$SLACK_WEBHOOK"
```

**Add to vpn-alerts.sh in send_notification function.**

---

## 📊 Step 4: Connection History Tracking

### 4.1: Create Connection Logger

```bash
nano ~/wireguard-vpn/scripts/log-connections.sh
```

**Add script:**

```bash
#!/bin/bash
# Log VPN connection history

HISTORY_FILE=~/wireguard-vpn/logs/connection-history.csv
CONTAINER_NAME="wg-easy"

# Create header if file doesn't exist
if [ ! -f "$HISTORY_FILE" ]; then
    echo "Timestamp,Client_PublicKey,Endpoint,Status,Data_Received_MB,Data_Sent_MB" > "$HISTORY_FILE"
fi

# Get current connections
docker exec $CONTAINER_NAME wg show wg0 dump | tail -n +2 | while IFS=$'\t' read -r public_key preshared_key endpoint allowed_ips latest_handshake transfer_rx transfer_tx persistent_keepalive; do
    
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    rx_mb=$((transfer_rx / 1048576))
    tx_mb=$((transfer_tx / 1048576))
    
    # Check if active (handshake within last 3 minutes)
    if [ "$latest_handshake" != "0" ]; then
        current_time=$(date +%s)
        time_diff=$((current_time - latest_handshake))
        
        if [ $time_diff -lt 180 ]; then
            status="ACTIVE"
        else
            status="IDLE"
        fi
    else
        status="NEVER_CONNECTED"
    fi
    
    # Log to CSV
    echo "$timestamp,${public_key:0:20}...$endpoint,$status,$rx_mb,$tx_mb" >> "$HISTORY_FILE"
done
```

**Make executable:**
```bash
chmod +x ~/wireguard-vpn/scripts/log-connections.sh
```

**Schedule logging (every 5 minutes):**
```bash
crontab -e

# Add:
*/5 * * * * ~/wireguard-vpn/scripts/log-connections.sh > /dev/null 2>&1
```

### 4.2: Create Connection Report Generator

```bash
nano ~/wireguard-vpn/scripts/connection-report.sh
```

**Add script:**

```bash
#!/bin/bash
# Generate connection history report

HISTORY_FILE=~/wireguard-vpn/logs/connection-history.csv

if [ ! -f "$HISTORY_FILE" ]; then
    echo "No connection history found!"
    exit 1
fi

echo "========================================"
echo "VPN Connection History Report"
echo "Date: $(date)"
echo "========================================"
echo ""

# Total entries
echo "[STATISTICS]"
echo "Total log entries: $(wc -l < "$HISTORY_FILE")"
echo "First entry: $(head -2 "$HISTORY_FILE" | tail -1 | cut -d',' -f1)"
echo "Last entry: $(tail -1 "$HISTORY_FILE" | cut -d',' -f1)"
echo ""

# Active connections today
echo "[TODAY'S ACTIVITY]"
TODAY=$(date '+%Y-%m-%d')
TODAY_CONNECTIONS=$(grep "$TODAY" "$HISTORY_FILE" | grep "ACTIVE" | wc -l)
echo "Active connection records today: $TODAY_CONNECTIONS"
echo ""

# Unique clients
echo "[CONNECTED CLIENTS]"
echo "Unique clients seen:"
tail -n +2 "$HISTORY_FILE" | cut -d',' -f2 | sort -u | nl
echo ""

# Data usage summary
echo "[DATA USAGE - Last 24 Hours]"
YESTERDAY=$(date -d '1 day ago' '+%Y-%m-%d' 2>/dev/null || date -v-1d '+%Y-%m-%d')
tail -n +2 "$HISTORY_FILE" | awk -F',' -v today="$TODAY" -v yesterday="$YESTERDAY" '
$1 ~ today || $1 ~ yesterday {
    rx += $5
    tx += $6
}
END {
    printf "Total Downloaded: %.2f GB\n", rx/1024
    printf "Total Uploaded: %.2f GB\n", tx/1024
    printf "Total Traffic: %.2f GB\n", (rx+tx)/1024
}'
echo ""

echo "========================================"
echo "Full history available at:"
echo "$HISTORY_FILE"
echo "========================================"
```

**Make executable and run:**
```bash
chmod +x ~/wireguard-vpn/scripts/connection-report.sh
~/wireguard-vpn/scripts/connection-report.sh
```

---

## 📈 Step 5: Performance Metrics

### 5.1: Create Performance Monitoring Script

```bash
nano ~/wireguard-vpn/scripts/performance-monitor.sh
```

**Add script:**

```bash
#!/bin/bash
# Monitor VPN server performance

METRICS_LOG=~/wireguard-vpn/logs/performance-metrics.csv
CONTAINER_NAME="wg-easy"

# Create header if needed
if [ ! -f "$METRICS_LOG" ]; then
    echo "Timestamp,CPU_Percent,Memory_MB,Memory_Percent,Network_RX_MB,Network_TX_MB,Disk_Percent,Load_1m,Load_5m,Load_15m" > "$METRICS_LOG"
fi

# Gather metrics
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# Container metrics
container_stats=$(docker stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}}" $CONTAINER_NAME)
cpu_percent=$(echo $container_stats | cut -d',' -f1 | sed 's/%//')
mem_usage=$(echo $container_stats | cut -d',' -f2 | cut -d'/' -f1 | sed 's/MiB//')
mem_percent=$(docker stats --no-stream --format "{{.MemPerc}}" $CONTAINER_NAME | sed 's/%//')

# Network stats (WireGuard interface)
if docker exec $CONTAINER_NAME ip -s link show wg0 &>/dev/null; then
    net_stats=$(docker exec $CONTAINER_NAME ip -s link show wg0 | grep -A 1 "RX:" | tail -1 | awk '{print $1}')
    net_rx_mb=$((net_stats / 1048576))
    net_stats=$(docker exec $CONTAINER_NAME ip -s link show wg0 | grep -A 1 "TX:" | tail -1 | awk '{print $1}')
    net_tx_mb=$((net_stats / 1048576))
else
    net_rx_mb=0
    net_tx_mb=0
fi

# Disk usage
disk_percent=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

# System load
load=$(uptime | awk -F'load average:' '{print $2}' | sed 's/ //g')
load_1m=$(echo $load | cut -d',' -f1)
load_5m=$(echo $load | cut -d',' -f2)
load_15m=$(echo $load | cut -d',' -f3)

# Log metrics
echo "$timestamp,$cpu_percent,$mem_usage,$mem_percent,$net_rx_mb,$net_tx_mb,$disk_percent,$load_1m,$load_5m,$load_15m" >> "$METRICS_LOG"
```

**Make executable:**
```bash
chmod +x ~/wireguard-vpn/scripts/performance-monitor.sh
```

**Schedule monitoring (every 5 minutes):**
```bash
crontab -e

# Add:
*/5 * * * * ~/wireguard-vpn/scripts/performance-monitor.sh > /dev/null 2>&1
```

### 5.2: Performance Report Generator

```bash
nano ~/wireguard-vpn/scripts/performance-report.sh
```

**Add script:**

```bash
#!/bin/bash
# Generate performance report

METRICS_LOG=~/wireguard-vpn/logs/performance-metrics.csv

if [ ! -f "$METRICS_LOG" ]; then
    echo "No performance metrics found!"
    exit 1
fi

echo "========================================"
echo "VPN Performance Report - Last 24 Hours"
echo "Date: $(date)"
echo "========================================"
echo ""

# Get data from last 24 hours
YESTERDAY=$(date -d '1 day ago' '+%Y-%m-%d' 2>/dev/null || date -v-1d '+%Y-%m-%d')
TODAY=$(date '+%Y-%m-%d')

tail -n +2 "$METRICS_LOG" | awk -F',' -v today="$TODAY" -v yesterday="$YESTERDAY" '
$1 ~ today || $1 ~ yesterday {
    count++
    cpu_sum += $2
    mem_sum += $4
    disk_sum += $7
    
    if ($2 > cpu_max) cpu_max = $2
    if ($4 > mem_max) mem_max = $4
    if ($7 > disk_max) disk_max = $7
    
    if (count == 1 || $2 < cpu_min) cpu_min = $2
    if (count == 1 || $4 < mem_min) mem_min = $4
}
END {
    if (count > 0) {
        printf "[CPU USAGE]\n"
        printf "Average: %.2f%%\n", cpu_sum/count
        printf "Maximum: %.2f%%\n", cpu_max
        printf "Minimum: %.2f%%\n\n", cpu_min
        
        printf "[MEMORY USAGE]\n"
        printf "Average: %.2f%%\n", mem_sum/count
        printf "Maximum: %.2f%%\n", mem_max
        printf "Minimum: %.2f%%\n\n", mem_min
        
        printf "[DISK USAGE]\n"
        printf "Average: %.2f%%\n", disk_sum/count
        printf "Current: %.2f%%\n\n", disk_max
    } else {
        print "No data for selected period"
    }
}'

# Latest metrics
echo "[CURRENT STATUS]"
tail -1 "$METRICS_LOG" | awk -F',' '{
    printf "Timestamp: %s\n", $1
    printf "CPU: %s%%\n", $2
    printf "Memory: %s MB (%s%%)\n", $3, $4
    printf "Disk: %s%%\n", $7
    printf "Load: %s, %s, %s\n", $8, $9, $10
}'

echo ""
echo "========================================"
```

**Make executable and run:**
```bash
chmod +x ~/wireguard-vpn/scripts/performance-report.sh
~/wireguard-vpn/scripts/performance-report.sh
```

---

## 🎯 Step 6: Unified Dashboard Script

Create a comprehensive dashboard that shows everything:

```bash
nano ~/wireguard-vpn/scripts/dashboard.sh
```

**Add script:**

```bash
#!/bin/bash
# VPN Complete Dashboard

clear

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        WireGuard VPN - Complete Dashboard                  ║"
echo "║        $(date '+%Y-%m-%d %H:%M:%S')                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Run all monitoring scripts
echo "📊 Running comprehensive analysis..."
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
~/wireguard-vpn/scripts/vpn-monitor.sh
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
~/wireguard-vpn/scripts/performance-report.sh 2>/dev/null
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
~/wireguard-vpn/scripts/connection-report.sh 2>/dev/null
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 SECURITY STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo fail2ban-client status sshd 2>/dev/null | grep "Currently banned" || echo "Fail2ban: No bans"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 LOG FILES SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Recent logs:"
ls -lht ~/wireguard-vpn/logs/*/*.log 2>/dev/null | head -5 || echo "No logs yet"
echo ""

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Dashboard Complete - $(date '+%H:%M:%S')                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
```

**Make executable:**
```bash
chmod +x ~/wireguard-vpn/scripts/dashboard.sh
```

**Run dashboard:**
```bash
~/wireguard-vpn/scripts/dashboard.sh
```

**Create alias for easy access:**
```bash
echo "alias vpn-dashboard='~/wireguard-vpn/scripts/dashboard.sh'" >> ~/.bashrc
source ~/.bashrc

# Now you can just run:
vpn-dashboard
```

---

**✅ Monitoring and Logging Complete!**

You should now have:
- ✅ Real-time connection monitoring
- ✅ Comprehensive log collection and rotation
- ✅ Automated log analysis
- ✅ Alert system with multiple notification options
- ✅ Connection history tracking
- ✅ Performance metrics monitoring
- ✅ Unified dashboard for all metrics

**Monitoring Features:**
- 📊 Real-time VPN status tracking
- 📝 Centralized log management with 30-day rotation
- 🔔 Automated health checks every 15 minutes
- 📈 Performance metrics collected every 5 minutes
- 📱 Alert notifications (email/webhook supported)
- 📊 Connection history with data usage tracking
- 🎯 Unified dashboard showing all metrics

**All scripts created:**
1. `vpn-monitor.sh` - Real-time VPN status
2. `vpn-watch.sh` - Continuous monitoring
3. `collect-logs.sh` - Daily log collection
4. `analyze-logs.sh` - Log analysis
5. `vpn-alerts.sh` - Health checks and alerts
6. `log-connections.sh` - Connection history tracking
7. `connection-report.sh` - Connection reports
8. `performance-monitor.sh` - Performance metrics
9. `performance-report.sh` - Performance reports
10. `dashboard.sh` - Unified dashboard

---

## 💾 Backup and Disaster Recovery

This section covers comprehensive backup strategies and disaster recovery procedures.

### Backup Strategy Overview

We'll implement:
1. **Configuration Backups** - WireGuard configs, keys, client data
2. **Automated Daily Backups** - Scheduled backup scripts
3. **Encrypted Backups** - GPG encryption for sensitive data
4. **Verification Procedures** - Ensure backups are valid
5. **Restoration Procedures** - Step-by-step recovery
6. **Off-site Backups** - Cloud/external storage options

---

## 📦 Step 1: Manual Backup Procedures

### 1.1: Create Comprehensive Backup Script

```bash
nano ~/wireguard-vpn/scripts/backup-vpn.sh
```

**Add script:**

```bash
#!/bin/bash
# WireGuard VPN Complete Backup Script

# Configuration
BACKUP_ROOT=~/wireguard-vpn/backups
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_ROOT}/backup-${DATE}"
CONTAINER_NAME="wg-easy"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}WireGuard VPN Backup Script${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""

# Create backup directory
echo -e "${YELLOW}Creating backup directory...${NC}"
mkdir -p "$BACKUP_DIR"/{config,data,scripts,logs,system}

# 1. Backup WireGuard configuration and data
echo -e "${YELLOW}Backing up WireGuard configuration...${NC}"
if docker ps | grep -q $CONTAINER_NAME; then
    # Stop container temporarily for consistent backup
    echo "  Stopping WireGuard container..."
    docker compose -f ~/wireguard-vpn/docker-compose.yml down > /dev/null 2>&1
    
    # Copy configuration files
    cp -r ~/wireguard-vpn/config/* "$BACKUP_DIR/config/" 2>/dev/null || true
    cp -r ~/wireguard-vpn/data/* "$BACKUP_DIR/data/" 2>/dev/null || true
    
    # Restart container
    echo "  Restarting WireGuard container..."
    docker compose -f ~/wireguard-vpn/docker-compose.yml up -d > /dev/null 2>&1
else
    echo "  Container not running, backing up files..."
    cp -r ~/wireguard-vpn/config/* "$BACKUP_DIR/config/" 2>/dev/null || true
    cp -r ~/wireguard-vpn/data/* "$BACKUP_DIR/data/" 2>/dev/null || true
fi

# 2. Backup docker-compose.yml
echo -e "${YELLOW}Backing up docker-compose configuration...${NC}"
cp ~/wireguard-vpn/docker-compose.yml "$BACKUP_DIR/docker-compose.yml"

# 3. Backup scripts
echo -e "${YELLOW}Backing up scripts...${NC}"
cp -r ~/wireguard-vpn/scripts/* "$BACKUP_DIR/scripts/" 2>/dev/null || true

# 4. Backup logs (last 7 days only)
echo -e "${YELLOW}Backing up recent logs...${NC}"
find ~/wireguard-vpn/logs -type f -mtime -7 -exec cp --parents {} "$BACKUP_DIR/logs/" \; 2>/dev/null || true

# 5. Backup system configuration
echo -e "${YELLOW}Backing up system configuration...${NC}"

# SSH configuration
sudo cp /etc/ssh/sshd_config "$BACKUP_DIR/system/sshd_config" 2>/dev/null

# UFW rules
sudo ufw status verbose > "$BACKUP_DIR/system/ufw-rules.txt" 2>/dev/null
sudo cp /etc/ufw/before.rules "$BACKUP_DIR/system/ufw-before.rules" 2>/dev/null

# Fail2ban configuration
sudo cp /etc/fail2ban/jail.local "$BACKUP_DIR/system/fail2ban-jail.local" 2>/dev/null || true

# Network configuration
sudo cp /etc/netplan/*.yaml "$BACKUP_DIR/system/" 2>/dev/null || true

# DuckDNS configuration
cp ~/duckdns/duck.sh "$BACKUP_DIR/system/duckdns.sh" 2>/dev/null || true

# Crontab
crontab -l > "$BACKUP_DIR/system/crontab.txt" 2>/dev/null || true

# 6. Create backup manifest
echo -e "${YELLOW}Creating backup manifest...${NC}"
cat > "$BACKUP_DIR/MANIFEST.txt" << EOF
WireGuard VPN Backup Manifest
==============================
Backup Date: $(date)
Backup Directory: $BACKUP_DIR
Hostname: $(hostname)
Server IP: $(ip addr show | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')

Contents:
---------
- config/          : WireGuard configuration files and keys
- data/            : WireGuard persistent data
- scripts/         : Monitoring and management scripts
- logs/            : Recent log files (last 7 days)
- system/          : System configuration files
- docker-compose.yml : Docker Compose configuration

Files Backed Up: $(find "$BACKUP_DIR" -type f | wc -l)
Total Size: $(du -sh "$BACKUP_DIR" | cut -f1)

Restoration:
------------
To restore this backup, run:
  ~/wireguard-vpn/scripts/restore-vpn.sh $BACKUP_DIR
EOF

# 7. Calculate checksums
echo -e "${YELLOW}Calculating checksums...${NC}"
find "$BACKUP_DIR" -type f -exec sha256sum {} \; > "$BACKUP_DIR/checksums.txt"

# 8. Display summary
echo ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}Backup completed successfully!${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""
echo "Backup Location: $BACKUP_DIR"
echo "Total Files: $(find "$BACKUP_DIR" -type f | wc -l)"
echo "Backup Size: $(du -sh "$BACKUP_DIR" | cut -f1)"
echo ""
echo "To create encrypted archive:"
echo "  cd $BACKUP_ROOT"
echo "  tar czf backup-${DATE}.tar.gz backup-${DATE}"
echo "  gpg -c backup-${DATE}.tar.gz"
echo ""

# Return backup directory path
echo "$BACKUP_DIR"
```

**Make executable:**
```bash
chmod +x ~/wireguard-vpn/scripts/backup-vpn.sh
```

**Run backup:**
```bash
~/wireguard-vpn/scripts/backup-vpn.sh
```

### 1.2: Create Encrypted Backup

**After running backup script:**

```bash
# Navigate to backups directory
cd ~/wireguard-vpn/backups

# Find latest backup
LATEST_BACKUP=$(ls -td backup-* | head -1)

# Create compressed archive
tar czf "${LATEST_BACKUP}.tar.gz" "$LATEST_BACKUP"

# Encrypt with GPG
gpg -c "${LATEST_BACKUP}.tar.gz"
# Enter a strong passphrase when prompted
# Remember this passphrase - you'll need it for restoration!

# Verify encrypted file created
ls -lh "${LATEST_BACKUP}.tar.gz.gpg"

# Remove unencrypted archive (keep encrypted only)
rm "${LATEST_BACKUP}.tar.gz"

echo "Encrypted backup created: ${LATEST_BACKUP}.tar.gz.gpg"
```

---

## 🔄 Step 2: Automated Backup System

### 2.1: Create Automated Backup Script

```bash
nano ~/wireguard-vpn/scripts/auto-backup.sh
```

**Add script:**

```bash
#!/bin/bash
# Automated VPN Backup with Encryption and Cleanup

BACKUP_ROOT=~/wireguard-vpn/backups
RETENTION_DAYS=30  # Keep backups for 30 days
GPG_PASSPHRASE_FILE=~/wireguard-vpn/.backup-passphrase  # Store passphrase securely

# Create backup
echo "[$(date)] Starting automated backup..."
BACKUP_DIR=$(~/wireguard-vpn/scripts/backup-vpn.sh | tail -1)

if [ -d "$BACKUP_DIR" ]; then
    BACKUP_NAME=$(basename "$BACKUP_DIR")
    
    # Create compressed archive
    echo "[$(date)] Creating archive..."
    cd "$BACKUP_ROOT"
    tar czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
    
    # Encrypt if passphrase file exists
    if [ -f "$GPG_PASSPHRASE_FILE" ]; then
        echo "[$(date)] Encrypting backup..."
        gpg --batch --yes --passphrase-file "$GPG_PASSPHRASE_FILE" -c "${BACKUP_NAME}.tar.gz"
        rm "${BACKUP_NAME}.tar.gz"
        echo "[$(date)] Encrypted backup created: ${BACKUP_NAME}.tar.gz.gpg"
    else
        echo "[$(date)] Warning: No passphrase file found, backup not encrypted"
    fi
    
    # Remove uncompressed backup directory
    rm -rf "$BACKUP_DIR"
    
    # Cleanup old backups
    echo "[$(date)] Cleaning up old backups (older than ${RETENTION_DAYS} days)..."
    find "$BACKUP_ROOT" -name "backup-*.tar.gz.gpg" -mtime +${RETENTION_DAYS} -delete
    find "$BACKUP_ROOT" -name "backup-*.tar.gz" -mtime +${RETENTION_DAYS} -delete
    
    echo "[$(date)] Automated backup completed successfully"
else
    echo "[$(date)] ERROR: Backup failed!"
    exit 1
fi
```

**Make executable:**
```bash
chmod +x ~/wireguard-vpn/scripts/auto-backup.sh
```

**Set up passphrase file (IMPORTANT - Secure this!):**

```bash
# Create secure passphrase file
nano ~/wireguard-vpn/.backup-passphrase
# Enter a strong passphrase (single line, no quotes)
# Save and exit

# Secure the passphrase file
chmod 600 ~/wireguard-vpn/.backup-passphrase

# IMPORTANT: Back up this passphrase to a password manager!
# You'll need it to decrypt backups!
```

**Test automated backup:**
```bash
~/wireguard-vpn/scripts/auto-backup.sh
```

### 2.2: Schedule Automated Backups

```bash
crontab -e
```

**Add daily backup at 2 AM:**
```bash
# Daily VPN backup at 2:00 AM
0 2 * * * ~/wireguard-vpn/scripts/auto-backup.sh >> ~/wireguard-vpn/logs/backup.log 2>&1

# Weekly verification on Sundays at 3 AM
0 3 * * 0 ~/wireguard-vpn/scripts/verify-backup.sh >> ~/wireguard-vpn/logs/backup-verify.log 2>&1
```

---

## ✅ Step 3: Backup Verification

### 3.1: Create Verification Script

```bash
nano ~/wireguard-vpn/scripts/verify-backup.sh
```

**Add script:**

```bash
#!/bin/bash
# Verify backup integrity

BACKUP_ROOT=~/wireguard-vpn/backups
VERIFY_DIR="${BACKUP_ROOT}/verify-tmp"

echo "======================================="
echo "Backup Verification"
echo "Date: $(date)"
echo "======================================="
echo ""

# Find latest encrypted backup
LATEST_BACKUP=$(ls -t "$BACKUP_ROOT"/backup-*.tar.gz.gpg 2>/dev/null | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    # Try non-encrypted
    LATEST_BACKUP=$(ls -t "$BACKUP_ROOT"/backup-*.tar.gz 2>/dev/null | head -1)
fi

if [ -z "$LATEST_BACKUP" ]; then
    echo "ERROR: No backups found!"
    exit 1
fi

echo "Latest backup: $(basename "$LATEST_BACKUP")"
echo "Size: $(du -sh "$LATEST_BACKUP" | cut -f1)"
echo "Date: $(date -r "$LATEST_BACKUP" '+%Y-%m-%d %H:%M:%S')"
echo ""

# Create temporary directory
mkdir -p "$VERIFY_DIR"
cd "$VERIFY_DIR"

echo "Verifying backup integrity..."

# Check if encrypted
if [[ "$LATEST_BACKUP" == *.gpg ]]; then
    echo "Backup is encrypted, checking GPG integrity..."
    
    # Check GPG file integrity (without decrypting)
    if gpg --list-packets "$LATEST_BACKUP" > /dev/null 2>&1; then
        echo "✓ GPG encryption is valid"
    else
        echo "✗ GPG file is corrupted!"
        rm -rf "$VERIFY_DIR"
        exit 1
    fi
    
    # Try to decrypt (requires passphrase)
    if [ -f ~/wireguard-vpn/.backup-passphrase ]; then
        echo "Attempting to decrypt backup..."
        gpg --batch --yes --passphrase-file ~/wireguard-vpn/.backup-passphrase \
            -o decrypted.tar.gz "$LATEST_BACKUP" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "✓ Decryption successful"
            ARCHIVE="decrypted.tar.gz"
        else
            echo "✗ Decryption failed!"
            rm -rf "$VERIFY_DIR"
            exit 1
        fi
    else
        echo "⚠ Passphrase file not found, cannot decrypt for full verification"
        rm -rf "$VERIFY_DIR"
        exit 0
    fi
else
    ARCHIVE="$LATEST_BACKUP"
fi

# Verify tar archive
echo "Verifying tar archive integrity..."
if tar tzf "$ARCHIVE" > /dev/null 2>&1; then
    echo "✓ Archive is valid"
else
    echo "✗ Archive is corrupted!"
    rm -rf "$VERIFY_DIR"
    exit 1
fi

# List contents
echo ""
echo "Archive contents:"
tar tzf "$ARCHIVE" | head -20
FILE_COUNT=$(tar tzf "$ARCHIVE" | wc -l)
echo "... total files: $FILE_COUNT"

# Check for critical files
echo ""
echo "Checking for critical files..."
CRITICAL_FILES=(
    "docker-compose.yml"
    "MANIFEST.txt"
    "config/"
    "scripts/"
)

for file in "${CRITICAL_FILES[@]}"; do
    if tar tzf "$ARCHIVE" | grep -q "$file"; then
        echo "✓ $file found"
    else
        echo "✗ $file missing!"
    fi
done

# Cleanup
rm -rf "$VERIFY_DIR"

echo ""
echo "======================================="
echo "Verification completed successfully!"
echo "======================================="
```

**Make executable:**
```bash
chmod +x ~/wireguard-vpn/scripts/verify-backup.sh
```

**Run verification:**
```bash
~/wireguard-vpn/scripts/verify-backup.sh
```

---

## 🔙 Step 4: Restoration Procedures

### 4.1: Create Restoration Script

```bash
nano ~/wireguard-vpn/scripts/restore-vpn.sh
```

**Add script:**

```bash
#!/bin/bash
# WireGuard VPN Restoration Script

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}=======================================${NC}"
echo -e "${RED}WireGuard VPN RESTORATION${NC}"
echo -e "${RED}=======================================${NC}"
echo ""
echo -e "${YELLOW}WARNING: This will restore VPN configuration${NC}"
echo -e "${YELLOW}from backup and may overwrite current setup!${NC}"
echo ""

# Check for backup parameter
if [ -z "$1" ]; then
    echo "Usage: $0 <backup-file-or-directory>"
    echo ""
    echo "Available backups:"
    ls -lht ~/wireguard-vpn/backups/ | grep -E "backup-|\.tar\.gz" | head -10
    exit 1
fi

BACKUP_SOURCE="$1"
RESTORE_TMP=~/wireguard-vpn/restore-tmp

# Confirm restoration
read -p "Are you sure you want to restore from backup? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Restoration cancelled."
    exit 0
fi

echo ""
echo -e "${GREEN}Starting restoration process...${NC}"

# Create temporary restoration directory
mkdir -p "$RESTORE_TMP"
cd "$RESTORE_TMP"

# Determine backup type and extract
if [ -f "$BACKUP_SOURCE" ]; then
    echo -e "${YELLOW}Extracting backup archive...${NC}"
    
    # Check if encrypted
    if [[ "$BACKUP_SOURCE" == *.gpg ]]; then
        echo "Backup is encrypted, decrypting..."
        
        if [ -f ~/wireguard-vpn/.backup-passphrase ]; then
            gpg --batch --passphrase-file ~/wireguard-vpn/.backup-passphrase \
                -o decrypted.tar.gz "$BACKUP_SOURCE"
        else
            gpg -o decrypted.tar.gz "$BACKUP_SOURCE"
        fi
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}ERROR: Decryption failed!${NC}"
            rm -rf "$RESTORE_TMP"
            exit 1
        fi
        
        tar xzf decrypted.tar.gz
    else
        tar xzf "$BACKUP_SOURCE"
    fi
    
    # Find extracted backup directory
    BACKUP_DIR=$(find . -maxdepth 1 -type d -name "backup-*" | head -1)
    
    if [ -z "$BACKUP_DIR" ]; then
        echo -e "${RED}ERROR: Cannot find backup directory in archive!${NC}"
        rm -rf "$RESTORE_TMP"
        exit 1
    fi
elif [ -d "$BACKUP_SOURCE" ]; then
    BACKUP_DIR="$BACKUP_SOURCE"
else
    echo -e "${RED}ERROR: Backup source not found: $BACKUP_SOURCE${NC}"
    exit 1
fi

echo -e "${GREEN}Backup extracted successfully${NC}"
echo ""

# Stop WireGuard container
echo -e "${YELLOW}Stopping WireGuard container...${NC}"
cd ~/wireguard-vpn
docker compose down

# Backup current configuration (just in case)
echo -e "${YELLOW}Creating safety backup of current configuration...${NC}"
SAFETY_BACKUP=~/wireguard-vpn/backups/pre-restore-$(date +%Y%m%d_%H%M%S)
mkdir -p "$SAFETY_BACKUP"
cp -r ~/wireguard-vpn/config "$SAFETY_BACKUP/" 2>/dev/null || true
cp -r ~/wireguard-vpn/data "$SAFETY_BACKUP/" 2>/dev/null || true
cp ~/wireguard-vpn/docker-compose.yml "$SAFETY_BACKUP/" 2>/dev/null || true

# Restore WireGuard configuration
echo -e "${YELLOW}Restoring WireGuard configuration...${NC}"
rm -rf ~/wireguard-vpn/config/*
rm -rf ~/wireguard-vpn/data/*
cp -r "$BACKUP_DIR"/config/* ~/wireguard-vpn/config/ 2>/dev/null || true
cp -r "$BACKUP_DIR"/data/* ~/wireguard-vpn/data/ 2>/dev/null || true

# Restore docker-compose.yml
echo -e "${YELLOW}Restoring docker-compose configuration...${NC}"
cp "$BACKUP_DIR"/docker-compose.yml ~/wireguard-vpn/docker-compose.yml

# Restore scripts
echo -e "${YELLOW}Restoring scripts...${NC}"
cp -r "$BACKUP_DIR"/scripts/* ~/wireguard-vpn/scripts/ 2>/dev/null || true
chmod +x ~/wireguard-vpn/scripts/*.sh

# Ask about system configuration restoration
echo ""
read -p "Restore system configuration (SSH, firewall, etc.)? (yes/no): " RESTORE_SYS

if [ "$RESTORE_SYS" == "yes" ]; then
    echo -e "${YELLOW}Restoring system configuration...${NC}"
    
    # SSH config
    if [ -f "$BACKUP_DIR/system/sshd_config" ]; then
        sudo cp "$BACKUP_DIR/system/sshd_config" /etc/ssh/sshd_config.restored
        echo "  SSH config restored to /etc/ssh/sshd_config.restored"
        echo "  Review and manually replace if needed: sudo mv /etc/ssh/sshd_config.restored /etc/ssh/sshd_config"
    fi
    
    # UFW rules
    if [ -f "$BACKUP_DIR/system/ufw-before.rules" ]; then
        sudo cp "$BACKUP_DIR/system/ufw-before.rules" /etc/ufw/before.rules.restored
        echo "  UFW rules restored to /etc/ufw/before.rules.restored"
    fi
    
    # Fail2ban
    if [ -f "$BACKUP_DIR/system/fail2ban-jail.local" ]; then
        sudo cp "$BACKUP_DIR/system/fail2ban-jail.local" /etc/fail2ban/jail.local.restored
        echo "  Fail2ban config restored to /etc/fail2ban/jail.local.restored"
    fi
    
    # Crontab
    if [ -f "$BACKUP_DIR/system/crontab.txt" ]; then
        cp "$BACKUP_DIR/system/crontab.txt" ~/crontab.restored
        echo "  Crontab restored to ~/crontab.restored"
        echo "  Install with: crontab ~/crontab.restored"
    fi
fi

# Restart WireGuard
echo ""
echo -e "${YELLOW}Starting WireGuard container...${NC}"
cd ~/wireguard-vpn
docker compose up -d

# Wait for container to start
sleep 5

# Verify restoration
echo ""
echo -e "${GREEN}Verifying restoration...${NC}"
if docker ps | grep -q wg-easy; then
    echo "✓ WireGuard container is running"
else
    echo "✗ WireGuard container failed to start!"
    echo "  Check logs: docker compose logs wg-easy"
fi

# Cleanup
rm -rf "$RESTORE_TMP"

echo ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}Restoration completed!${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""
echo "Safety backup of previous config: $SAFETY_BACKUP"
echo ""
echo "Next steps:"
echo "1. Verify VPN is working: docker compose ps"
echo "2. Check Web UI: http://192.168.x.x:51821"
echo "3. Test client connections"
echo "4. Review system configs in $BACKUP_DIR/system/"
echo ""
```

**Make executable:**
```bash
chmod +x ~/wireguard-vpn/scripts/restore-vpn.sh
```

### 4.2: Restoration Examples

**Restore from encrypted backup:**
```bash
# List available backups
ls -lht ~/wireguard-vpn/backups/*.gpg

# Restore from specific backup
~/wireguard-vpn/scripts/restore-vpn.sh ~/wireguard-vpn/backups/backup-20251106_020000.tar.gz.gpg
```

**Restore from uncompressed backup directory:**
```bash
~/wireguard-vpn/scripts/restore-vpn.sh ~/wireguard-vpn/backups/backup-20251106_020000
```

---

## ☁️ Step 5: Off-site Backup Options

### 5.1: Backup to External Drive

```bash
# Mount external drive
sudo mkdir -p /mnt/external
sudo mount /dev/sdb1 /mnt/external  # Adjust device name

# Copy backups
cp ~/wireguard-vpn/backups/*.gpg /mnt/external/vpn-backups/

# Unmount
sudo umount /mnt/external
```

### 5.2: Backup to Cloud Storage (rsync example)

**Using rsync to remote server:**

```bash
nano ~/wireguard-vpn/scripts/cloud-backup.sh
```

**Add script:**

```bash
#!/bin/bash
# Sync backups to remote server

REMOTE_USER="backup-user"
REMOTE_HOST="backup-server.example.com"
REMOTE_PATH="/backups/wireguard-vpn"
LOCAL_BACKUP_DIR=~/wireguard-vpn/backups

# Sync encrypted backups only
rsync -avz --progress \
    --include="*.gpg" \
    --exclude="*" \
    "$LOCAL_BACKUP_DIR/" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/"

echo "Backups synced to remote server"
```

**Make executable:**
```bash
chmod +x ~/wireguard-vpn/scripts/cloud-backup.sh
```

### 5.3: Using rclone for Cloud Storage

**Install rclone:**
```bash
sudo apt install -y rclone
```

**Configure rclone (for Dropbox, Google Drive, etc.):**
```bash
rclone config
# Follow interactive setup for your cloud provider
```

**Create cloud sync script:**
```bash
nano ~/wireguard-vpn/scripts/rclone-backup.sh
```

**Add script:**
```bash
#!/bin/bash
# Sync backups to cloud storage using rclone

REMOTE_NAME="mydrive"  # Name from rclone config
REMOTE_PATH="VPN-Backups"
LOCAL_BACKUP_DIR=~/wireguard-vpn/backups

# Sync encrypted backups
rclone sync "$LOCAL_BACKUP_DIR" "${REMOTE_NAME}:${REMOTE_PATH}" \
    --include="*.gpg" \
    --transfers 4 \
    --checkers 8 \
    --contimeout 60s \
    --timeout 300s \
    --retries 3 \
    --low-level-retries 10 \
    --stats 1s

echo "Backups synced to cloud storage"
```

---

## 🚨 Step 6: Disaster Recovery Scenarios

### Scenario 1: Server Complete Failure

**Recovery steps:**

1. **Install Ubuntu on new server**
2. **Set static IP (192.168.x.x)**
3. **Install Docker:**
```bash
# Follow Docker installation from Prerequisites section
```

4. **Restore VPN:**
```bash
# Copy backup from external/cloud storage
# Run restoration script
~/wireguard-vpn/scripts/restore-vpn.sh /path/to/backup.tar.gz.gpg
```

5. **Verify router port forwarding still points to 192.168.x.x**

### Scenario 2: Corrupted WireGuard Container

**Quick recovery:**
```bash
cd ~/wireguard-vpn

# Stop container
docker compose down

# Remove corrupted data
docker volume prune -f

# Restore from backup
~/wireguard-vpn/scripts/restore-vpn.sh ~/wireguard-vpn/backups/backup-latest.tar.gz.gpg

# Or just restart with existing config
docker compose up -d
```

### Scenario 3: Lost Client Configuration

**Regenerate client:**
1. Access Web UI: http://192.168.x.x:51821
2. Delete old client
3. Create new client with same name
4. Deploy new config to device

**Or restore from backup to get original keys:**
```bash
# Restore just to view old configs
~/wireguard-vpn/scripts/restore-vpn.sh ~/wireguard-vpn/backups/backup-old.tar.gz.gpg
# Access Web UI to export old client configs
# Then restore latest backup
```

### Scenario 4: Forgotten Web UI Password

**Reset password:**
```bash
cd ~/wireguard-vpn

# Edit docker-compose.yml
nano docker-compose.yml

# Change PASSWORD environment variable
# Save and restart
docker compose down
docker compose up -d
```

---

## 📋 Step 7: Backup Checklist and Best Practices

### Daily Backup Checklist

- [✓] Automated backup runs at 2 AM
- [✓] Backup is encrypted with GPG
- [✓] Old backups cleaned up (30+ days)
- [✓] Backup logs checked for errors

### Weekly Verification

- [✓] Run backup verification script
- [✓] Test one backup restoration
- [✓] Verify off-site backups synced
- [✓] Check backup storage space

### Monthly Tasks

- [✓] Full restoration test on separate system
- [✓] Update backup documentation
- [✓] Rotate backup encryption keys (optional)
- [✓] Review disaster recovery procedures

### Best Practices

**DO:**
- ✅ Keep multiple backup copies (3-2-1 rule)
- ✅ Store backups off-site (cloud or external drive)
- ✅ Encrypt all backups
- ✅ Test restoration regularly
- ✅ Document restoration procedures
- ✅ Keep passphrase in password manager
- ✅ Automate backup process

**DON'T:**
- ❌ Store only local backups
- ❌ Skip backup verification
- ❌ Use weak encryption passwords
- ❌ Delete old backups immediately
- ❌ Store passphrase with backups
- ❌ Forget to test restoration
- ❌ Ignore backup failure alerts

---

## 📊 Step 8: Backup Monitoring Dashboard

```bash
nano ~/wireguard-vpn/scripts/backup-status.sh
```

**Add script:**

```bash
#!/bin/bash
# Backup Status Dashboard

BACKUP_DIR=~/wireguard-vpn/backups

echo "========================================"
echo "VPN Backup Status Dashboard"
echo "Date: $(date)"
echo "========================================"
echo ""

# Latest backup
LATEST=$(ls -t "$BACKUP_DIR"/*.gpg 2>/dev/null | head -1)
if [ -n "$LATEST" ]; then
    echo "[LATEST BACKUP]"
    echo "File: $(basename "$LATEST")"
    echo "Date: $(date -r "$LATEST" '+%Y-%m-%d %H:%M:%S')"
    echo "Size: $(du -sh "$LATEST" | cut -f1)"
    echo "Age: $((( $(date +%s) - $(date -r "$LATEST" +%s) ) / 3600)) hours"
else
    echo "[LATEST BACKUP]"
    echo "No encrypted backups found!"
fi

echo ""

# Total backups
TOTAL=$(ls -1 "$BACKUP_DIR"/*.gpg 2>/dev/null | wc -l)
echo "[BACKUP INVENTORY]"
echo "Total encrypted backups: $TOTAL"
echo "Total storage used: $(du -sh "$BACKUP_DIR" | cut -f1)"

echo ""

# Backup schedule status
echo "[BACKUP SCHEDULE]"
if crontab -l | grep -q "auto-backup.sh"; then
    echo "✓ Automated backup is scheduled"
    CRON_LINE=$(crontab -l | grep "auto-backup.sh")
    echo "  Schedule: $CRON_LINE"
else
    echo "✗ No automated backup scheduled!"
fi

echo ""

# Recent backup logs
echo "[RECENT BACKUP ACTIVITY]"
if [ -f ~/wireguard-vpn/logs/backup.log ]; then
    echo "Last 5 backup attempts:"
    grep "Starting automated backup" ~/wireguard-vpn/logs/backup.log | tail -5
else
    echo "No backup log found"
fi

echo ""
echo "========================================"
```

**Make executable:**
```bash
chmod +x ~/wireguard-vpn/scripts/backup-status.sh
```

**Run status:**
```bash
~/wireguard-vpn/scripts/backup-status.sh
```

---

**✅ Backup and Disaster Recovery Complete!**

You should now have:
- ✅ Comprehensive manual backup procedures
- ✅ Automated daily encrypted backups
- ✅ Backup verification scripts
- ✅ Complete restoration procedures
- ✅ Off-site backup options (cloud/external)
- ✅ Disaster recovery scenarios documented
- ✅ Backup monitoring and status dashboard

**Backup System Features:**
- 🔐 GPG-encrypted backups for security
- ⏰ Automated daily backups at 2 AM
- 🧹 Automatic cleanup (30-day retention)
- ✅ Backup verification scripts
- 📊 Status monitoring dashboard
- ☁️ Cloud sync capabilities
- 🔄 Easy restoration process

**Critical Files to Backup:**
1. WireGuard configs and keys (`~/wireguard-vpn/config`)
2. Client data (`~/wireguard-vpn/data`)
3. Docker Compose file (`docker-compose.yml`)
4. Scripts (`~/wireguard-vpn/scripts`)
5. System configs (SSH, UFW, Fail2ban)

**Remember:**
- Store backup passphrase in password manager
- Test restoration monthly
- Keep off-site backups
- Verify backups weekly

---

## 🔧 Troubleshooting and Maintenance

This final section covers common issues, solutions, and ongoing maintenance procedures.

---

## 🚨 Common Issues and Solutions

### Issue 1: Cannot Connect to VPN

**Symptoms:**
- Client shows "connecting" but never establishes connection
- Handshake fails
- Timeout errors

**Diagnosis:**
```bash
# Check if container is running
docker ps | grep wg-easy

# Check WireGuard interface
docker exec wg-easy wg show

# Check if port is listening
sudo ss -ulnp | grep 51820

# Check firewall
sudo ufw status | grep 51820

# Check logs
docker logs wg-easy --tail 50
```

**Solutions:**

**Solution 1: Verify port forwarding**
```bash
# Test from external network (use mobile data)
# Visit: https://www.yougetsignal.com/tools/open-ports/
# Enter your DuckDNS domain and port 51820

# Or use nmap from another server
nmap -sU -p 51820 your-domain.duckdns.org
```

**Solution 2: Check DuckDNS**
```bash
# Verify DuckDNS is updating
cat ~/duckdns/duck.log
# Should show "OK"

# Manually update
~/duckdns/duck.sh

# Check DNS resolution
nslookup your-domain.duckdns.org
```

**Solution 3: Restart WireGuard**
```bash
cd ~/wireguard-vpn
docker compose restart
docker logs wg-easy
```

**Solution 4: Verify client configuration**
- Endpoint in client config should match your DuckDNS domain
- Port should be 51820
- Check AllowedIPs is set correctly

---

### Issue 2: VPN Connects but No Internet

**Symptoms:**
- VPN shows "connected"
- Can't access internet
- DNS not resolving

**Diagnosis:**
```bash
# From client, while connected to VPN:
ping 10.13.13.1  # Test VPN connection to server
ping 8.8.8.8     # Test internet without DNS
ping google.com  # Test DNS resolution

# On server, check IP forwarding
cat /proc/sys/net/ipv4/ip_forward
# Should return 1

# Check NAT rules
sudo iptables -t nat -L -n -v | grep MASQUERADE
```

**Solutions:**

**Solution 1: Enable IP forwarding**
```bash
# Temporary
sudo sysctl -w net.ipv4.ip_forward=1

# Permanent
sudo nano /etc/sysctl.conf
# Ensure this line is uncommented:
net.ipv4.ip_forward=1

# Apply changes
sudo sysctl -p
```

**Solution 2: Fix NAT/masquerading**
```bash
# Check your network interface name
ip link show

# Edit UFW before rules
sudo nano /etc/ufw/before.rules

# Ensure NAT rules exist at top (before *filter)
# Replace eth0 with your interface
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 10.13.13.0/24 -o eth0 -j MASQUERADE
COMMIT

# Restart UFW
sudo ufw disable
sudo ufw enable
```

**Solution 3: Fix DNS**
```bash
# Edit docker-compose.yml
nano ~/wireguard-vpn/docker-compose.yml

# Ensure DNS is set:
- WG_DEFAULT_DNS=1.1.1.1,8.8.8.8

# Restart
docker compose restart
```

---

### Issue 3: Cannot Access Local Network Through VPN

**Symptoms:**
- VPN connected
- Internet works
- Cannot access local devices (192.168.0.x)

**Solutions:**

**Solution 1: Check AllowedIPs**
```bash
# In client configuration, AllowedIPs should include local network
# Option 1: All traffic (recommended for your setup)
AllowedIPs = 0.0.0.0/0

# Option 2: Split tunnel (specific networks)
AllowedIPs = 192.168.0.0/24, 10.13.13.0/24
```

**Solution 2: Add firewall rule for VPN network**
```bash
# Allow VPN clients to access local network
sudo ufw allow from 10.13.13.0/24 to 192.168.0.0/24
sudo ufw reload
```

---

### Issue 4: Web UI Not Accessible

**Symptoms:**
- Cannot access http://192.168.x.x:51821
- Connection refused or timeout

**Diagnosis:**
```bash
# Check if container is running
docker ps | grep wg-easy

# Check if port is listening
sudo ss -tlnp | grep 51821

# Check firewall
sudo ufw status | grep 51821
```

**Solutions:**

**Solution 1: Verify firewall allows local access**
```bash
sudo ufw allow from 192.168.0.0/24 to any port 51821 proto tcp
sudo ufw reload
```

**Solution 2: Access from correct network**
```
# Web UI is only accessible from:
1. Local network (192.168.0.x)
2. Through VPN (10.13.13.1:51821)

# NOT accessible from internet (security feature)
```

**Solution 3: Check container health**
```bash
docker exec wg-easy curl -f http://localhost:51821
# Should return HTML

# If fails, check logs
docker logs wg-easy
```

---

### Issue 5: Slow VPN Speed

**Symptoms:**
- VPN connection very slow
- High latency
- Packet loss

**Diagnosis:**
```bash
# Check server resources
docker stats wg-easy

# Check system load
uptime

# Check network bandwidth
speedtest-cli  # Install: sudo apt install speedtest-cli

# Test VPN latency
ping -c 10 10.13.13.1
```

**Solutions:**

**Solution 1: Adjust MTU**
```bash
# Edit docker-compose.yml
nano ~/wireguard-vpn/docker-compose.yml

# Try different MTU values
- WG_MTU=1420  # Default
# Or try:
- WG_MTU=1280  # Lower for problematic connections
- WG_MTU=1500  # Higher for better performance (if no issues)

# Restart
docker compose restart
```

**Solution 2: Optimize persistent keepalive**
```bash
# Edit docker-compose.yml
nano ~/wireguard-vpn/docker-compose.yml

# Adjust keepalive interval
- WG_PERSISTENT_KEEPALIVE=25  # Default
# Try 0 for better performance (if stable connection)
# Try 15 for more stable but higher overhead

docker compose restart
```

**Solution 3: Check ISP throttling**
```bash
# Test speed without VPN
speedtest-cli

# Test speed with VPN
speedtest-cli

# Compare results
```

---

### Issue 6: Client Key/Config Lost

**Symptoms:**
- Lost device
- Corrupted configuration
- Need to reconfigure client

**Solutions:**

**Solution 1: Revoke old client and create new**
```
1. Access Web UI: http://192.168.x.x:51821
2. Find old client in list
3. Click trash icon to delete
4. Click "Add Client" to create new one
5. Download new configuration
```

**Solution 2: Restore from backup**
```bash
# If you need original keys, restore old backup
~/wireguard-vpn/scripts/restore-vpn.sh ~/wireguard-vpn/backups/backup-DATE.tar.gz.gpg

# Access Web UI to export old client config
# Then restore latest backup
```

---

### Issue 7: Docker Container Won't Start

**Symptoms:**
- `docker compose up -d` fails
- Container exits immediately
- Error messages in logs

**Diagnosis:**
```bash
cd ~/wireguard-vpn

# Check detailed logs
docker compose logs wg-easy

# Check Docker daemon
sudo systemctl status docker

# Check disk space
df -h
```

**Solutions:**

**Solution 1: Fix permissions**
```bash
# Fix ownership
sudo chown -R $USER:$USER ~/wireguard-vpn/config
sudo chown -R $USER:$USER ~/wireguard-vpn/data

chmod 700 ~/wireguard-vpn/config
chmod 700 ~/wireguard-vpn/data
```

**Solution 2: Remove corrupted data**
```bash
# Stop container
docker compose down

# Remove volumes (will regenerate)
docker volume prune -f

# Restart
docker compose up -d
```

**Solution 3: Rebuild container**
```bash
docker compose down
docker compose pull
docker compose up -d --force-recreate
```

---

### Issue 8: Fail2ban Blocking Legitimate IPs

**Symptoms:**
- Locked out of SSH
- Cannot access server
- IP banned incorrectly

**Solutions:**

**Solution 1: Unban IP**
```bash
# From another device on local network
ssh your-username@192.168.x.x

# Check banned IPs
sudo fail2ban-client status sshd

# Unban specific IP
sudo fail2ban-client set sshd unbanip YOUR.IP.ADDRESS.HERE

# Verify
sudo fail2ban-client status sshd
```

**Solution 2: Whitelist IP**
```bash
# Edit fail2ban configuration
sudo nano /etc/fail2ban/jail.local

# Add to ignoreip
ignoreip = 127.0.0.1/8 ::1 192.168.0.0/24 YOUR.IP.ADDRESS.HERE

# Restart fail2ban
sudo systemctl restart fail2ban
```

---

### Issue 9: DuckDNS Not Updating

**Symptoms:**
- IP changed but DuckDNS still shows old IP
- Cannot connect from outside

**Diagnosis:**
```bash
# Check DuckDNS log
cat ~/duckdns/duck.log

# Check cron is running
sudo systemctl status cron

# List cron jobs
crontab -l | grep duck
```

**Solutions:**

**Solution 1: Manually update**
```bash
# Run update script manually
~/duckdns/duck.sh

# Check result
cat ~/duckdns/duck.log
# Should show "OK"
```

**Solution 2: Fix cron job**
```bash
crontab -e

# Ensure this line exists:
*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1

# Or test cron
*/5 * * * * ~/duckdns/duck.sh >> ~/duckdns/cron.log 2>&1
```

**Solution 3: Verify token**
```bash
# Edit duck.sh
nano ~/duckdns/duck.sh

# Ensure token is correct (from duckdns.org)
# Test manually
curl "https://www.duckdns.org/update?domains=YOURDOMAIN&token=YOURTOKEN&ip="
```

---

## 🔍 Diagnostic Commands Reference

### Quick Health Check
```bash
# One-command health check
docker ps && \
docker exec wg-easy wg show && \
sudo ufw status | grep -E "51820|51821" && \
curl -s ifconfig.me && \
echo "Health check complete"
```

### Check All Services
```bash
# Create quick diagnostic script
cat > ~/vpn-quick-check.sh << 'EOF'
#!/bin/bash
echo "=== VPN Quick Diagnostic ==="
echo "1. Container: $(docker ps | grep -q wg-easy && echo OK || echo FAILED)"
echo "2. VPN Port: $(sudo ss -ulnp | grep -q 51820 && echo OK || echo FAILED)"
echo "3. Web UI: $(sudo ss -tlnp | grep -q 51821 && echo OK || echo FAILED)"
echo "4. Firewall: $(sudo ufw status | grep -q active && echo OK || echo FAILED)"
echo "5. IP Forward: $(cat /proc/sys/net/ipv4/ip_forward)"
echo "6. DuckDNS: $(tail -1 ~/duckdns/duck.log)"
echo "7. Fail2ban: $(sudo systemctl is-active fail2ban)"
echo "8. SSH: $(sudo systemctl is-active ssh)"
echo "9. xRDP: $(sudo systemctl is-active xrdp)"
EOF

chmod +x ~/vpn-quick-check.sh
~/vpn-quick-check.sh
```

### Log Analysis
```bash
# View all relevant logs
sudo journalctl -u docker --since "1 hour ago" | grep wg-easy
docker logs wg-easy --since 1h
sudo tail -50 /var/log/ufw.log
sudo tail -50 /var/log/fail2ban.log
```

---

## 🔄 Update and Upgrade Procedures

### Update WireGuard Container

```bash
cd ~/wireguard-vpn

# Pull latest image
docker compose pull

# Recreate container with new image
docker compose up -d

# Verify
docker compose ps
docker logs wg-easy --tail 20
```

### Update Ubuntu System

```bash
# Update package list
sudo apt update

# List upgradable packages
apt list --upgradable

# Upgrade all packages
sudo apt upgrade -y

# Check if reboot required
[ -f /var/run/reboot-required ] && echo "Reboot required" || echo "No reboot needed"

# Reboot if needed
sudo reboot
```

### Update Scripts

```bash
# Re-download this guide if updates available
# Then update scripts manually or:

cd ~/wireguard-vpn/scripts

# Backup current scripts
tar czf scripts-backup-$(date +%Y%m%d).tar.gz *.sh

# Update with new versions (if you have them)
# chmod +x *.sh
```

---

## 📅 Maintenance Schedule

### Daily (Automated)
- ✅ Log collection (11:59 PM)
- ✅ Backup creation (2:00 AM)
- ✅ Connection logging (every 5 minutes)
- ✅ Performance metrics (every 5 minutes)
- ✅ Health checks (every 15 minutes)

### Weekly (Manual - 15 minutes)
```bash
# Run on Sundays
~/wireguard-vpn/scripts/dashboard.sh
~/wireguard-vpn/scripts/security-audit.sh
~/wireguard-vpn/scripts/backup-status.sh
~/wireguard-vpn/scripts/verify-backup.sh
```

### Monthly (Manual - 30 minutes)
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Update WireGuard
cd ~/wireguard-vpn
docker compose pull
docker compose up -d

# Test backup restoration (important!)
# Review security logs
~/wireguard-vpn/scripts/analyze-logs.sh

# Check disk space
df -h

# Review and rotate old logs
find ~/wireguard-vpn/logs -name "*.log" -mtime +60 -delete
```

### Quarterly (Manual - 1 hour)
- Full backup restoration test on test system
- Review and update client list (remove unused)
- Rotate WireGuard keys (if security policy requires)
- Update documentation with any changes
- Review fail2ban rules and banned IPs
- Audit system users and permissions

---

## 📚 Frequently Asked Questions (FAQ)

### General Questions

**Q: Can I use this VPN for torrenting?**
A: Yes, all traffic routes through your home connection. However, be aware that your ISP can see the traffic. Consider your home internet's terms of service.

**Q: How many devices can connect simultaneously?**
A: Depends on your server resources. The default setup can easily handle 10-20 simultaneous connections. Each client needs a unique configuration.

**Q: Will this work with my mobile carrier?**
A: Yes, WireGuard works on both WiFi and cellular data. Some carriers may have specific ports blocked, but UDP 51820 is typically allowed.

**Q: Can I change the VPN port from 51820?**
A: Yes, edit `docker-compose.yml` and change the port mapping and `WG_PORT` variable. Remember to update router port forwarding.

**Q: Is this production-ready?**
A: Yes, WireGuard is production-grade. This setup includes security hardening, monitoring, and backups suitable for production use.

### Security Questions

**Q: How secure is WireGuard compared to OpenVPN?**
A: WireGuard uses modern cryptography (ChaCha20, Curve25519) and has been audited. It's considered more secure than OpenVPN with significantly less code to audit.

**Q: What happens if someone gets my VPN configuration file?**
A: They can connect to your VPN as that device. Immediately delete that client from the Web UI and create a new one. This is why you should never share configs.

**Q: Should I expose SSH to the internet?**
A: No! This guide specifically keeps SSH accessible only through VPN or local network. This is a critical security measure.

**Q: How often should I rotate VPN keys?**
A: For home use, rotation isn't strictly necessary unless a device is compromised. For higher security, consider every 90-180 days.

### Technical Questions

**Q: Why is my VPN slower than my direct connection?**
A: VPN adds encryption overhead. You'll typically see 10-20% speed reduction. If more, check MTU settings and server resources.

**Q: Can I run other services in Docker alongside WireGuard?**
A: Yes, Docker containers are isolated. Just ensure port conflicts don't occur.

**Q: What if my home IP changes?**
A: DuckDNS automatically updates every 5 minutes via cron. Your VPN endpoint (domain) stays the same.

**Q: Can I access my VPN from China/restricted countries?**
A: WireGuard can work but may be detected and blocked. Consider using port 443 or obfuscation tools if needed.

**Q: How much bandwidth does the VPN use when idle?**
A: Minimal - just keepalive packets (25-30 seconds interval). Very battery-friendly for mobile devices.

---

## 🎯 Quick Reference Commands

### Essential Commands

```bash
# Start VPN
cd ~/wireguard-vpn && docker compose up -d

# Stop VPN
cd ~/wireguard-vpn && docker compose down

# Restart VPN
cd ~/wireguard-vpn && docker compose restart

# View logs
docker logs wg-easy --tail 50 -f

# Status dashboard
~/wireguard-vpn/scripts/dashboard.sh

# Quick health check
~/vpn-quick-check.sh

# Create backup
~/wireguard-vpn/scripts/backup-vpn.sh

# Security audit
sudo ~/wireguard-vpn/scripts/security-audit.sh

# View connected clients
docker exec wg-easy wg show
```

### Access Points

```
Web UI (local):     http://192.168.x.x:51821
Web UI (via VPN):   http://10.13.13.1:51821
SSH (via VPN):      ssh user@10.13.13.1
RDP (via VPN):      10.13.13.1:3389
Server VPN IP:      10.13.13.1
Client VPN Range:   10.13.13.2-254
```

### Important File Locations

```
Configuration:      ~/wireguard-vpn/docker-compose.yml
WireGuard Data:     ~/wireguard-vpn/config/
Client Data:        ~/wireguard-vpn/data/
Scripts:            ~/wireguard-vpn/scripts/
Logs:               ~/wireguard-vpn/logs/
Backups:            ~/wireguard-vpn/backups/
DuckDNS:            ~/duckdns/duck.sh
```

---

## 🆘 Emergency Procedures

### VPN Completely Down

```bash
# 1. Quick restart
cd ~/wireguard-vpn
docker compose restart

# 2. If that fails, full reset
docker compose down
docker compose up -d

# 3. Check logs
docker logs wg-easy

# 4. If still down, restore from backup
~/wireguard-vpn/scripts/restore-vpn.sh ~/wireguard-vpn/backups/backup-latest.tar.gz.gpg
```

### Locked Out of Server

```bash
# Option 1: Access via local network
ssh user@192.168.x.x

# Option 2: Physical access (keyboard/monitor)
# Login directly at console

# Option 3: Router admin
# Reset port forwarding or check firewall

# Once in, check fail2ban
sudo fail2ban-client status sshd
sudo fail2ban-client set sshd unbanip YOUR_IP
```

### Cannot Access After Update

```bash
# Rollback to previous backup
cd ~/wireguard-vpn
docker compose down

# Find previous backup
ls -lt ~/wireguard-vpn/backups/

# Restore
~/wireguard-vpn/scripts/restore-vpn.sh ~/wireguard-vpn/backups/backup-PREVIOUS_DATE.tar.gz.gpg

# Start VPN
docker compose up -d
```

---

## ✅ Final Checklist

Before considering your setup complete, verify:

### Installation Checklist
- [ ] Ubuntu server configured with static IP (192.168.x.x)
- [ ] Docker and Docker Compose V2 installed
- [ ] DuckDNS configured and auto-updating
- [ ] Router port forwarding configured (UDP 51820)
- [ ] WireGuard container running
- [ ] Web UI accessible locally

### Security Checklist
- [ ] SSH password authentication disabled
- [ ] SSH accessible only from local network/VPN
- [ ] Root SSH login disabled
- [ ] UFW firewall enabled and configured
- [ ] Fail2ban installed and monitoring
- [ ] Only VPN port (51820) exposed to internet
- [ ] Web UI accessible only locally
- [ ] Security audit script tested

### Client Checklist
- [ ] Windows client configured and tested
- [ ] macOS client configured and tested
- [ ] iOS client configured and tested
- [ ] Android client configured and tested
- [ ] SSH access through VPN working
- [ ] RDP access through VPN working
- [ ] Internet routing through VPN working

### Monitoring Checklist
- [ ] All monitoring scripts created
- [ ] Dashboard accessible
- [ ] Log collection automated
- [ ] Performance metrics collecting
- [ ] Alert system configured
- [ ] Connection history tracking

### Backup Checklist
- [ ] Manual backup tested
- [ ] Automated daily backup scheduled
- [ ] Backup encryption configured
- [ ] Backup verification tested
- [ ] Restoration procedure tested

---

# 🌐 APPENDIX: CGNAT Workaround Guide

## Complete VPS Relay Setup for CGNAT Users

If you discovered you're behind CGNAT (router WAN IP ≠ public IP), this guide shows you how to use a cheap VPS as a relay server.

### Architecture Overview

```
┌─────────────────┐         ┌─────────────────┐         ┌──────────────────┐
│  Your Device    │         │   VPS Server    │         │   Home Server    │
│  (Traveling)    │◄────────┤  (Public IP)    │◄────────┤  (Behind CGNAT)  │
│                 │  VPN 1  │                 │  VPN 2  │                  │
│  10.13.13.2     │         │  Public IP      │         │  10.14.14.1      │
└─────────────────┘         └─────────────────┘         └──────────────────┘
```

**How it works:**
1. **VPN 2**: Home server maintains persistent connection to VPS
2. **VPN 1**: Your devices connect to VPS
3. VPS forwards traffic between the two tunnels
4. Result: Your devices can reach home server despite CGNAT

---

## Step 1: Get a VPS

### Recommended Providers

#### Option A: Oracle Cloud (FREE Forever) ⭐
- **Cost**: FREE (2 AMD VMs with 1GB RAM each)
- **Sign up**: https://www.oracle.com/cloud/free/
- **Specs**: 1 core, 1GB RAM, 10TB monthly traffic
- **Perfect for**: VPN relay (more than enough)

#### Option B: DigitalOcean ($4/month)
- **Cost**: $4/month + $200 free credit for new users
- **Sign up**: https://www.digitalocean.com/
- **Specs**: 1 core, 512MB RAM, 500GB traffic
- **Promo**: Use code `DO10` for $10 credit

#### Option C: Vultr ($3.50/month)
- **Cost**: $3.50/month + $100 free credit
- **Sign up**: https://www.vultr.com/
- **Specs**: 1 core, 512MB RAM, 500GB traffic

### VPS Setup
1. Create account at chosen provider
2. Deploy Ubuntu 24.04 LTS instance
3. Choose closest region to your home
4. Note down the **public IP address**

---

## Step 2: Install WireGuard on VPS

SSH into your VPS and run:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install WireGuard
sudo apt install -y wireguard

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

---

## Step 3: Configure WireGuard on VPS

### Generate VPS Keys

```bash
cd /etc/wireguard
sudo wg genkey | sudo tee vps-private.key | wg pubkey | sudo tee vps-public.key
sudo chmod 600 vps-private.key
```

### Create VPS WireGuard Config

```bash
sudo nano /etc/wireguard/wg0.conf
```

**VPS Configuration** (`/etc/wireguard/wg0.conf`):

```ini
[Interface]
PrivateKey = <VPS_PRIVATE_KEY>  # Content of vps-private.key
Address = 10.14.14.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Peer 1: Your Home Server (persistent connection FROM home)
[Peer]
PublicKey = <HOME_SERVER_PUBLIC_KEY>  # Generated in Step 4
AllowedIPs = 10.14.14.2/32, 192.168.0.0/24  # Home server + home network
PersistentKeepalive = 25

# Peer 2: Your Laptop
[Peer]
PublicKey = <LAPTOP_PUBLIC_KEY>  # Generated in Step 5
AllowedIPs = 10.14.14.3/32

# Peer 3: Your Phone
[Peer]
PublicKey = <PHONE_PUBLIC_KEY>  # Generated in Step 5
AllowedIPs = 10.14.14.4/32
```

**Note:** We'll fill in the public keys in the next steps.

---

## Step 4: Configure Home Server

On your **Ubuntu home server** (behind CGNAT):

### Generate Home Server Keys

```bash
cd /etc/wireguard
sudo wg genkey | sudo tee home-private.key | wg pubkey | sudo tee home-public.key
sudo chmod 600 home-private.key
```

### Create Home Server Config

```bash
sudo nano /etc/wireguard/wg-vps.conf
```

**Home Server Configuration** (`/etc/wireguard/wg-vps.conf`):

```ini
[Interface]
PrivateKey = <HOME_PRIVATE_KEY>  # Content of home-private.key
Address = 10.14.14.2/24

# Peer: VPS Server (we initiate connection TO vps)
[Peer]
PublicKey = <VPS_PUBLIC_KEY>  # Content of vps-public.key from VPS
Endpoint = <VPS_PUBLIC_IP>:51820  # Replace with actual VPS IP
AllowedIPs = 10.14.14.0/24
PersistentKeepalive = 25
```

### Enable IP Forwarding on Home Server

```bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Start Home-to-VPS Tunnel

```bash
# Start the tunnel
sudo wg-quick up wg-vps

# Enable on boot
sudo systemctl enable wg-quick@wg-vps
```

### Copy Home Server Public Key

```bash
sudo cat /etc/wireguard/home-public.key
```

**Go back to VPS** and update `/etc/wireguard/wg0.conf` with this public key in the `[Peer]` section for home server.

---

## Step 5: Update VPS Config and Start

On **VPS**, after adding home server's public key:

```bash
# Start WireGuard on VPS
sudo wg-quick up wg0

# Enable on boot
sudo systemctl enable wg-quick@wg0

# Check status
sudo wg show
```

You should see output showing the home server peer with recent handshake.

---

## Step 6: Test Home-to-VPS Connection

From **home server**:

```bash
# Ping VPS through tunnel
ping 10.14.14.1

# Check WireGuard status
sudo wg show wg-vps
```

You should see:
- ✅ Successful pings to `10.14.14.1`
- ✅ Recent handshake in `sudo wg show`
- ✅ Data transfer counters increasing

---

## Step 7: Configure Client Devices

Now your client devices connect to the **VPS**, and VPS routes to **home server**.

### Generate Client Keys

On your **laptop/phone** (or do this on VPS/home server):

```bash
wg genkey | tee client-private.key | wg pubkey > client-public.key
```

### Client Configuration Example (Laptop)

**Laptop WireGuard Config**:

```ini
[Interface]
PrivateKey = <LAPTOP_PRIVATE_KEY>
Address = 10.14.14.3/24
DNS = 1.1.1.1

[Peer]
PublicKey = <VPS_PUBLIC_KEY>
Endpoint = <VPS_PUBLIC_IP>:51820
AllowedIPs = 0.0.0.0/0, ::/0  # Route ALL traffic through VPN
PersistentKeepalive = 25
```

### Add Client to VPS Config

On **VPS**, edit `/etc/wireguard/wg0.conf` and add:

```ini
[Peer]
PublicKey = <LAPTOP_PUBLIC_KEY>
AllowedIPs = 10.14.14.3/32
```

Then reload:

```bash
sudo wg-quick down wg0 && sudo wg-quick up wg0
```

---

## Step 8: Access Home Server Services

Now from your laptop (connected to VPS VPN):

### SSH to Home Server

```bash
ssh username@10.14.14.2
```

Or if you want to use home server's actual LAN IP:

```bash
ssh username@192.168.x.x
```

This works because:
1. VPS has `AllowedIPs = 192.168.0.0/24` for home server peer
2. VPS forwards packets destined for `192.168.0.0/24` to home server
3. Home server routes them to local network

### RDP to Home Server

In your RDP client:
- **Connect to**: `10.14.14.2:3389` or `192.168.x.x:3389`
- Username/password as usual

---

## Step 9: Firewall Rules on VPS

```bash
# On VPS - allow WireGuard
sudo ufw allow 51820/udp
sudo ufw enable
```

---

## Traffic Flow Example

When you **browse internet** from laptop:

```
Laptop → VPS (encrypted) → Internet
```

When you **SSH to home server**:

```
Laptop → VPS → Home Server (via tunnel 2) → Ubuntu Server
```

---

## Cost Comparison

| Solution | Monthly Cost | Setup Time | Performance |
|----------|--------------|------------|-------------|
| Oracle Cloud VPS | **FREE** | 30 min | Good (~20-50ms added latency) |
| DigitalOcean | $4/month | 20 min | Excellent (~10-30ms latency) |
| Vultr | $3.50/month | 20 min | Excellent (~10-30ms latency) |
| ISP Static IP | $5-15/month | 5 min | Best (no added latency) |

---

## Monitoring VPS Relay

### Check Connection Status

On **VPS**:
```bash
sudo wg show
```

Look for:
- ✅ **latest handshake** should be recent (< 3 minutes)
- ✅ **transfer** counters should be increasing

On **Home Server**:
```bash
sudo wg show wg-vps
```

### Auto-Restart on Connection Loss

Create a watchdog script on **home server**:

```bash
sudo nano /usr/local/bin/wg-vps-watchdog.sh
```

```bash
#!/bin/bash
# Restart WireGuard if VPS unreachable

if ! ping -c 1 -W 2 10.14.14.1 > /dev/null 2>&1; then
    echo "$(date): VPS unreachable, restarting wg-vps" >> /var/log/wg-watchdog.log
    systemctl restart wg-quick@wg-vps
fi
```

```bash
sudo chmod +x /usr/local/bin/wg-vps-watchdog.sh
```

Add to crontab:
```bash
sudo crontab -e
```

```cron
*/5 * * * * /usr/local/bin/wg-vps-watchdog.sh
```

---

## Troubleshooting VPS Relay

### Home Server Can't Connect to VPS

**Check:**
1. VPS firewall allows UDP 51820
2. VPS WireGuard is running: `sudo systemctl status wg-quick@wg0`
3. Keys are correct in both configs
4. VPS public IP is correct in home server config

**Test:**
```bash
# From home server
nc -vzu <VPS_IP> 51820
```

### Clients Can't Reach Home Server Through VPS

**Check:**
1. VPS has IP forwarding enabled: `sysctl net.ipv4.ip_forward`
2. VPS peer config includes home network: `AllowedIPs = 10.14.14.2/32, 192.168.0.0/24`
3. Home server responds to pings: `ping 10.14.14.2` from VPS
4. Firewall rules on VPS allow forwarding

**Test from VPS:**
```bash
# Can VPS reach home server?
ping 10.14.14.2

# Can VPS reach home LAN?
ping 192.168.x.x
```

---

## Performance Optimization

### 1. Choose VPS Region Wisely
- Pick VPS geographically close to your home
- Closer = lower latency

### 2. Use UDP Acceleration (on high-latency links)
If VPS is far away, consider BBR congestion control:

On **VPS**:
```bash
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 3. MTU Optimization

Test optimal MTU:
```bash
# From home server to VPS
ping -M do -s 1472 10.14.14.1
```

If fails, reduce packet size until it works, then set MTU in WireGuard config:

```ini
[Interface]
MTU = 1420  # Adjust based on your test
```

---

## 🎯 Summary

**You've now:**
- ✅ Set up VPS as relay server
- ✅ Created persistent tunnel from home server to VPS
- ✅ Configured clients to connect via VPS
- ✅ Can access home server despite CGNAT

**Total cost:** FREE to $4/month  
**Total latency added:** ~20-50ms (acceptable for SSH/RDP)

---

# 🌐 APPENDIX B: Tailscale Complete Setup Guide

## Why Tailscale for CGNAT?

Tailscale is the **easiest** solution if you're behind CGNAT and want immediate results.

### ✅ Advantages
- **Zero configuration** - Works in 5 minutes
- **No port forwarding needed** - Handles CGNAT automatically
- **Cross-platform** - Windows, Mac, Linux, iOS, Android
- **Free for personal use** - Up to 100 devices
- **Automatic NAT traversal** - Direct peer-to-peer when possible
- **Built-in MagicDNS** - Access devices by name instead of IP
- **Exit nodes** - Route internet traffic through any device
- **Subnet routing** - Access entire home network remotely

### ⚠️ Considerations
- Relies on Tailscale's coordination servers
- Less control than self-hosted VPN
- Free tier sufficient for most personal use
- Optional: Can self-host coordination server (Headscale)

---

## 🚀 Quick Start: Tailscale Setup

### Step 1: Install Tailscale on Home Server (Ubuntu)

```bash
# Add Tailscale repository
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-list | sudo tee /etc/apt/sources.list.d/tailscale.list

# Install Tailscale
sudo apt update
sudo apt install -y tailscale

# Start Tailscale
sudo tailscale up
```

**You'll see a URL** - open it in browser to authenticate with Google/Microsoft/GitHub account.

### Step 2: Install Tailscale on Your Devices

#### **Windows:**
1. Download: https://tailscale.com/download/windows
2. Run installer
3. Click "Connect" and sign in with same account

#### **macOS:**
1. Download: https://tailscale.com/download/mac
2. Run installer
3. Click "Connect" and sign in

#### **iOS/Android:**
1. Install from App Store / Play Store
2. Open app and sign in

#### **Linux:**
Same as server installation above

---

## 🎯 Use Case 1: Access Home Server from remote location

**This works immediately after setup!**

### Find Your Server's Tailscale IP

On **home server**:
```bash
tailscale ip -4
# Example output: 100.101.102.103
```

### SSH from remote location

```bash
# Option 1: Use Tailscale IP
ssh username@100.101.102.103

# Option 2: Use MagicDNS name (easier)
ssh username@home-server
```

### RDP from remote location

In your RDP client (Windows/Mac):
```
Connect to: 100.101.102.103:3389
# Or: home-server:3389
```

**✅ It just works!** No port forwarding, no firewall rules needed.

---

## 🌍 Use Case 2: Browse Internet as if at home

This requires **Exit Node** configuration.

### Step 1: Enable IP Forwarding on Home Server

```bash
# Enable IP forwarding permanently
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

### Step 2: Advertise Home Server as Exit Node

```bash
# Advertise server as exit node
sudo tailscale up --advertise-exit-node
```

### Step 3: Approve Exit Node (in Tailscale Admin)

1. Go to https://login.tailscale.com/admin/machines
2. Find your home server
3. Click **"Edit route settings"**
4. Enable **"Use as exit node"**
5. Click **"Save"**

### Step 4: Use Exit Node from remote location Laptop

#### **Linux/Mac:**
```bash
# List available exit nodes
tailscale exit-node list

# Use home server as exit node
tailscale up --exit-node=home-server
# Or use the Tailscale IP:
# tailscale up --exit-node=100.101.102.103
```

#### **Windows:**
1. Right-click Tailscale tray icon
2. Select **"Exit Node"**
3. Choose your home server
4. Click **"Use Exit Node"**

#### **iOS/Android:**
1. Open Tailscale app
2. Tap **"Exit Node"**
3. Select your home server

### Step 5: Verify It's Working

```bash
# Check your public IP
curl ifconfig.me
# Should show your home server's public IP!

# Check location
curl ipinfo.io
# Should show home location
```

### Stop Using Exit Node

#### **Linux/Mac:**
```bash
tailscale up --exit-node=""
```

#### **Windows/iOS/Android:**
Disable exit node in app settings

---

## 🏠 Use Case 3: Access Entire Home Network at home

Want to access **other devices** on your home network (192.168.0.x)?

### Step 1: Advertise Subnet on Home Server

```bash
# Advertise your home network subnet
sudo tailscale up --advertise-routes=192.168.0.0/24 --advertise-exit-node
```

### Step 2: Approve Subnet in Tailscale Admin

1. Go to https://login.tailscale.com/admin/machines
2. Find home server
3. Click **"Edit route settings"**
4. Enable **subnet routes** (192.168.0.0/24)
5. Click **"Save"**

### Step 3: Access Devices from remote location

Now you can access **any device** on your home network:

```bash
# Access home router
ssh admin@192.168.0.1

# Access other server
ssh user@192.168.0.50

# Access IP camera
http://192.168.0.20

# Access NAS
smb://192.168.0.100
```

**✅ Your entire home network is accessible!**

---

## 🔒 Security Best Practices with Tailscale

### 1. Enable Key Expiry

Tailscale keys expire by default (180 days). To change:

1. Go to https://login.tailscale.com/admin/machines
2. Click device → **"Disable key expiry"** (if you want permanent)
3. Or adjust expiry period

### 2. Use ACLs (Access Control Lists)

Control which devices can access which:

1. Go to https://login.tailscale.com/admin/acls
2. Edit ACL policy (JSON format)

Example: Only allow remote laptop to SSH to home server:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["laptop-remote"],
      "dst": ["home-server:22"]
    }
  ]
}
```

### 3. Enable MFA

1. Go to https://login.tailscale.com/admin/settings/general
2. Enable **Two-factor authentication**

### 4. Monitor Active Connections

```bash
# On any device
tailscale status

# Show detailed peer info
tailscale status --json | jq
```

---

## 📊 Performance Comparison

### Direct Connection (Peer-to-Peer)

When Tailscale establishes direct connection:

| Metric | Performance |
|--------|-------------|
| Latency | Same as raw internet (~100-150ms home-remote) |
| Speed | Full bandwidth (100+ Mbps typically) |
| NAT Traversal | Automatic (STUN/TURN) |

### Relayed Connection (DERP)

When direct connection impossible:

| Metric | Performance |
|--------|-------------|
| Latency | +20-50ms additional |
| Speed | ~50-100 Mbps (still good) |
| Reliability | Very high |

### Check Connection Type

```bash
tailscale status
```

Look for:
- **`direct`** = Peer-to-peer (best performance)
- **`relay`** = Through Tailscale DERP server (still good)

---

## 🛠️ Troubleshooting Tailscale

### Issue 1: Can't Connect to Device

**Check if both devices are online:**
```bash
tailscale status
```

**Ping the device:**
```bash
ping 100.101.102.103
```

**Check firewall on home server:**
```bash
# Allow Tailscale interface
sudo ufw allow in on tailscale0
```

### Issue 2: Exit Node Not Working

**Verify IP forwarding:**
```bash
sysctl net.ipv4.ip_forward
# Should output: net.ipv4.ip_forward = 1
```

**Check exit node approval:**
- Go to https://login.tailscale.com/admin/machines
- Verify exit node is enabled

**Test with direct IP:**
```bash
tailscale up --exit-node=100.101.102.103
```

### Issue 3: Subnet Routing Not Working

**Check route advertisement:**
```bash
tailscale status
# Look for "Offering routes"
```

**Verify kernel forwarding:**
```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

**Check Tailscale admin:**
- Ensure subnet routes are approved

### Issue 4: Poor Performance

**Check connection type:**
```bash
tailscale status
```

If showing `relay`, try to force direct connection:

**On home server:**
```bash
sudo tailscale up --accept-routes --advertise-exit-node --advertise-routes=192.168.0.0/24
```

**Check NAT/firewall:**
- Ensure UDP ports aren't blocked
- Tailscale uses UDP 41641 and 3478

---

## 💡 Advanced: Self-Hosted Headscale

Want **full control** without Tailscale's servers?

**Headscale** is an open-source, self-hosted Tailscale control server.

### Quick Headscale Setup

**On a VPS (or home server):**

```bash
# Install Headscale
wget https://github.com/juanfont/headscale/releases/latest/download/headscale_*_linux_amd64.deb
sudo dpkg -i headscale_*.deb

# Configure
sudo nano /etc/headscale/config.yaml
# Set server_url to your VPS IP or domain

# Start Headscale
sudo systemctl enable --now headscale

# Create namespace
headscale namespaces create mypersonal

# Add devices
headscale nodes register --namespace mypersonal --key <device-key>
```

**On devices:**
```bash
tailscale up --login-server=http://your-vps-ip:8080
```

**Pros:**
- ✅ Full control over coordination server
- ✅ No reliance on Tailscale cloud
- ✅ Can customize everything

**Cons:**
- ⚠️ More complex setup
- ⚠️ You maintain the server
- ⚠️ No official support

---

## 📋 Tailscale vs WireGuard Comparison

| Feature | Tailscale | Self-Hosted WireGuard |
|---------|-----------|----------------------|
| **Setup Time** | 5 minutes | 1-2 hours |
| **CGNAT Support** | ✅ Built-in | ❌ Requires workarounds |
| **Multi-device** | ✅ Automatic | ⚠️ Manual config |
| **Exit Nodes** | ✅ Easy toggle | ⚠️ Manual routing |
| **Control** | ⚠️ Some reliance on Tailscale | ✅ Full control |
| **Cost** | Free (personal) | Free (DIY) or VPS cost |
| **Performance** | ⭐⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ Excellent |
| **Learning Value** | ⭐⭐⭐ Medium | ⭐⭐⭐⭐⭐ High |
| **Maintenance** | ⭐⭐⭐⭐⭐ Minimal | ⭐⭐⭐ Regular |

---

## 🎯 Your home-remote Use Case: Complete Setup

### What You Get with Tailscale:

#### ✅ Always Available:
1. **SSH to home server** from anywhere
2. **RDP to home server** from anywhere
3. **Access home network devices** at home

#### ✅ When You Need It:
4. **Exit node ON**: Browse internet as if at home
   - Netflix home region content
   - Banking apps requiring home IP
   - Bypass geo-restrictions
   
5. **Exit node OFF**: Use local local internet
   - Better latency for general browsing
   - Faster speeds

### Complete Setup Commands

**On Home Server:**
```bash
# Install
curl -fsSL https://tailscale.com/install.sh | sh

# Configure with all features
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf

# Start with exit node + subnet routing
sudo tailscale up --advertise-exit-node --advertise-routes=192.168.0.0/24

# Get server IP
tailscale ip -4
```

**Approve in Admin Panel:**
1. Visit https://login.tailscale.com/admin/machines
2. Enable exit node and subnet routes

**On Remote Laptop:**
```bash
# Install
curl -fsSL https://tailscale.com/install.sh | sh

# Connect
sudo tailscale up

# When you want home internet:
tailscale up --exit-node=home-server

# When you want local internet:
tailscale up --exit-node=""
```

**Daily Usage:**
```bash
# SSH to home server (always works)
ssh username@home-server

# RDP (always works)
# Connect to: home-server:3389

# Toggle home internet (as needed)
tailscale up --exit-node=home-server  # home IP
tailscale up --exit-node=""            # local IP
```

---

## 🎓 Summary

**For your CGNAT situation, Tailscale provides:**

✅ **Immediate access** to home server from remote location  
✅ **SSH and RDP** work instantly  
✅ **Exit node** lets you browse internet as if at home  
✅ **Subnet routing** gives access to entire home network  
✅ **Zero port forwarding** needed  
✅ **Free for personal use**  
✅ **5-minute setup** vs hours for alternatives  

**Trade-offs:**
- ⚠️ Relies on Tailscale coordination servers (but peer-to-peer data)
- ⚠️ Less learning about VPN internals
- ⚠️ Less customization than self-hosted

**Perfect for:** Quick solution, reliability, ease of use  
**Not ideal for:** Learning deep VPN concepts, 100% self-hosted requirement

---

# 🌩️ APPENDIX C: Cloudflare Tunnel Complete Setup Guide

## What is Cloudflare Tunnel?

Cloudflare Tunnel (formerly Argo Tunnel) creates a secure, outbound-only connection from your server to Cloudflare's global network. Perfect for CGNAT situations!

### Architecture

```
┌─────────────┐      HTTPS      ┌──────────────┐    Tunnel    ┌──────────────┐
│   Client    │ ──────────────► │  Cloudflare  │ ◄─────────── │ Home Server │
│  (Remote)  │                 │     Edge     │              │ (Behind NAT) │
└─────────────┘                 └──────────────┘              └──────────────┘
                                                                     │
                                                              SSH, RDP, HTTP
```

**Key Insight:** The connection is **initiated FROM your server TO Cloudflare**, so inbound ports/CGNAT don't matter!

---

## ✅ Advantages

### 🆓 Free Tier Includes:
- Unlimited bandwidth
- Unlimited tunnels
- DDoS protection
- SSL/TLS encryption
- CDN caching
- Access control
- Browser-based SSH/RDP

### 🎯 Perfect For:
- Web applications (HTTP/HTTPS)
- SSH access (browser or CLI)
- RDP/VNC (browser-based)
- APIs and webhooks
- Development servers
- Home labs
- Anything behind CGNAT

### ⚠️ Limitations:
- Not designed for exit node (browsing internet as if at home)
- Adds ~10-30ms latency
- Requires Cloudflare account
- Custom domains recommended (but not required)

---

## 🚀 Complete Setup Guide

### Prerequisites

1. **Cloudflare account** (free): https://dash.cloudflare.com/sign-up
2. **Domain name** (optional but recommended):
   - Can use Cloudflare's free subdomain
   - Or add your own domain to Cloudflare

---

## Step 1: Install cloudflared on Home Server

### Ubuntu/Debian:

```bash
# Add Cloudflare repository
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-archive-keyring.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/cloudflare-archive-keyring.gpg] https://pkg.cloudflare.com/cloudflared jammy main" | sudo tee /etc/apt/sources.list.d/cloudflared.list

# Install
sudo apt update
sudo apt install -y cloudflared

# Verify installation
cloudflared --version
```

### Alternative: Direct Download

```bash
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
```

---

## Step 2: Authenticate with Cloudflare

```bash
cloudflared tunnel login
```

This will:
1. Open a URL in your terminal
2. Copy and paste it in a browser
3. Sign in to your Cloudflare account
4. Authorize cloudflared
5. Download a certificate to `~/.cloudflared/cert.pem`

**✅ You should see:** "You have successfully logged in"

---

## Step 3: Create a Tunnel

```bash
# Create tunnel with a name
cloudflared tunnel create home-server

# Output will show:
# Tunnel credentials written to /root/.cloudflared/<TUNNEL-ID>.json
# Created tunnel home-server with id <TUNNEL-ID>
```

**Save the Tunnel ID!** You'll need it.

### List your tunnels:
```bash
cloudflared tunnel list
```

---

## Step 4: Configure Tunnel

Create configuration file:

```bash
sudo mkdir -p /etc/cloudflared
sudo nano /etc/cloudflared/config.yml
```

### Basic Configuration (SSH + RDP):

```yaml
# Replace <TUNNEL-ID> with your actual tunnel ID
tunnel: <TUNNEL-ID>
credentials-file: /root/.cloudflared/<TUNNEL-ID>.json

# Optional: Better logging
loglevel: info
logfile: /var/log/cloudflared.log

ingress:
  # SSH access via browser
  - hostname: ssh.yourdomain.com
    service: ssh://localhost:22
  
  # RDP access via browser
  - hostname: rdp.yourdomain.com
    service: tcp://localhost:3389
  
  # Catch-all rule (required, must be last)
  - service: http_status:404
```

### Advanced Configuration (Multiple Services):

```yaml
tunnel: <TUNNEL-ID>
credentials-file: /root/.cloudflared/<TUNNEL-ID>.json

ingress:
  # SSH
  - hostname: ssh.yourdomain.com
    service: ssh://localhost:22
  
  # RDP/xRDP
  - hostname: rdp.yourdomain.com
    service: tcp://localhost:3389
  
  # Web application on port 8080
  - hostname: app.yourdomain.com
    service: http://localhost:8080
  
  # Home Assistant
  - hostname: home.yourdomain.com
    service: http://localhost:8123
  
  # Jupyter Notebook
  - hostname: jupyter.yourdomain.com
    service: http://localhost:8888
  
  # Expose entire home network (advanced)
  - hostname: router.yourdomain.com
    service: http://192.168.0.1
  
  # Catch-all
  - service: http_status:404
```

---

## Step 5: Create DNS Records

### Option A: Using cloudflared CLI (Recommended)

```bash
# For each hostname in your config
cloudflared tunnel route dns home-server ssh.yourdomain.com
cloudflared tunnel route dns home-server rdp.yourdomain.com
cloudflared tunnel route dns home-server app.yourdomain.com
```

### Option B: Manual DNS (Cloudflare Dashboard)

1. Go to https://dash.cloudflare.com
2. Select your domain
3. Go to **DNS** → **Records**
4. Add CNAME records:
   - **Name:** `ssh`
   - **Target:** `<TUNNEL-ID>.cfargotunnel.com`
   - **Proxy status:** Proxied (orange cloud)

Repeat for each hostname.

---

## Step 6: Test Tunnel

```bash
# Run tunnel in foreground (for testing)
cloudflared tunnel run home-server

# You should see:
# Starting tunnel home-server
# Registered tunnel connection
# Each tunnel runs 4 connections to different edge servers
```

**Test from another device:**
```bash
curl https://ssh.yourdomain.com
# Should get a response (even if error, means tunnel works)
```

---

## Step 7: Install as System Service

Once testing works:

```bash
# Install service
sudo cloudflared service install

# Start service
sudo systemctl start cloudflared

# Enable on boot
sudo systemctl enable cloudflared

# Check status
sudo systemctl status cloudflared

# View logs
sudo journalctl -u cloudflared -f
```

---

## 🌐 Accessing Your Services

### SSH Access

#### Option 1: Browser-Based SSH (No Client!)

1. Navigate to: `https://ssh.yourdomain.com`
2. You'll see Cloudflare Access page
3. Authenticate (if configured) or direct access
4. Full terminal in browser!

#### Option 2: CLI with cloudflared

**On remote laptop:**

```bash
# Install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# SSH through tunnel
cloudflared access ssh --hostname ssh.yourdomain.com
```

#### Option 3: Native SSH Client

Add to `~/.ssh/config`:

```
Host home-server
  ProxyCommand cloudflared access ssh --hostname ssh.yourdomain.com
```

Then simply:
```bash
ssh home-server
```

### RDP Access

#### Browser-Based RDP:

1. Navigate to: `https://rdp.yourdomain.com`
2. Full RDP session in browser
3. Works on any device with a browser!

#### Native RDP Client:

**Windows:**
```powershell
# Install cloudflared for Windows
# Download from: https://github.com/cloudflare/cloudflared/releases

# Create tunnel in PowerShell
cloudflared access rdp --hostname rdp.yourdomain.com --url localhost:13389

# In another window, connect RDP to:
# localhost:13389
```

---

## 🔒 Security: Cloudflare Access (Zero Trust)

Add authentication layer to your tunnels (FREE!):

### Step 1: Enable Cloudflare Access

1. Go to https://dash.cloudflare.com
2. Navigate to **Zero Trust** → **Access**
3. Set up authentication provider:
   - Google
   - GitHub
   - Email OTP
   - Many others

### Step 2: Create Access Policy

1. Go to **Access** → **Applications**
2. Click **Add an Application**
3. Select **Self-hosted**
4. Configure:
   - **Application name:** "SSH to Home Server"
   - **Subdomain:** `ssh`
   - **Domain:** `yourdomain.com`

5. Create policy:
   - **Rule name:** "Only me"
   - **Rule action:** Allow
   - **Include:** Your email address

### Step 3: Test

Now when you visit `https://ssh.yourdomain.com`, you'll be asked to authenticate!

---

## 📊 Monitoring and Logs

### View Tunnel Status

```bash
# From home server
cloudflared tunnel info home-server

# List all tunnels
cloudflared tunnel list

# Check service status
sudo systemctl status cloudflared
```

### View Logs

```bash
# Real-time logs
sudo journalctl -u cloudflared -f

# Last 100 lines
sudo journalctl -u cloudflared -n 100

# Logs from last hour
sudo journalctl -u cloudflared --since "1 hour ago"
```

### Cloudflare Dashboard

1. Go to https://dash.cloudflare.com
2. Select your domain
3. Go to **Traffic** → **Analytics**
4. See requests, bandwidth, threats blocked

---

## 🛠️ Advanced Configurations

### 1. Expose Multiple Ports (Same Service)

```yaml
ingress:
  # Main web app
  - hostname: myapp.yourdomain.com
    service: http://localhost:3000
  
  # API on different port
  - hostname: api.yourdomain.com
    service: http://localhost:4000
  
  # WebSocket service
  - hostname: ws.yourdomain.com
    service: ws://localhost:5000
```

### 2. Load Balancing

```yaml
ingress:
  - hostname: app.yourdomain.com
    service: hello-world
    originRequest:
      connectTimeout: 30s
      noTLSVerify: false
  
  - service: http_status:404
```

### 3. Access to Entire Home Network

**Enable IP forwarding on home server:**

```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

**In config.yml:**

```yaml
ingress:
  # Access router
  - hostname: router.yourdomain.com
    service: http://192.168.0.1
  
  # Access another device
  - hostname: nas.yourdomain.com
    service: http://192.168.0.50
```

### 4. Custom HTTP Headers

```yaml
ingress:
  - hostname: app.yourdomain.com
    service: http://localhost:8080
    originRequest:
      httpHostHeader: app.local
      http2Origin: true
```

---

## 🚨 Troubleshooting

### Tunnel Won't Start

**Check config syntax:**
```bash
cloudflared tunnel validate /etc/cloudflared/config.yml
```

**Check credentials file exists:**
```bash
ls -la /root/.cloudflared/
```

**Check tunnel exists:**
```bash
cloudflared tunnel list
```

### DNS Not Resolving

**Verify DNS record:**
```bash
dig ssh.yourdomain.com
# Should show CNAME to *.cfargotunnel.com
```

**Check proxy status** in Cloudflare dashboard (should be orange cloud)

### Service Not Reachable

**Check local service is running:**
```bash
# For SSH
sudo systemctl status ssh

# For RDP
sudo systemctl status xrdp

# For web app
curl localhost:8080
```

**Check ingress rules order** - catch-all must be last!

### High Latency

**Check nearest edge:**
```bash
cloudflared tunnel info home-server
# Shows which Cloudflare datacenters tunnel connects to
```

**Tunnel uses closest Cloudflare datacenter automatically**

---

## 💰 Cost Comparison

| Feature | Cloudflare Tunnel | Tailscale | VPS Relay |
|---------|------------------|-----------|-----------|
| **Monthly Cost** | FREE | FREE | $0-5 |
| **Bandwidth** | Unlimited | Unlimited | Limited |
| **DDoS Protection** | ✅ Included | ❌ No | ❌ No |
| **CDN** | ✅ Included | ❌ No | ❌ No |
| **SSL Certs** | ✅ Auto | Manual | Manual |
| **Browser Access** | ✅ Yes | ❌ No | ❌ No |

---

## 🎯 Use Case Examples

### Example 1: Personal Blog

```yaml
ingress:
  - hostname: blog.yourdomain.com
    service: http://localhost:80
  - service: http_status:404
```

**Benefits:**
- ✅ Free CDN
- ✅ Free SSL
- ✅ DDoS protection
- ✅ No server port exposure

### Example 2: Development Server

```yaml
ingress:
  # Frontend
  - hostname: app.yourdomain.com
    service: http://localhost:3000
  
  # Backend API
  - hostname: api.yourdomain.com
    service: http://localhost:8000
  
  # Database admin (Adminer)
  - hostname: db.yourdomain.com
    service: http://localhost:8080
  
  - service: http_status:404
```

### Example 3: Home Automation

```yaml
ingress:
  # Home Assistant
  - hostname: home.yourdomain.com
    service: http://localhost:8123
  
  # Security cameras
  - hostname: cameras.yourdomain.com
    service: http://localhost:8888
  
  # Node-RED
  - hostname: nodered.yourdomain.com
    service: http://localhost:1880
  
  - service: http_status:404
```

---

## 🔄 Combining Cloudflare Tunnel + Tailscale

**Best of both worlds!**

### Setup Strategy:

1. **Cloudflare Tunnel** for:
   - Web services (public or authenticated)
   - Browser-based access
   - Services you want to share

2. **Tailscale** for:
   - Direct SSH/RDP (lower latency)
   - Exit node (browsing as if at home)
   - Private services
   - Device-to-device communication

### Configuration:

**On home server, run BOTH:**

```bash
# Cloudflare Tunnel
sudo systemctl start cloudflared

# Tailscale
sudo tailscale up --advertise-exit-node
```

**From Remote Location:**

```bash
# Access web app via Cloudflare
https://app.yourdomain.com

# SSH via Tailscale (faster)
ssh username@home-server

# Browse as if at home via Tailscale
tailscale up --exit-node=home-server
```

---

## 📋 Quick Command Reference

```bash
# Create tunnel
cloudflared tunnel create <NAME>

# List tunnels
cloudflared tunnel list

# Delete tunnel
cloudflared tunnel delete <NAME>

# Route DNS
cloudflared tunnel route dns <NAME> <HOSTNAME>

# Run tunnel (foreground)
cloudflared tunnel run <NAME>

# Install service
sudo cloudflared service install

# Service management
sudo systemctl {start|stop|restart|status} cloudflared

# View logs
sudo journalctl -u cloudflared -f

# Validate config
cloudflared tunnel validate /etc/cloudflared/config.yml

# Get tunnel info
cloudflared tunnel info <NAME>
```

---

## 🎓 Summary

**Cloudflare Tunnel provides:**

✅ **Zero inbound ports** - Perfect for CGNAT  
✅ **Browser-based access** - No client software needed  
✅ **Free DDoS protection** - Enterprise-grade security  
✅ **Free SSL certificates** - Automatic renewal  
✅ **Global CDN** - Fast access from anywhere  
✅ **Zero Trust security** - Free authentication layer  
✅ **Unlimited bandwidth** - No usage limits  

**Best for:**
- Web applications and APIs
- Browser-based SSH/RDP access
- Services requiring DDoS protection
- Public-facing services
- Professional setup with custom domains

**Combine with Tailscale for:**
- Direct low-latency access
- Exit node (browsing as if at home)
- Private device-to-device communication

---
- [ ] Off-site backup configured
- [ ] Backup passphrase stored securely

### Maintenance Checklist
- [ ] Cron jobs configured
- [ ] Update procedures documented
- [ ] Emergency procedures tested
- [ ] Documentation accessible
- [ ] Troubleshooting guide reviewed

---

## 🎓 Learning Resources

### WireGuard Documentation
- Official Site: https://www.wireguard.com
- Quick Start: https://www.wireguard.com/quickstart/
- Protocol: https://www.wireguard.com/protocol/

### wg-easy Documentation
- GitHub: https://github.com/wg-easy/wg-easy
- Docker Hub: https://hub.docker.com/r/weejewel/wg-easy

### Security Resources
- Ubuntu Security: https://ubuntu.com/security
- Docker Security: https://docs.docker.com/engine/security/
- Fail2ban: https://www.fail2ban.org

---

## 🎉 Conclusion

**Congratulations!** You now have a production-ready, security-hardened, self-hosted WireGuard VPN server.

### What You've Accomplished:

✅ **Secure VPN Infrastructure**
- Modern WireGuard encryption
- Multi-platform client support
- Device-based access control

✅ **Security Hardening**
- Fail2ban intrusion prevention
- SSH key-only authentication
- Advanced firewall configuration
- Automated security updates

✅ **Comprehensive Monitoring**
- Real-time connection tracking
- Performance metrics
- Security alerts
- Log analysis

✅ **Disaster Recovery**
- Automated encrypted backups
- Tested restoration procedures
- Off-site backup options

### Your VPN Can Now:

🔒 **Secure Access**
- Access your Ubuntu server from anywhere
- RDP into your desktop remotely
- SSH securely without exposing ports

🌍 **Privacy Protection**
- Route internet through home connection when traveling
- Bypass geo-restrictions
- Secure public WiFi usage

📱 **Multi-Device Support**
- Windows, macOS, iOS, Android
- Easy configuration with QR codes
- Automatic connection options

### Next Steps:

1. **Test everything thoroughly** from different networks
2. **Document your specific customizations**
3. **Set calendar reminders** for monthly maintenance
4. **Share this guide** with others (if permitted)
5. **Keep backups updated** and tested

### Support and Community:

- WireGuard Community: https://lists.zx2c4.com/mailman/listinfo/wireguard
- Reddit: r/WireGuard
- Stack Overflow: Tag `wireguard`

---

## 📄 License and Disclaimer

This guide is provided "as-is" for educational purposes. 

**Disclaimer:**
- Always comply with your ISP's terms of service
- Ensure you have legal right to access systems remotely
- VPN does not guarantee complete anonymity
- Regular security updates and monitoring are essential
- Test thoroughly before relying on for critical access

**Security Reminder:**
- Keep all passwords secure
- Don't share VPN configurations
- Monitor access logs regularly
- Update systems promptly
- Backup encryption keys safely

---

**🎯 End of Guide**

You now have everything you need to run a secure, reliable, self-hosted VPN!

**Version:** 1.0  
**Last Updated:** November 23, 2025  
**Total Sections:** 12  
**Total Scripts:** 20+  
**Setup Time:** 2-4 hours  
**Maintenance:** ~30 minutes/month

---

**Happy VPN-ing! 🚀🔐**
---------