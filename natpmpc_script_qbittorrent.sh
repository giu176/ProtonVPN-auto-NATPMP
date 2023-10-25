#!/bin/bash
# Path to the qbittorrent-nox.service file
service_file="/etc/systemd/system/qbittorrent-nox.service"
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
    current_port=$(grep -Po --max-count=1 '(?<=--torrenting-port=)[0-9]+' "$service_file")

    # Check if $current_port is different from $port
    if [ "$current_port" != "$port" ]; then
        # Stop the qbittorrent-nox service
        service qbittorrent-nox stop
        echo "Current port is different. Changing from $current_port to $port"
        # Update the service file with the new port
        sed -i "s/--torrenting-port=$current_port/--torrenting-port=$port/" "$service_file"
        # Reoload services
        systemctl daemon-reload 
        # Start the qbittorrent-nox service with the new port
        service qbittorrent-nox start
    fi
    sleep 45
done
