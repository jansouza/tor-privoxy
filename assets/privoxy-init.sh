#!/bin/bash
set -e

CONFFILE=/etc/privoxy/config

echo "[PRIVOXY] Starting Privoxy configuration..."

LOG_LEVEL_ENV=$(printenv | grep 'PRIVOXY_LOG_LEVEL')
LOG_LEVEL_VAL="${LOG_LEVEL_ENV##*=}"
for level in ${LOG_LEVEL_VAL//,/ }; do
    sed -i -e "/^#debug[[:space:]]\+$level/s/#//" "${CONFFILE}"
done

while read -r env; do
    name="$(cut -c9- <<< ${env%%=*})"
    val="${env##*=}"
    [[ "$name" =~ _ ]] && continue
    echo "[PRIVOXY] Set Config: $name = $val"
    if grep -q "^$name" ${CONFFILE}; then
        sed -i "/^$name/s| .*| $val|" ${CONFFILE}
    else
        echo "$name $val" >>${CONFFILE}
    fi
done <<< $(printenv | grep '^PRIVOXY_'| grep -v 'PRIVOXY_LOG_LEVEL')


echo "[PRIVOXY] Privoxy configuration applied. Starting Privoxy..."

# Start Privoxy
exec /usr/sbin/privoxy --no-daemon ${CONFFILE} 2>&1 | awk '{print "[PRIVOXY] " $0}'