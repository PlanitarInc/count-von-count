#!/bin/bash

set -e

CVC_DIR="/count-von-count"
SCRIPT_DIR="${CVC_DIR}/lib/scripts"
NGINX_DIR="/opt/openresty/nginx"

redis_load_script() {
  redis-cli SCRIPT LOAD "$(cat "${CVC_DIR}/lib/redis/$1")"
}

rm -f $NGINX_DIR/conf/include/vars.conf
echo 'set $redis_counter_hash '$(redis_load_script voncount.lua)';' > $NGINX_DIR/conf/vars.conf
echo 'set $redis_getdaterange_hash '$(redis_load_script getdaterange.lua)';' >> $NGINX_DIR/conf/vars.conf
echo --------
cat $NGINX_DIR/conf/vars.conf
echo --------
redis-cli set von_count_config_live $(cat "${CVC_DIR}/config/voncount.config" | tr -d '\n' | tr -d ' ')
$NGINX_DIR/sbin/nginx -s reload || true
