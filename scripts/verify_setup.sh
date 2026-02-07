#!/bin/bash

echo "=== VPS Security Verification (Expert) ==="

# Check UFW
echo -n "[Check] UFW... "
if sudo ufw status | grep -q "Status: active"; then
    echo "✅ Active"
else
    echo "❌ Inactive (Run 'sudo ufw enable')"
fi

# Check Unattended Upgrades
echo -n "[Check] Unattended Upgrades... "
if systemctl is-active --quiet unattended-upgrades; then
    echo "✅ Running"
else
    echo "❌ Stopped/Not Installed"
fi

# Check Sysctl Hardening
echo -n "[Check] Sysctl Hardening... "
if sysctl net.ipv4.conf.all.rp_filter | grep -q "1"; then
    echo "✅ Applied"
else
    echo "❌ Not applied (Check /etc/sysctl.d/99-security.conf)"
fi

# Check Tailscale
echo -n "[Check] Tailscale... "
if tailscale status > /dev/null 2>&1; then
    echo "✅ Connected"
else
    echo "❌ Not connected"
fi

# Check Docker & Containers
echo "[Check] Critical Containers:"
for container in traefik crowdsec watchtower; do
    echo -n "  - $container... "
    if docker ps --format '{{.Names}}' | grep -q "$container"; then
        echo "✅ Up"
    else
        echo "⚠️  Not found or stopped"
    fi
done

echo "=== Verification Complete ==="