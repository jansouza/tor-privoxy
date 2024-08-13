#!/bin/bash
set -e

podman stop tor-privoxy ||true
podman rm tor-privoxy ||true
podman rmi tor-privoxy-img ||true