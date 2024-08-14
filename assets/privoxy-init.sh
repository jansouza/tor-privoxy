#!/bin/bash
set -e

CONFFILE=/etc/privoxy/config

echo "[PRIVOXY] Starting Privoxy configuration..."

while read -r env; do
    name="$(cut -c9- <<< ${env%%=*})"
    val="${env##*=}"
    echo "[PRIVOXY] Set Config: $name = $val"
    [[ "$name" =~ _ ]] && continue
    if grep -q "^$name" ${CONFFILE}; then
        sed -i "/^$name/s| .*| $val|" ${CONFFILE}
    else
        echo "$name $val" >>${CONFFILE}
    fi
done <<< $(printenv | grep '^PRIVOXY_')

sed -i -e '/^#debug/s/#//' ${CONFFILE}

echo "[PRIVOXY] Privoxy configuration applied. Starting Privoxy..."

# Start Privoxy
exec /usr/sbin/privoxy --no-daemon ${CONFFILE} 2>&1 | awk '{print "[PRIVOXY] " $0}'