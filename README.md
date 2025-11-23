# 🏠 Homelab VPN: My Journey from "Port Forwarding Failed" to Tailscale Magic

> **How I turned an old dusty PC into a globally-accessible homelab server, learned about CGNAT the hard way, and discovered why mesh VPNs are awesome**

*A week-long adventure through networking rabbit holes, CGNAT frustration, and finally finding the right solution*

[![Uptime](https://img.shields.io/badge/Uptime-99.9%25-brightgreen)]()
[![Access Points](https://img.shields.io/badge/Access_Points-3_Locations-blue)]()
[![Solution](https://img.shields.io/badge/VPN-Tailscale-purple)]()
[![Status](https://img.shields.io/badge/Status-Production-success)]()

---

## 📖 Table of Contents

- [The Origin Story](#-the-origin-story)
- [The CGNAT Wall](#-the-cgnat-wall)
- [The Great Solution Hunt](#-the-great-solution-hunt)
- [Architecture Deep Dive](#-architecture-deep-dive)
- [The Final Setup](#-the-final-setup)
- [Lessons Learned](#-lessons-learned)
- [Results & Stats](#-results--stats)
- [Quick Start Guide](#-quick-start-guide)
- [Repository Contents](#-repository-contents)
- [Future Plans](#-future-plans)
- [Acknowledgments](#-acknowledgments)

---

## 🎯 The Origin Story

Last week, I stared at an old PC collecting dust in the corner and thought, "Why am I keeping this?" Then it hit me - **homelab time!** 

I wiped it clean, installed Ubuntu, and suddenly I had a shiny new server humming away at home. SSH worked perfectly. RDP was smooth. I spun up some web servers, experimented with media streaming, and felt like a sysadmin wizard.

But then I thought: *"What if I'm traveling and need to access this?"*

**Narrator:** *He did not know what he was about to learn.*

My goal was simple:
- 🔐 Access my homelab server from anywhere in the world
- 🌐 Route my internet through home (handy for traveling)
- 📚 Learn networking along the way (spoiler: mission accomplished)

I confidently Googled "VPN setup Ubuntu" and landed on WireGuard tutorials. "Perfect!" I thought. "Just forward a port, exchange some keys, and boom - remote access!"

I configured my router, set up the port forwarding rule for UDP 51820, generated WireGuard configs, and attempted to connect...

**Nothing. Absolutely nothing.**

---

## 🚧 The CGNAT Wall

### The Frustrating Discovery

My port forwarding wasn't working. I triple-checked everything:
- ✅ Router forwarding rule: correct
- ✅ Server firewall: allowing UDP 51820
- ✅ WireGuard config: looked good
- ✅ DuckDNS pointing to my public IP: check

So why wasn't it working?

I decided to verify the basics. I logged into my router's admin panel and compared two things:

```
Router's WAN IP:  172.18.x.x
My Public IP:     206.84.x.x

Wait... these are DIFFERENT! 🤔
```

**One Google search later:** "Oh. CGNAT. Great."

### What is CGNAT? (The Thing I Wish I Knew Earlier)

**CGNAT** (Carrier-Grade Network Address Translation) is when your ISP puts you behind *another* layer of NAT. Basically:

```
🌐 What I THOUGHT my network looked like:
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   Internet   │────────>│  My Router   │────────>│  My Server   │
│              │         │ (Public IP)  │         │ (Local IP)   │
└──────────────┘         └──────────────┘         └──────────────┘
                              ✅ Port forwarding works!

❌ What my network ACTUALLY looks like:
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Internet   │───>│  ISP CGNAT   │───>│  My Router   │───>│  My Server   │
│              │    │ (Shared IP)  │    │ (Private IP) │    │ (Local IP)   │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
                          🚫 Port forwarding hits ISP wall, never reaches my router!
```

**The Problem:** My router doesn't have a real public IP. It has a private IP assigned by the ISP's CGNAT system. When I try to forward a port, it forwards to... nowhere that matters.

**The Reaction:** Frustration → Confusion → Curiosity

**The Timeline:** One full day of debugging before figuring this out.

### Why ISPs Use CGNAT

There aren't enough IPv4 addresses to go around, so ISPs share one public IP among hundreds or thousands of customers. It saves them money, but breaks:
- Port forwarding
- Hosting servers
- P2P applications
- Traditional VPN setups
- Basically anything that needs inbound connections

**The Options:**
1. Request a static public IP from ISP (~$10-15/month, if they even offer it)
2. Use IPv6 (if available and you trust yourself with IPv6 routing)
3. Find a solution that works with CGNAT

I chose option 3. Time to research.

---

## 🔍 The Great Solution Hunt

I spent the next day researching every possible way to access my homelab behind CGNAT. Here's what I found:

### Solution 1: WireGuard + VPS Relay

**The Concept:** Rent a cloud VPS with a public IP, set up WireGuard on both the VPS and home server, relay traffic through the VPS.

```
You (traveling) ──> VPS (public IP) ──> Home Server (CGNAT)
                     └─ Acts as relay ─┘
```

**Pros:**
- ✅ Full control over everything
- ✅ Learn WireGuard internals deeply
- ✅ Free tier available (Oracle Cloud)
- ✅ Can use for other projects

**Cons:**
- ❌ More complex setup (2 WireGuard tunnels to manage)
- ❌ Adds latency (~20-50ms depending on VPS location)
- ❌ Need to maintain a VPS
- ❌ More moving parts = more troubleshooting

**Verdict:** Great for learning, but more work than I wanted for a simple homelab.

---

### Solution 2: Cloudflare Tunnel

**The Concept:** Install Cloudflare's `cloudflared` daemon on your server, create persistent outbound tunnels to Cloudflare's edge network.

```
You (browser) ──> Cloudflare (edge) ──> Your Server (CGNAT)
                   └─ Professional CDN ─┘
```

**Pros:**
- ✅ Free (unlimited bandwidth!)
- ✅ Browser-based access (no client software)
- ✅ Free SSL certificates
- ✅ DDoS protection included
- ✅ Professional appearance with custom domains

**Cons:**
- ❌ Best for HTTP/HTTPS (web apps)
- ❌ Not ideal for SSH/RDP access
- ❌ **No exit node capability** (can't route internet through home)
- ❌ Relies on Cloudflare service

**Verdict:** Perfect for hosting web apps, but not the right fit for my SSH/RDP + exit node use case.

---

### Solution 3: Tailscale (The Winner!)

**The Concept:** Mesh VPN that coordinates through cloud servers but tries to establish direct peer-to-peer connections using NAT traversal magic.

```
You (traveling) ──┐
                  ├──> Tailscale Coordination ──┐
Home Server ──────┘    (helps establish P2P)    └──> Direct P2P Connection
                                                      (when possible!)
```

**Pros:**
- ✅ **5-minute setup** (seriously!)
- ✅ Mesh networking (all devices can talk to each other)
- ✅ **Exit node feature built-in** (route internet through home!)
- ✅ NAT traversal works behind CGNAT
- ✅ Free for personal use (100 devices)
- ✅ Works on everything (Windows, Mac, Linux, iOS, Android)
- ✅ MagicDNS (access devices by name, not IP)
- ✅ Direct P2P when possible (low latency)

**Cons:**
- ❌ Relies on Tailscale's infrastructure
- ❌ Less control than self-hosted WireGuard
- ❌ Visitors need Tailscale client to access your services

**Verdict:** 🏆 Perfect balance of simplicity, features, and "it just works."

---

### The Decision Matrix

| Criteria | WireGuard + VPS | Cloudflare Tunnel | Tailscale |
|----------|----------------|-------------------|-----------|
| **Setup Time** | 30-60 min | 10-15 min | **5 min** ✅ |
| **Cost** | $0-5/month | FREE | FREE ✅ |
| **SSH/RDP Access** | ✅ Yes | ⚠️ Browser-based | ✅ **Native** |
| **Exit Node** | ✅ Yes | ❌ No | ✅ **Built-in** |
| **Learning Value** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Maintenance** | High | Low | **Lowest** ✅ |
| **Works with CGNAT** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Best For** | Learning | Web Apps | **Homelab Access** ✅ |

**Why I chose Tailscale:**
1. I wanted quick setup (homelab is for experimenting, not maintaining VPN infrastructure)
2. Exit node was a must-have (traveling internationally)
3. Mesh networking is elegant (every device can talk to every other device)
4. Free tier is generous (100 devices - I have 2!)
5. Still learning value (understanding NAT traversal, mesh networks, modern VPN tech)

---

## 🏗️ Architecture Deep Dive

Let me show you how Tailscale solves the CGNAT problem using some clever networking tricks.

### The Problem Visualized

```
❌ Traditional VPN with CGNAT:

                  ┌─────────────────────────────────────┐
                  │         ISP CGNAT Layer             │
                  │  (Shared Public IP: 206.84.x.x)     │
                  └─────────────────────────────────────┘
                                    │
                        ❌ Inbound connection blocked
                                    ↓
                  ┌─────────────────────────────────────┐
                  │         Your Router                 │
                  │    (Private IP: 172.18.x.x)         │
                  │    Port Forward: 51820 → Server     │ ← Rule exists but useless!
                  └─────────────────────────────────────┘
                                    │
                                    ↓
                  ┌─────────────────────────────────────┐
                  │         Your Server                 │
                  │       (Local IP: 192.168.x.x)       │
                  │      WireGuard listening: 51820     │ ← Never receives packets!
                  └─────────────────────────────────────┘

🚫 Problem: Packets sent to 206.84.x.x:51820 go to ISP's CGNAT, which doesn't 
   know which customer to forward to (thousands share this IP!)
```

### The Tailscale Solution

Tailscale uses **outbound connections only** (which work through CGNAT) plus **NAT traversal techniques**:

```
✅ Tailscale Approach:

Step 1️⃣: Both devices connect OUTBOUND to Tailscale coordination servers
┌─────────────────┐                                    ┌─────────────────┐
│  Your Laptop    │─────────────────┐                  │  Home Server    │
│  (Traveling)    │                 ↓                  │  (Behind CGNAT) │
└─────────────────┘         ┌──────────────┐          └─────────────────┘
                            │  Tailscale   │                    │
                            │ Coordination │                    │
                            │   Servers    │                    │
                            └──────────────┘                    │
                                    ↑                           │
                                    └───────────────────────────┘
                            Both establish outbound connections ✅
                                   (CGNAT allows this!)


Step 2️⃣: Coordination servers help devices find each other
┌──────────────────────────────────────────────────────────────┐
│               Tailscale Coordination Server                  │
│                                                              │
│  "Laptop is at: 85.10.x.x:51234"                            │
│  "Server is at: 206.84.x.x:51820 (behind CGNAT)"            │
│                                                              │
│  Exchange: Public keys, endpoints, NAT types                │
└──────────────────────────────────────────────────────────────┘


Step 3️⃣: Simultaneous hole punching (NAT traversal magic!)
┌─────────────────┐                                    ┌─────────────────┐
│  Your Laptop    │──────────────────────────────────>│  Home Server    │
│                 │<──────────────────────────────────│                 │
└─────────────────┘    Both send packets at same time └─────────────────┘
                       └─> Creates temporary NAT holes! ✨

                              Result:
                     Direct P2P Connection! 🎉
                    (When possible - 70-80% success)


Step 4️⃣: Fallback to DERP relay (if P2P fails)
┌─────────────────┐         ┌──────────────┐         ┌─────────────────┐
│  Your Laptop    │────────>│ Tailscale    │────────>│  Home Server    │
│                 │<────────│ DERP Relay   │<────────│                 │
└─────────────────┘         └──────────────┘         └─────────────────┘
                        Still encrypted end-to-end!
```

### How Simultaneous Hole Punching Works

This is the clever part that makes CGNAT bypass possible:

```
┌──────────────────────────────────────────────────────────────────┐
│  The Magic of Hole Punching (Simplified)                        │
└──────────────────────────────────────────────────────────────────┘

Your Laptop                    ISP CGNAT                    Home Server
     │                              │                              │
     │  1️⃣ Send packet to server   │                              │
     ├──────────────────────────────>                              │
     │                              ├─> Creates "hole" in NAT      │
     │                              │   (allows responses from     │
     │                              │    server's IP to come back) │
     │                              │                              │
     │                              │   2️⃣ Server sends at same time│
     │                              <──────────────────────────────┤
     │   Packet arrives! 🎉         │                              │
     <──────────────────────────────┤                              │
     │                              │                              │
     │  3️⃣ Both keep sending        ↔        Holes stay open!     │
     <──────────────────────────────────────────────────────────────>
                          Direct P2P connection established! ✨
```

**Why this works:**
- Both devices initiate **outbound** connections (CGNAT allows outbound!)
- Timing is coordinated by Tailscale servers
- NAT devices create temporary "holes" expecting response traffic
- When both sides punch holes simultaneously, packets flow through
- Connection is maintained with keepalive packets

**Pretty cool, right?** 🤓

---

## ✅ The Final Setup

After choosing Tailscale, the actual setup was almost anticlimactic:

### On Home Server (5 minutes)

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Enable IP forwarding (for exit node)
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

# Start with exit node + subnet routing
sudo tailscale up --advertise-exit-node --advertise-routes=192.168.x.0/24

# Authenticate (opens browser)
# Copy link, sign in with Google/GitHub
```

### In Tailscale Admin Panel (2 minutes)

1. Visit https://login.tailscale.com/admin/machines
2. Find home server
3. Enable "Use as exit node"
4. Approve subnet routes
5. Done!

### On Laptop/Phone (2 minutes)

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Connect
sudo tailscale up
```

**Total setup time:** ~10 minutes including authentication.

### What I'm Running Now

My homelab is accessible via Tailscale for:

- 🔐 **SSH** - Remote terminal access
- 🖥️ **RDP** - Full desktop access (xRDP)
- 🌐 **Web Servers** - Personal projects and experiments
- 📺 **Media Server** - Streaming my content library
- ☁️ **Personal Cloud** - File sync and storage
- 🔄 **Exit Node** - Browse internet as if I'm at home

**Access from:**
- 💻 Laptop (Linux/Windows)
- 📱 Phone (Android/iOS)
- 🌍 Any location in the world

---

## 🎓 Lessons Learned

### 1. **Understand Your Network First**

**What I wish I knew earlier:** How internet actually reaches my home.

```
Simple mental model of home internet:
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Internet │───>│   ISP    │───>│  Router  │───>│  Device  │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

**The reality with CGNAT:**
```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Internet │───>│ISP CGNAT │───>│Router NAT│───>│  Device  │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
                └─ Adds layer─┘  └─Home layer─┘
```

**Takeaway:** Before setting up any server/VPN, check if you have a real public IP:
```bash
# Your public IP (from internet's perspective)
curl ifconfig.me

# Your router's WAN IP (from router admin page)
# If these DON'T match → you're behind CGNAT
```

**Time saved:** Could have saved an entire day if I checked this first.

---

### 2. **The Firewall/Telnet Facepalm Moment** 🤦

**The Setup:** I'm trying to RDP to my server from my laptop through Tailscale. RDP won't connect. SSH works fine.

**What I did:** Spent HALF A DAY troubleshooting:
- ✅ Checked xRDP service (running)
- ✅ Checked Tailscale connection (connected)
- ✅ Tested with `telnet server-ip 3389` from SERVER itself (works!)
- ✅ Checked logs (no errors)
- ❌ Still can't RDP from laptop

**The Problem:**
```bash
# My firewall rule (WRONG):
sudo ufw allow from 192.168.x.108 to any port 3389

# ☝️ Only allowing from ONE specific IP (my laptop's local IP)
# But through Tailscale, my laptop has a DIFFERENT IP (100.x.x.x)!
```

**Why telnet from server worked:** I was testing FROM the server TO itself, so the firewall allowed it!

**The Fix:**
```bash
# Should have allowed entire Tailscale network:
sudo ufw allow from 100.64.0.0/10 to any port 3389

# Or my home network CIDR:
sudo ufw allow from 192.168.x.0/24 to any port 3389
```

**Lesson:** When testing connectivity, test from the ACTUAL source (laptop → server), not from server → server! 🤦

**Time wasted:** 4+ hours

**Emotional journey:** Confident → Confused → Frustrated → Debugging mode → Facepalm → Laughing at myself

---

### 3. **Architecture First, Implementation Second**

**What I did:** Jump straight into WireGuard setup without understanding my constraints (CGNAT).

**What I should have done:**
1. Draw my current network architecture
2. Identify constraints (CGNAT, no public IP)
3. Research solutions that work WITH my constraints
4. Choose solution
5. THEN implement

**Time spent researching AFTER failed attempt:** ~6 hours

**Time I could have spent if I researched FIRST:** ~2 hours

**Lesson:** Measure twice, cut once. Especially in networking.

---

### Key Takeaways

| # | Lesson | Impact |
|---|--------|--------|
| 1 | **Check for CGNAT before attempting port forwarding** | Saves days of frustration |
| 2 | **Test from actual source/destination, not localhost** | Saves hours of debugging |
| 3 | **Understand architecture before implementation** | Saves rework and wrong solutions |
| 4 | **Firewall rules need CIDRs, not single IPs** | Saves half-day troubleshooting sessions |
| 5 | **Modern mesh VPNs > traditional VPNs for CGNAT** | Saves setup complexity |

**Bonus Lesson:** Documentation is your friend. I created extensive docs during this journey (see [Repository Contents](#-repository-contents)), and it's already helped me troubleshoot issues twice.

---

## 📊 Results & Stats

After one week of learning, frustration, and implementation:

### ✅ What's Working

- 🌍 **Access from 3 different locations** (home, work, travel)
- 📈 **99.9% uptime** (okay, it's been a week, but still! 😄)
- ⚡ **Low latency** (~20-40ms for direct P2P connections)
- 🔐 **Secure access** to all homelab services
- 🚀 **Exit node** toggles on/off instantly
- 📱 **Cross-platform** (laptop and phone both work seamlessly)

### 📊 Metrics That Matter

```
Services Running:       SSH, RDP, Web, Media Server
Devices Connected:      2 (laptop, phone)
Total Setup Time:       ~10 hours (including research & mistakes)
  ├─ Research:          ~6 hours
  ├─ Failed attempts:   ~2 hours
  ├─ Final setup:       ~10 minutes
  └─ Documentation:     ~2 hours

Learning Hours:         Worth it! 🎓
CGNAT Frustration:      Initially high, now understood
Current Satisfaction:   Very high ✨
```

### 🎯 Success Criteria Met

- ✅ Access homelab from anywhere in the world
- ✅ Secure encrypted connections
- ✅ Exit node for international travel
- ✅ Low maintenance overhead
- ✅ **Deep learning about networking** (the real win!)

---

## 🚀 Quick Start Guide

Want to set this up yourself? Here's the condensed version:

### Step 1: Check for CGNAT

```bash
# Get your public IP
curl ifconfig.me

# Compare with router's WAN IP (from router admin page)
# If different → you're behind CGNAT (use Tailscale)
# If same → you can use traditional VPN (WireGuard, OpenVPN)
```

**Script included:** [`check-cgnat.sh`](./scripts/check-cgnat.sh)

---

### Step 2: Choose Your Solution

| Your Situation | Recommended Solution |
|----------------|---------------------|
| **No CGNAT + Want to learn** | WireGuard (traditional setup) |
| **Behind CGNAT + Want simple** | **Tailscale** ⭐ |
| **Behind CGNAT + Want to learn** | WireGuard + VPS Relay |
| **Only web apps** | Cloudflare Tunnel |
| **Want everything** | Tailscale + Cloudflare |

**Comparison guide:** [`SOLUTIONS-COMPARISON.md`](./docs/SOLUTIONS-COMPARISON.md)

---

### Step 3: Follow Detailed Guide

Depending on your choice:

- 📘 **Tailscale:** [`TAILSCALE-COMPLETE-GUIDE.md`](./docs/tailscale/TAILSCALE-COMPLETE-GUIDE.md) (full 7-step guide)
- 📗 **Tailscale Quick:** [`TAILSCALE-QUICKSTART.md`](./docs/tailscale/TAILSCALE-QUICKSTART.md) (5-minute version)
- 📙 **WireGuard Traditional:** [`VPN.md`](./docs/wireguard/VPN.md) (comprehensive guide)
- 📕 **VPS Relay:** [`VPN.md` → Appendix A](./docs/wireguard/VPN.md#appendix-a-cgnat-workaround-guide)
- 📔 **Cloudflare:** [`VPN.md` → Appendix C](./docs/wireguard/VPN.md#appendix-c-cloudflare-tunnel-setup)

---

### Step 4: Test & Enjoy!

```bash
# Test SSH access
ssh user@your-server

# Test RDP (in RDP client)
your-server:3389

# Enable exit node (Tailscale)
tailscale up --exit-node=your-server

# Verify you're routing through home
curl ifconfig.me
```

---

## 📚 Repository Contents

This repo contains all my documentation from this journey:

### 📖 Main Guides

| File | Description | Audience |
|------|-------------|----------|
| [`README.md`](./README.md) | This file - my journey & lessons | Everyone |
| [`VPN.md`](./docs/wireguard/VPN.md) | Comprehensive WireGuard guide (8000+ lines) | Intermediate |
| [`TAILSCALE-COMPLETE-GUIDE.md`](./docs/tailscale/TAILSCALE-COMPLETE-GUIDE.md) | Full Tailscale setup (4700+ lines) | Beginners to Advanced |
| [`TAILSCALE-QUICKSTART.md`](./docs/tailscale/TAILSCALE-QUICKSTART.md) | 5-minute Tailscale setup | Quick start |

### 🔍 Decision Helpers

| File | Description | Use When |
|------|-------------|----------|
| [`SOLUTIONS-COMPARISON.md`](./docs/SOLUTIONS-COMPARISON.md) | Compare all VPN solutions | Choosing a solution |
| [`CGNAT-BYPASS-ARCHITECTURE.md`](./docs/CGNAT-BYPASS-ARCHITECTURE.md) | How each solution bypasses CGNAT | Understanding options |
| [`check-cgnat.sh`](./scripts/check-cgnat.sh) | Detect if you're behind CGNAT | First step |

### 🎯 What to Read First

**If you're behind CGNAT (like me):**
1. Read this README (you're here!)
2. Run `scripts/check-cgnat.sh` to confirm
3. Read `docs/SOLUTIONS-COMPARISON.md` to choose
4. Follow `docs/tailscale/TAILSCALE-QUICKSTART.md` for fast setup
5. Refer to `docs/tailscale/TAILSCALE-COMPLETE-GUIDE.md` for details

**If you have a public IP:**
1. Read this README for context
2. Follow `docs/wireguard/VPN.md` for traditional WireGuard

**If you just want architecture diagrams:**
- See `docs/CGNAT-BYPASS-ARCHITECTURE.md`

---

## 🔮 Future Plans

Now that the VPN is working, here's what's next for my homelab:

### Short Term (Next Month)
- 📹 **Live streaming setup** - OBS + RTMP server
- 💾 **Expand storage** - NAS setup for media/backups
- 🔒 **Security hardening** - Implement ACLs, fail2ban, monitoring
- 📊 **Monitoring dashboard** - Grafana + Prometheus

### Medium Term (Next 3 Months)
- 🐳 **More Docker services** - Nextcloud, Jellyfin, Pi-hole
- 🤖 **Automation** - Ansible playbooks for reproducible setup
- 📱 **Mobile-optimized access** - Better UX for phone access
- 🔐 **Advanced security** - Implement Tailscale ACL policies

### Long Term (Wishlist)
- 🖥️ **Expand hardware** - Maybe another server for redundancy
- 🌐 **Public services** - Host some projects for friends/family
- 📚 **Documentation site** - Turn this into a blog/tutorial site
- 🎓 **Video tutorials** - Record setup process for others

**Follow along:** I'll update this repo as I add features!

---

## 🙏 Acknowledgments

This project wouldn't have been possible without:

### 🛠️ Tools & Projects
- **[Tailscale](https://tailscale.com)** - For making VPN accessible to mere mortals
- **[WireGuard](https://www.wireguard.com)** - Modern VPN that sparked this journey
- **[DuckDNS](https://www.duckdns.org)** - Free dynamic DNS
- **Ubuntu** - Solid server OS

### 📚 Learning Resources
- Tailscale blog posts on NAT traversal
- WireGuard documentation
- r/homelab community
- Various blog posts and tutorials (too many to list!)

### 💡 Inspiration
- The r/selfhosted community
- Fellow homelabbers sharing their setups
- My own frustration with CGNAT (best teacher!)

---

## 📬 Questions or Feedback?

If you found this helpful, have questions, or want to share your own CGNAT horror stories:

- 🌟 Star this repo if it helped!
- 🐛 Open an issue if you find errors
- 💬 Share your own homelab journey

---

## 📄 License

This documentation is released under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

Feel free to use, modify, and share - just give credit and share alike!

---

**Happy homelabbing! 🏠🔐✨**

*Last updated: November 23, 2025*

