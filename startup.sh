#!/bin/sh

set -x

IP=$(ip route show |grep -o src.* |cut -f2 -d" ")
NETWORK=$(echo ${IP} | cut -f3 -d.)

case "${NETWORK}" in
  100)
    zone=1a
    color=Crimson
    ;;
  101)
    zone=1b
    color=CornflowerBlue
    ;;
  102)
    zone=1c
    color=LightGreen
    ;;
  *)
    zone=unknown
    color=Yellow
    ;;
esac

export CODE_HASH="$(cat code_hash.txt)"
export AZ="${IP} in AZ-${zone}"

# exec bundle exec thin start
RAILS_ENV=production rake assets:precompile
exec rails s -e production -b 0.0.0.0
