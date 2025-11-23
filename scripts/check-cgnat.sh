#!/bin/bash
#
# CGNAT Detection Script
# Checks if you're behind Carrier-Grade NAT
#

set -e

echo "================================================"
echo "🔍 CGNAT Detection Test"
echo "================================================"
echo ""

# Get public IP from external service
echo "📡 Checking your public IP address..."
PUBLIC_IP=$(curl -s ifconfig.me)

if [ -z "$PUBLIC_IP" ]; then
    echo "❌ Error: Could not determine public IP"
    echo "   Make sure you have internet connectivity"
    exit 1
fi

echo "✅ Public IP (from ifconfig.me): $PUBLIC_IP"
echo ""

# Analyze IP
echo "================================================"
echo "📋 IP Analysis:"
echo "================================================"

# Check if IP is in private/CGNAT ranges
if [[ "$PUBLIC_IP" =~ ^10\. ]]; then
    echo "⚠️  IP starts with 10.x.x.x"
    echo "   This is a PRIVATE IP range (RFC 1918)"
    LIKELY_CGNAT=true
elif [[ "$PUBLIC_IP" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]]; then
    echo "⚠️  IP starts with 172.16-31.x.x"
    echo "   This is a PRIVATE IP range (RFC 1918)"
    LIKELY_CGNAT=true
elif [[ "$PUBLIC_IP" =~ ^192\.168\. ]]; then
    echo "⚠️  IP starts with 192.168.x.x"
    echo "   This is a PRIVATE IP range (RFC 1918)"
    LIKELY_CGNAT=true
elif [[ "$PUBLIC_IP" =~ ^100\.(6[4-9]|[7-9][0-9]|1[0-1][0-9]|12[0-7])\. ]]; then
    echo "⚠️  IP starts with 100.64-127.x.x"
    echo "   This is CGNAT range (RFC 6598)"
    LIKELY_CGNAT=true
else
    echo "✅ IP appears to be a public address"
    LIKELY_CGNAT=false
fi

echo ""

# Instructions
echo "================================================"
echo "📝 Next Steps:"
echo "================================================"
echo ""
echo "1. Log into your router admin panel:"
echo "   URL: http://192.168.0.1 (or your router IP)"
echo ""
echo "2. Navigate to: Status → WAN (or Internet Status)"
echo ""
echo "3. Find the 'WAN IP Address' or 'Internet IP'"
echo ""
echo "4. Compare it with the public IP above:"
echo "   Public IP:  $PUBLIC_IP"
echo "   Router WAN: _______________ (write it down)"
echo ""
echo "================================================"
echo "🎯 Interpretation:"
echo "================================================"
echo ""

if [ "$LIKELY_CGNAT" = true ]; then
    echo "❌ YOUR PUBLIC IP LOOKS SUSPICIOUS!"
    echo ""
    echo "Your public IP ($PUBLIC_IP) is in a private/CGNAT range."
    echo "This STRONGLY indicates you are behind CGNAT."
    echo ""
    echo "⚠️  Port forwarding WILL NOT WORK"
    echo ""
    echo "📚 See the VPN.md guide, section:"
    echo "   '🚨 CRITICAL: Check for CGNAT First!'"
    echo ""
    echo "🔧 You will need to use one of these solutions:"
    echo "   1. Request static public IP from ISP (recommended)"
    echo "   2. Use VPS relay setup (see CGNAT Workaround Guide)"
    echo "   3. Use Tailscale/ZeroTier (easiest)"
    echo ""
else
    echo "If Router WAN IP = $PUBLIC_IP:"
    echo "   ✅ NO CGNAT - You're good to go!"
    echo "   → Continue with standard VPN setup"
    echo ""
    echo "If Router WAN IP ≠ $PUBLIC_IP:"
    echo "   ❌ CGNAT DETECTED - Port forwarding won't work"
    echo "   → Use alternative solutions (see VPN.md)"
fi

echo ""
echo "================================================"
echo ""

# Prompt for router WAN IP
read -p "Enter your Router WAN IP address (or press Enter to skip): " ROUTER_WAN

if [ ! -z "$ROUTER_WAN" ]; then
    echo ""
    echo "================================================"
    echo "🔬 Comparison:"
    echo "================================================"
    echo "Public IP:  $PUBLIC_IP"
    echo "Router WAN: $ROUTER_WAN"
    echo ""
    
    if [ "$PUBLIC_IP" = "$ROUTER_WAN" ]; then
        echo "✅✅✅ MATCH! NO CGNAT DETECTED ✅✅✅"
        echo ""
        echo "🎉 Great news! You have a routable public IP."
        echo "   Port forwarding will work."
        echo "   You can proceed with the standard VPN setup!"
        echo ""
    else
        echo "❌❌❌ DIFFERENT! CGNAT DETECTED ❌❌❌"
        echo ""
        echo "⚠️  You are behind CGNAT."
        echo "   Traditional port forwarding WILL NOT work."
        echo ""
        echo "📚 Open VPN.md and go to:"
        echo "   'Alternative Solutions for CGNAT'"
        echo ""
        echo "Recommended options:"
        echo "   • Contact ISP for static public IP ($5-15/month)"
        echo "   • Use Oracle Cloud VPS relay (FREE)"
        echo "   • Use Tailscale (easiest, free)"
        echo ""
    fi
fi

echo "================================================"
echo ""
