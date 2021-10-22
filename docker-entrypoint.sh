#!/usr/bin/env bash

# shellcheck disable=SC2154
if [[ -n "${TZ}" ]]; then
  echo "Setting timezone to ${TZ}"
  ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone
fi

cd /aedge-blockchain || exit 1

# shellcheck disable=SC1091
. ./activate

aedge init --fix-ssl-permissions

if [[ ${testnet} == 'true' ]]; then
   echo "configure testnet"
   aedge configure --testnet true
fi

if [[ ${keys} == "persistent" ]]; then
  echo "Not touching key directories"
elif [[ ${keys} == "generate" ]]; then
  echo "to use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
  aedge keys generate
elif [[ ${keys} == "copy" ]]; then
  if [[ -z ${ca} ]]; then
    echo "A path to a copy of the farmer peer's ssl/ca required."
	exit
  else
  aedge init -c "${ca}"
  fi
else
  aedge keys add -f "${keys}"
fi

for p in ${plots_dir//:/ }; do
    mkdir -p "${p}"
    if [[ ! $(ls -A "$p") ]]; then
        echo "Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
    fi
    aedge plots add -d "${p}"
done

if [[ -n "${log_level}" ]]; then
  aedge configure --log-level "${log_level}"
fi

sed -i 's/localhost/127.0.0.1/g' "$CONFIG_ROOT/config/config.yaml"

exec "$@"
