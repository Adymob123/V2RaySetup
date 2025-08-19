#!/bin/bash
# block-abuse-ips.sh
# Fetches Spamhaus + FireHOL lists, loads them into ipset,
# and blocks outbound traffic with iptables/ip6tables.

set -euo pipefail

# Lists to fetch
LISTS=(
  "https://www.spamhaus.org/drop/drop.txt"
  "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset"
)

# Set names
IPV4_SET="abuse_v4"
IPV6_SET="abuse_v6"

# Create ipsets if not exist
ipset create "$IPV4_SET" hash:net family inet -exist maxelem 1048576
ipset create "$IPV6_SET" hash:net family inet6 -exist maxelem 1048576

# Temporary sets for atomic refresh
TMP_V4="${IPV4_SET}_tmp"
TMP_V6="${IPV6_SET}_tmp"
ipset create "$TMP_V4" hash:net family inet -exist maxelem 1048576
ipset create "$TMP_V6" hash:net family inet6 -exist maxelem 1048576

# Temporary file
TMPFILE=$(mktemp)

for url in "${LISTS[@]}"; do
  curl -fsSL "$url" -o "$TMPFILE" || continue

  while read -r net; do
    [[ -z "$net" ]] && continue
    if [[ "$net" == *:* ]]; then
      ipset add "$TMP_V6" "$net" -exist
    else
      ipset add "$TMP_V4" "$net" -exist
    fi
  done < <(grep -Eo '^[0-9a-fA-F:.]+/[0-9]+' "$TMPFILE")
done

rm -f "$TMPFILE"

# Additional manual IPs (IPv4 only here, add IPv6 if needed)
ADDITIONAL_IPS=(
  "5.79.71.205"
  "5.79.71.225"
  "85.17.31.82"
  "104.156.155.94"
  "178.162.203.202"
  "178.162.217.107"
)

for ip in "${ADDITIONAL_IPS[@]}"; do
  ipset add "$TMP_V4" "$ip" -exist
done

# Atomic swap
ipset swap "$TMP_V4" "$IPV4_SET"
ipset swap "$TMP_V6" "$IPV6_SET"
ipset destroy "$TMP_V4"
ipset destroy "$TMP_V6"

# Ensure iptables rules exist (idempotent)
iptables -C OUTPUT -m set --match-set "$IPV4_SET" dst -j DROP 2>/dev/null \
  || iptables -A OUTPUT -m set --match-set "$IPV4_SET" dst -j DROP

ip6tables -C OUTPUT -m set --match-set "$IPV6_SET" dst -j DROP 2>/dev/null \
  || ip6tables -A OUTPUT -m set --match-set "$IPV6_SET" dst -j DROP