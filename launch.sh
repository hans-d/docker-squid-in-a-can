#!/bin/bash

CONF=/etc/squid3/squid.conf

SQUID_MAX_OBJ_SIZE=${SQUID_MAX_OBJ_SIZE:-1024}
SQUID_MAX_MEM_OBJ_SIZE=${SQUID_MAX_MEM_OBJ_SIZE:-50}
SQUID_MAX_CACHE_SIZE=${SQUID_MAX_CACHE_SIZE:-5000}

SQUID_PARENT_HOST=${SQUID_PARENT_HOST:-}
SQUID_PARENT_PORT=${SQUID_PARENT_PORT:-3128}
SQUID_PARENT_PORT_UDP=${SQUID_PARENT_PORT_UDP:-0}

SQUID_ACL=${SQUID_ACL:-}
SQUID_ALWAYS_DIRECT=${SQUID_ALWAYS_DIRECT:-}
SQUID_NEVER_DIRECT=${SQUID_NEVER_DIRECT:-}
if [ -z "${SQUID_NEVER_DIRECT}${SQUID_ALWAYS_DIRECT}" ]; then
  SQUID_NEVER_DIRECT="allow all"
fi

if [ -n "${SQUID_PARENT_HOST}" ]; then
  SQUID_PARENT_ENABLED=${SQUID_PARENT_ENABLED:-true}
fi
SQUID_PARENT_ENABLED=${SQUID_PARENT_ENABLED:-false}

# update rights
chown -R proxy:proxy /var/cache/squid3

# change config
# - cache size
echo "maximum_object_size ${SQUID_MAX_OBJ_SIZE} MB" >> $CONF
echo "maximum_object_size_in_memory ${SQUID_MAX_MEM_OBJ_SIZE} MB" >> $CONF
echo "cache_dir ufs /var/cache/squid3 ${SQUID_MAX_CACHE_SIZE} 16 256" >> $CONF

# - upstream proxy
if [ "${SQUID_PARENT_ENABLED}" == "true" ]; then
  echo "cache_peer ${SQUID_PARENT_HOST} parent ${SQUID_PARENT_PORT} ${SQUID_PARENT_PORT_UDP} no-query default" >> $CONF
  
  IFS=";" read -ra ACL <<< "$SQUID_ACL"
  for i in "${ACL[@]}"; do
    echo "acl ${i}" >> $CONF
  done

  IFS=";" read -ra DIRECT <<< "$SQUID_ALWAYS_DIRECT"
  for i in "${DIRECT[@]}"; do
    echo "always_direct ${i}" >> $CONF
  done

  IFS=";" read -ra DIRECT <<< "$SQUID_NEVER_DIRECT"
  for i in "${DIRECT[@]}"; do
    echo "never_direct ${i}" >> $CONF
  done

fi

# start
if [ $# -eq 0 ]; then
  squid3 -N
  exit
fi

if [ "$1" == "redirect" ]; then
  iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to 3129   
  exit
fi

"$@"

