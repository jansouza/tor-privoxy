#!/bin/bash
set -e

echo "[TOR] Starting Tor configuration..."

LOG_LEVEL_ENV=$(printenv | grep 'TOR_LOG_LEVEL')
LOG_LEVEL_VAL="${LOG_LEVEL_ENV##*=}"
echo "Log $LOG_LEVEL_VAL stdout" >/etc/tor/torrc

while read -r env; do
    name="$(cut -c5- <<< ${env%%=*})"
    val="${env##*=}"
    [[ "$name" =~ _ ]] && continue
    echo "[TOR] Set Config: $name = $val"
    if grep -q "^$name" /etc/tor/torrc; then
        sed -i "/^$name/s| .*| $val|" /etc/tor/torrc
    else
        echo "$name $val" >>/etc/tor/torrc
    fi
done <<< $(printenv | grep '^TOR_')

echo "[TOR] Tor configuration applied. Starting Tor..."

# Start Tor
exec tor -f /etc/tor/torrc | awk '{print "[TOR] " $0}'