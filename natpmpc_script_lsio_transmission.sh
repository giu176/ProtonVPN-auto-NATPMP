#!/bin/bash
# This script is designed to run in https://docs.linuxserver.io/images/docker-transmission/
# It can be loaded at startup as described at https://www.linuxserver.io/blog/2019-09-14-customizing-our-containers

# wait for wireguard / network DNS up, as seen in https://github.com/sebdanielsson/compose-transmission-wireguard
sleep 2

# install deps
apk update && apk add moreutils libnatpmp || exit 1 # deps: natpmpc & sponge

# Path to the config file
config_file="/config/settings.json"
while true; do
    date

    # Run natpmpc for UDP and TCP, redirect output to a temporary file
    natpmpc -a 1 0 udp 60 -g 10.2.0.1 && natpmpc -a 1 0 tcp 60 -g 10.2.0.1 > /tmp/natpmpc_output || { 
        echo -e "ERROR with natpmpc command \a" 
        break
    }

    # Extract the port numbers from the output and save them in variables
    port=$(grep 'TCP' /tmp/natpmpc_output | grep -o 'Mapped public port [0-9]*' | awk '{print $4}')

    echo "Opened port: $port"
    # Get the current --torrenting-port from the service file
    current_port=$(jq -r '."peer-port"' < "$config_file")

    # Check if $current_port is different from $port
    if [ "$current_port" != "$port" ]; then
        echo "Current port is different. Changing from $current_port to $port"
        # Update the service file with the new port
        jq -r --argjson p "$port" '."peer-port" = $p' "$config_file" | sponge "$config_file"
	# reload transmission config:
        # https://github.com/transmission/transmission/blob/86498a71e5074affdb1eedd48074ce8eee8d8089/docs/Editing-Configuration-Files.md
        killall -HUP transmission-daemon
    fi
    sleep 47
done &

echo "Transmission Proton Port forward script started."
