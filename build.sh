#!/bin/bash
set -e

podman build -t tor-privoxy-img .

podman run -d \
  --name tor-privoxy \
  -p 9050:9050 \
  -p 9051:9051 \
  -p 8118:8118 \
  -e TOR_SOCKSPort=9050 \
  -e TOR_ControlPort=9051 \
  -e TOR_CookieAuthentication=1 \
  -e TOR_CookieAuthFileGroupReadable=1 \
  -e TOR_CookieAuthFile=/var/lib/tor/control_auth_cookie \
  -e PRIVOXY_listen-address=0.0.0.0:8118 \
  tor-privoxy-img

podman ps