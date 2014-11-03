#!/bin/bash

set -e

CVC_DIR="/count-von-count"
SCRIPT_DIR="${CVC_DIR}/lib/scripts"
NGINX_DIR="/opt/openresty/nginx"

${SCRIPT_DIR}/reload.sh
${NGINX_DIR}/sbin/nginx
