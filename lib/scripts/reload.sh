#!/bin/bash

set -e

CVC_DIR="/count-von-count"
SCRIPT_DIR="${CVC_DIR}/lib/scripts"
NGINX_DIR="/opt/openresty/nginx"

rm -f $NGINX_DIR/conf/include/vars.conf
echo 'set $redis_counter_hash '$(redis-cli SCRIPT LOAD "$(cat "${CVC_DIR}/lib/redis/voncount.lua")")';' > $NGINX_DIR/conf/vars.conf
redis-cli set von_count_config_live $(cat "${CVC_DIR}/config/voncount.config" | tr -d '\n' | tr -d ' ')
$NGINX_DIR/sbin/nginx -s reload || true
