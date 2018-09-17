#!/bin/sh

set -x

IP=$(ip route show |grep -o src.* |cut -f2 -d" ")
NETWORK=$(echo ${IP} | cut -f3 -d.)

case "${NETWORK}" in
  100)
    zone=a
    color=Crimson
    ;;
  101)
    zone=b
    color=CornflowerBlue
    ;;
  102)
    zone=c
    color=LightGreen
    ;;
  *)
    zone=unknown
    color=Yellow
    ;;
esac

# kubernetes sets routes differently -- so we will discover our IP differently
if [[ ${IP} == "" ]]; then
  IP=$(hostname -i)
fi

# Am I on ec2 instances?
if [[ ${zone} == "unknown" ]]; then
  zone=$(curl -m2 -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.availabilityZone' | grep -o .$)
fi

export CODE_HASH="$(cat code_hash.txt)"
export AZ="${IP} in AZ-${zone}"

# exec bundle exec thin start
RAILS_ENV=production rake assets:precompile
exec rails s -e production -b 0.0.0.0
