# 🏗️ CGNAT Bypass Architecture Diagrams

**Understanding How Each Solution Works Around CGNAT**

---

## ❌ The Problem: Traditional VPN with CGNAT

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        │        Your Public IP: 206.84.x.x        │
        │              (ISP's CGNAT)                │
        │                                           │
        │  ┌─────────────────────────────────────┐ │
        │  │      ISP's CGNAT Server              │ │
        │  │  Shared by 1000s of customers        │ │
        │  └─────────────────────────────────────┘ │
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                              │
                    ┌─────────┴─────────┐
                    │  Your Router      │
                    │  WAN IP:          │
                    │  172.18.x.x       │ ← Private IP (not routable!)
                    │  (Not Reachable!) │
                    └─────────┬─────────┘
                              │
                    ┌─────────┴─────────┐
                    │  Home Server      │
                    │  192.168.x.x      │
                    │  Port 51820       │ ← Can't receive inbound!
                    └───────────────────┘

❌ PROBLEM: Port forwarding on router does NOTHING because
            your router doesn't have a public IP!
            
❌ Packets sent to 206.84.x.x:51820 never reach your router
            because that IP is shared by thousands of customers
            
❌ ISP's CGNAT doesn't know which customer to send packets to
```

---

## ✅ Solution 1: VPS Relay (Outbound Connections Only)

**Key Concept:** Your server initiates the connection TO the VPS (outbound works through CGNAT)

```
┌────────────────────────────────────────────────────────────────────────┐
│                            INTERNET                                     │
└────────────────────────────────────────────────────────────────────────┘
         │                              │                        │
         │                              │                        │
    ┌────▼────┐                   ┌─────▼─────┐          ┌──────▼──────┐
    │ Remote  │                   │    VPS    │          │  ISP CGNAT  │
    │ Laptop  │                   │ (Cloud)   │          │  206.x.x.x  │
    │         │                   │           │          │             │
    └────┬────┘                   │ Public IP:│          └──────┬──────┘
         │                        │ 45.x.x.x  │                 │
         │                        │           │                 │
         │                        │ Port 51820│                 │
         │                        └─────┬─────┘                 │
         │                              │                       │
         │    ┌─────────────────────────┘                       │
         │    │  1. WireGuard Tunnel                            │
         │    │     (VPN 1)                                     │
         │    │                                                 │
         │    │                                    ┌────────────┘
         │    │                                    │
         │    │                                    │ 2. Persistent
         │    │                                    │    Connection
         │    │                                    │    (Outbound)
         │    │                                    │    ↑ CGNAT allows!
         │    │                              ┌─────▼─────┐
         │    │                              │  Router   │
         │    │                              │172.18.x.x │
         │    │                              └─────┬─────┘
         │    │                                    │
         │    │                              ┌─────▼─────┐
         │    └─────────────────────────────►│   Home    │
         │         3. Traffic Forwarded      │  Server   │
         │            by VPS                 │192.168.x.x│
         │                                   └───────────┘
         │
         └──────────────────────────────────────────┐
                      Traffic Flow:                  │
                                                     │
    Your Device → VPS (Public) → Home Server ◄──────┘
    (via VPN 1)   (forwards)     (via VPN 2)


┌──────────────────────────────────────────────────────────────┐
│ HOW IT WORKS:                                                 │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│ 1. Home Server → VPS (Tunnel 2)                              │
│    • Home server initiates connection to VPS                 │
│    • Outbound connection = CGNAT allows it                   │
│    • Connection stays persistent (keepalive every 25 sec)    │
│                                                               │
│ 2. Your Device → VPS (Tunnel 1)                              │
│    • You connect to VPS (it has public IP)                   │
│    • VPS is reachable from anywhere                          │
│                                                               │
│ 3. VPS Forwards Traffic                                      │
│    • VPS acts as middleman/relay                             │
│    • Forwards packets between Tunnel 1 and Tunnel 2          │
│    • Your device ← VPS ← Home Server                         │
│                                                               │
│ ✅ Result: You access home server despite CGNAT!             │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

**Detailed Packet Flow:**

```
Step 1: Initial Setup
═══════════════════════════════════════════════════════════════

Home Server (192.168.x.x)
    │
    │ Initiates WireGuard connection (outbound - works through CGNAT!)
    ▼
Router (172.18.x.x)
    │
    │ NAT translation (outbound traffic allowed)
    ▼
ISP CGNAT (206.84.x.x)
    │
    │ Forwards to internet
    ▼
VPS (45.x.x.x:51820)
    │
    └─► Accepts connection and maintains tunnel

✅ Tunnel established: Home Server ←═══► VPS



Step 2: You Connect from Remote Location
═══════════════════════════════════════════════════════════════

Remote Laptop
    │
    │ Connect to VPS (public IP, always reachable)
    ▼
VPS (45.x.x.x:51820)
    │
    └─► Accepts your connection

✅ Second tunnel: Remote Laptop ←═══► VPS



Step 3: Access Home Server
═══════════════════════════════════════════════════════════════

Remote Laptop
    │
    │ SSH to 10.14.14.2 (home server's VPN IP)
    ▼
VPS (forwards via routing table)
    │
    │ Looks at routing: 10.14.14.2 → send via Tunnel 2
    ▼
Home Server
    │
    └─► Receives packet via existing tunnel

✅ Traffic flow: Remote ═► VPS ═► Home Server
```

---

## ✅ Solution 2: Tailscale (Coordination Servers)

**Key Concept:** Both devices connect to Tailscale's coordination servers (outbound only)

```
┌────────────────────────────────────────────────────────────────────────┐
│                            INTERNET                                     │
└────────────────────────────────────────────────────────────────────────┘
         │                              │                        │
         │                              │                        │
    ┌────▼────┐                   ┌─────▼──────┐         ┌──────▼──────┐
    │ Remote  │                   │ Tailscale  │         │  ISP CGNAT  │
    │ Laptop  │                   │ Control    │         │  206.x.x.x  │
    │         │                   │ Servers    │         │             │
    └────┬────┘                   │            │         └──────┬──────┘
         │                        │ (Cloud)    │                │
         │  1. Register           │            │ 2. Register    │
         ├───────────────────────►│            │◄───────────────┤
         │    & get peer list     │            │   & get peer   │
         │                        │            │     list       │
         │                        └────────────┘                │
         │                                                      │
         │                                                      │
         │  4. Try direct P2P connection (STUN/ICE)            │
         │      (Often succeeds even through CGNAT!)           │
         │  ┌──────────────────────────────────────────────┐   │
         │  │  If direct works:                            │   │
         │  │  Remote ←═══════════════════════════════════╬═══┤
         │  │   Laptop          Direct P2P               Home  │
         │  │                   (encrypted)             Server │
         │  └──────────────────────────────────────────────┘   │
         │                                                      │
         │  5. If direct fails, use DERP relay:                │
         │     ┌──────────────────────────────────┐            │
         │     │    Tailscale DERP Relay          │            │
         │     │    (Closest datacenter)          │            │
         │     │                                  │            │
         ├────►│◄─────────────────────────────────┼────────────┤
         │     └──────────────────────────────────┘            │
         │            Encrypted relay                          │
         │                                                  ┌───▼────┐
         │                                                  │ Router │
         │                                                  │172.18.x│
         │                                                  └───┬────┘
         │                                                      │
         │                                                  ┌───▼────┐
         └─────────────────────────────────────────────────►│  Home  │
                          6. Access server                  │ Server │
                                                            │10.x.x.x│
                                                            └────────┘

┌──────────────────────────────────────────────────────────────┐
│ HOW IT WORKS:                                                 │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│ 1. Both Devices Register (Outbound Connections)              │
│    • Home server → Tailscale control servers                 │
│    • Remote laptop → Tailscale control servers               │
│    • Both connections are OUTBOUND (CGNAT allows!)           │
│                                                               │
│ 2. Coordination                                               │
│    • Control servers tell each device about the other        │
│    • Exchange public keys, IP addresses                      │
│                                                               │
│ 3. NAT Traversal (STUN/ICE)                                  │
│    • Devices attempt direct P2P connection                   │
│    • Uses STUN to punch through NAT/CGNAT                    │
│    • Often succeeds! (70-80% of cases)                       │
│                                                               │
│ 4. Fallback to DERP Relay                                    │
│    • If direct fails, use Tailscale relay servers            │
│    • Both devices maintain outbound connection to relay      │
│    • Relay forwards encrypted packets                        │
│                                                               │
│ ✅ Result: P2P or relayed access, no port forwarding!       │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

**NAT Traversal Details:**

```
┌─────────────────────────────────────────────────────────────────┐
│           Tailscale NAT Traversal (How it Beats CGNAT)          │
└─────────────────────────────────────────────────────────────────┘

Step 1: Both devices connect to STUN server
══════════════════════════════════════════════

Home Server                              Remote Laptop
     │                                           │
     │ "What's my public IP?"                    │ "What's my public IP?"
     ▼                                           ▼
   STUN Server (Tailscale runs these)
     │                                           │
     │ "You're 206.84.x.x:41641"              │ "You're 85.10.x.x:52341"
     │                                           │
     ▼                                           ▼
Gets external IP/port                     Gets external IP/port


Step 2: Exchange connection info via control server
═══════════════════════════════════════════════════

Home Server                    Control Server              Remote Laptop
     │                                │                           │
     ├───────────────────────────────►│                           │
     │ "I'm at 206.84.x.x:41641"   │                           │
     │                                ├──────────────────────────►│
     │                                │ "Home is at 206.x:41641" │
     │                                │                           │
     │                                │◄──────────────────────────┤
     │                                │ "Remote at 85.x:52341"   │
     │◄───────────────────────────────┤                           │
     │ "Remote is at 85.10.x.x:52341"                          │


Step 3: Simultaneous hole punching
═══════════════════════════════════════

Home Server                                           Remote Laptop
     │                                                        │
     │ Send packet to 85.10.x.x:52341                       │
     │ (Creates outbound NAT mapping)                         │
     │                                                        │
     ├───────────────────► CGNAT ──────────────►             │
     │                   (Opens hole)                         │
     │                                          ◄─────────────┤
     │              ◄──── CGNAT ◄───────────────┤             │
     │                   (Allows inbound because              │
     │                    of existing mapping!)               │
     ◄────────────────────────────────────────────────────────┤
                  Direct P2P connection established!

✅ Magic: Both sides punch holes simultaneously
✅ CGNAT allows packets because they match existing outbound sessions
```

---

## ✅ Solution 3: Cloudflare Tunnel (Outbound Only)

**Key Concept:** Your server initiates connection to Cloudflare (outbound works through CGNAT)

```
┌────────────────────────────────────────────────────────────────────────┐
│                            INTERNET                                     │
└────────────────────────────────────────────────────────────────────────┘
         │                              │                        │
         │                              │                        │
    ┌────▼────┐                   ┌─────▼──────┐         ┌──────▼──────┐
    │ Remote  │                   │ Cloudflare │         │  ISP CGNAT  │
    │ Laptop  │                   │ Edge       │         │  206.x.x.x  │
    │ Browser │                   │ Network    │         │             │
    └────┬────┘                   │            │         └──────┬──────┘
         │                        │ Global CDN │                │
         │                        │            │                │
         │ 3. User Access         │            │ 1. Outbound    │
         │    (HTTPS)             │            │    Tunnel      │
         │                        │            │    Connection  │
         ├───────────────────────►│            │                │
         │                        │            │                │
         │ https://ssh.domain.com │            │◄───────────────┤
         │                        │            │                │
         │                        │            │                │
         │                        │  ┌─────────┤          ┌─────▼─────┐
         │                        │  │ Tunnel  │          │  Router   │
         │                        │  │ Server  │          │172.18.2.x │
         │                        │  │         │          └─────┬─────┘
         │                        │  │ Proxies │                │
         │                        │  │ Traffic │          ┌─────▼─────┐
         │                        │  └─────────┘          │     Home  │
         │                        │            │          │  Server   │
         │                        │            │          │           │
         │                        │            │◄─────────┤           │
         │                        │            │          │192.168.0.x│
         │                        │            │          │           │
         │                        │            │ 2. cloudflared daemon│
         │                        │            │    maintains tunnel  │
         │                        │            │    (persistent)      │
         │                        └────────────┘          └───────────┘
         │
         └────────► 4. Cloudflare forwards to home server via tunnel


┌──────────────────────────────────────────────────────────────┐
│ HOW IT WORKS:                                                 │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│ 1. Home Server Initiates (Outbound)                         │
│    • cloudflared daemon starts on server                     │
│    • Connects to Cloudflare edge (outbound - CGNAT allows!)  │
│    • Creates 4 persistent QUIC tunnels                       │
│    • Registers tunnel ID and services                        │
│                                                               │
│ 2. Tunnel Stays Alive                                         │
│    • Server → Cloudflare connection always active            │
│    • No inbound ports needed                                 │
│    • Survives IP changes (CGNAT reassignments)               │
│                                                               │
│ 3. User Accesses Service                                     │
│    • Browser goes to https://ssh.yourdomain.com              │
│    • DNS points to Cloudflare (CNAME record)                 │
│    • Cloudflare receives request                             │
│                                                               │
│ 4. Cloudflare Proxies Request                                │
│    • Looks up tunnel for ssh.yourdomain.com                  │
│    • Forwards request through tunnel to home server         │
│    • Server processes request (SSH/RDP/HTTP)                 │
│    • Response goes back through tunnel                       │
│    • Cloudflare sends to user                                │
│                                                               │
│ ✅ Result: Browser-based access, no ports exposed!          │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

**Detailed Connection Flow:**

```
┌─────────────────────────────────────────────────────────────────┐
│         Cloudflare Tunnel - Step by Step                        │
└─────────────────────────────────────────────────────────────────┘

Step 1: Server Establishes Tunnel (Once, at startup)
════════════════════════════════════════════════════════

Home Server (192.168.x.x)
    │
    │ cloudflared daemon starts
    ▼
Router (172.18.x.x)
    │
    │ Outbound HTTPS connection (CGNAT allows)
    ▼
ISP CGNAT (206.84.x.x)
    │
    │ Forwards outbound traffic
    ▼
Cloudflare Edge Network
    │
    │ Accepts tunnel connection
    │ Assigns to nearest edge servers
    ▼
4x Persistent Connections Established
    │
    └─► Tunnel ready to receive requests

✅ Tunnel: Home Server ═══► Cloudflare (stays connected)



Step 2: User Visits https://ssh.yourdomain.com
══════════════════════════════════════════════════

Remote Laptop Browser
    │
    │ DNS lookup: ssh.yourdomain.com
    ▼
DNS Server
    │
    │ Returns: CNAME → tunnel-id.cfargotunnel.com
    │           A → Cloudflare IP (104.x.x.x)
    ▼
Browser connects to Cloudflare (HTTPS)
    │
    ▼
Cloudflare Edge Server (nearest location)



Step 3: Cloudflare Routes Request Through Tunnel
═════════════════════════════════════════════════

Cloudflare Edge (Nearest)
    │
    │ Lookup: ssh.yourdomain.com → Tunnel ID
    │ Check tunnel config: Port 22 (SSH)
    ▼
Find active tunnel connection to home server
    │
    │ Send request through persistent tunnel
    ▼
Home Server receives request (via existing tunnel)
    │
    │ SSH service on port 22 processes request
    ▼
Response sent back through tunnel
    │
    ▼
Cloudflare Edge → Remote Browser



Step 4: Browser-Based SSH Session
══════════════════════════════════════

Remote Browser
    │
    │ Full terminal rendered in browser
    │ All traffic encrypted: Browser ← TLS → Cloudflare ← Tunnel → Server
    ▼
Interactive SSH session
    │
    └─► No VPN client needed!
        No ports opened on server!
        Works through CGNAT!
```

---

## 📊 Side-by-Side Comparison

```
┌──────────────────────────────────────────────────────────────────┐
│              HOW EACH SOLUTION HANDLES CGNAT                      │
└──────────────────────────────────────────────────────────────────┘

╔═════════════════════════════════════════════════════════════════╗
║  VPS RELAY                                                       ║
╠═════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Connection Direction:                                           ║
║  Home Server ────outbound────► VPS (has public IP)             ║
║  Your Device  ────outbound────► VPS                             ║
║                                                                  ║
║  Key Insight: Both connections are OUTBOUND                      ║
║               CGNAT doesn't block outbound!                      ║
║                                                                  ║
║  Pros: Full control, learn WireGuard, Oracle Cloud FREE         ║
║  Cons: 30 min setup, manage VPS, ~20-50ms latency              ║
║                                                                  ║
╚═════════════════════════════════════════════════════════════════╝

╔═════════════════════════════════════════════════════════════════╗
║  TAILSCALE                                                       ║
╠═════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Connection Direction:                                           ║
║  Home Server ────outbound────► Tailscale Control Servers       ║
║  Your Device  ────outbound────► Tailscale Control Servers       ║
║  Then: Attempt direct P2P via NAT hole punching                 ║
║                                                                  ║
║  Key Insight: Magic! Often achieves direct P2P even through     ║
║               CGNAT using STUN/ICE techniques                    ║
║               Fallback: DERP relay (still outbound)              ║
║                                                                  ║
║  Pros: 5 min setup, often direct P2P, exit node feature         ║
║  Cons: Relies on Tailscale service                              ║
║                                                                  ║
╚═════════════════════════════════════════════════════════════════╝

╔═════════════════════════════════════════════════════════════════╗
║  CLOUDFLARE TUNNEL                                               ║
╠═════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Connection Direction:                                           ║
║  Home Server ────outbound────► Cloudflare Edge Network         ║
║  Your Browser ────outbound────► Cloudflare Edge Network         ║
║                                                                  ║
║  Key Insight: Server maintains persistent outbound tunnel       ║
║               All inbound requests proxied by Cloudflare         ║
║               No ports ever opened on your server                ║
║                                                                  ║
║  Pros: Browser access, DDoS protection, SSL certs, CDN          ║
║  Cons: No exit node feature                                     ║
║                                                                  ║
╚═════════════════════════════════════════════════════════════════╝
```

---

## 🎯 The Common Pattern

**All CGNAT bypass solutions use the same principle:**

```
┌────────────────────────────────────────────────────────────┐
│                                                             │
│  THE GOLDEN RULE OF CGNAT BYPASS:                          │
│                                                             │
│  ✅ Outbound connections ALWAYS work through CGNAT         │
│  ❌ Inbound connections NEVER work through CGNAT           │
│                                                             │
│  Solution: Make your server INITIATE the connection        │
│                                                             │
└────────────────────────────────────────────────────────────┘

Traditional VPN (FAILS):
═══════════════════════════
Internet → Router (private IP) → Server ❌
         ↑ Inbound doesn't work!

VPS Relay (WORKS):
═══════════════════════════
Server → Router → CGNAT → Internet → VPS ✅
       ↑ Outbound works!

Tailscale (WORKS):
═══════════════════════════
Server → Router → CGNAT → Internet → Tailscale Control ✅
       ↑ Outbound works!

Cloudflare Tunnel (WORKS):
═══════════════════════════
Server → Router → CGNAT → Internet → Cloudflare Edge ✅
       ↑ Outbound works!
```

---

## 💡 Why Your Port Forwarding Failed

```
What you configured:
═══════════════════════════════════════════════════════

Router Port Forward Rule:
External Port 51820 → 192.168.x.x:51820

What happens when someone tries to connect:
═══════════════════════════════════════════════════════

Step 1: They send packet to 206.84.x.x:51820
        (Your "public" IP from curl ifconfig.me)
        
Step 2: Packet arrives at ISP's CGNAT server
        CGNAT receives it at 206.84.x.x:51820
        
Step 3: CGNAT asks: "Which customer owns this?"
        Problem: 1000s of customers share this IP!
        CGNAT has NO IDEA which router to send it to!
        
Step 4: Packet is DROPPED ❌
        Never reaches your router
        Your port forwarding rule never gets a chance to work
        
═══════════════════════════════════════════════════════

ISP's CGNAT (206.84.x.x)
    │
    ├── Customer 1 Router (172.18.x.x)
    ├── Customer 2 Router (172.18.x.x)
    ├── Customer 3 Router (172.18.x.x)
    ├── YOU → Router (172.18.x.x) ← Your router
    ├── Customer 5 Router (172.18.x.x)
    └── ... 1000s more customers

When packet arrives at 206.84.x.x:51820:
"Which router should receive this?" → UNKNOWN! → DROP

When YOUR router sends packet OUT:
CGNAT creates temporary mapping: 172.18.x.x:51820 → 206.84.x.x:RANDOM_PORT
This mapping expires after ~60 seconds of inactivity
```

---

## 🔑 Key Takeaways

### ✅ What Works:

1. **Outbound-initiated connections**
   - Your server connects OUT to somewhere
   - CGNAT allows outbound traffic
   - Connection stays alive with keepalive packets

2. **Middleman with public IP**
   - VPS Relay: Your VPS
   - Tailscale: Their control/relay servers
   - Cloudflare: Their edge network

3. **NAT hole punching (sometimes)**
   - Tailscale's STUN/ICE magic
   - Works ~70-80% of time
   - Creates temporary bidirectional paths

### ❌ What Doesn't Work:

1. **Port forwarding on your router**
   - Router doesn't have public IP
   - CGNAT doesn't know where to send packets

2. **DuckDNS pointing to your "public" IP**
   - That IP is shared by thousands
   - Can't uniquely identify your server

3. **Traditional VPN server setup**
   - Requires inbound connections
   - CGNAT blocks them all

---

## 🎓 Summary

**The Fundamental Problem:**
```
CGNAT = Your router doesn't have a unique public IP
      = Inbound connections impossible
      = Port forwarding useless
```

**The Universal Solution:**
```
Reverse the connection direction!
Your server reaches OUT to somewhere reachable
That somewhere has a real public IP
It becomes the bridge/relay/proxy
```

**That's why all three solutions work! 🎉**

