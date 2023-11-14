# ProtonVPN-auto-NATPMP
Periodically request port opening to Proton's P2P-optimized servers even without the ProtonVPN offical app and automatically retrieve the port number.

Citing the [ProtonVPN website](https://protonvpn.com/support/port-forwarding/):
> "Port forwarding is currently available in our Windows app for everyone with a paid Proton VPN plan. " 

So if you have manually configured a tunnel on your machine (or you are using Linux) you need to manually enable port forwarding as explained in the [official documentation](https://protonvpn.com/support/port-forwarding-manual-setup/). Port forwarding for tunnels created on a router can be acheived in the same way running the `natpmpc` command from a linux machine inside the network if its traffic is routed through the tunnel.

This script provides an automatic way to enable this feature in unsupported devices and can be customized to pass the number of the opened port to software of your choice, for example [qbittorrent-nox](https://github.com/qbittorrent/qBittorrent/wiki/Running-qBittorrent-without-X-server-(WebUI-only,-systemd-service-set-up,-Ubuntu-15.04-or-newer)) (qbittorrent-nox configuration below).
## Before running the script

The script was tested on a P2P application running on debian 12 connected to a MiktorTikOS VM that routes all the trafffic through a ProtonVPN server. Before you use the script you need to manually configure your device following [Step 1 in Proton VPN official guide](https://protonvpn.com/support/port-forwarding-manual-setup/). It's also recommended to try Step 2 from the same guide to test the command `natpmpc` as the script will use the same code from this guide.

## Installation
 If you tried the code ([Step 2 of the official guide](https://protonvpn.com/support/port-forwarding-manual-setup/)) as recommended you already have all the required software to run the script, otherwise proceed to install `natpmpc`:
 ```sh
sudo apt update
sudo apt upgrade
sudo apt install natpmpc
```
Download the script:
 ```sh
curl https://raw.githubusercontent.com/giu176/ProtonVPN-auto-NATPMP/main/natpmpc_script.sh -o natpmpc_script.sh
```
 Give execute permission:
 ```sh
chmod +x natpmpc_script.sh
```
Now you are ready to launch the script:
 ```sh
./natpmpc_script.sh
```
This will enable port forwarding on the ProtonVPN server, a random port will be assigned. The port will be closed 60 seconds after you close the script with `ctrl+C`.

Output:
```sh
initnatpmp() returned 0 (SUCCESS)
using gateway : 10.2.0.1
sendpublicaddressrequest returned 2 (SUCCESS)
readnatpmpresponseorretry returned 0 (OK)
Public IP address : X.X.X.X
epoch = 77878
sendnewportmappingrequest returned 12 (SUCCESS)
readnatpmpresponseorretry returned 0 (OK)
Mapped public port 65152 protocol UDP to local port 0 liftime 60
epoch = 77878
closenatpmp() returned 0 (SUCCESS)
Opened port: 65152
```
The Public IP address `X.X.X.X` must be your VPN endpoint, if not there is a problem in your ProtonVPN configuration or network setup and the machine is not using the VPN tunnel.

The script will print the output of `natpmpc` alongside with the opened port. You can see the log of the latest output in ` /tmp/natpmpc_output`.

Now you can use the opened port in your P2P application. 

### Run with a systemd service on Linux
If you are running your application on Linux server is raccomended that you use a systemd service.

Create a new file, `/etc/systemd/system/natpmpc_script.service`, and edit it with the appropriate permissions and text editor of your choice, for example:
```cmd
sudo nano /etc/systemd/system/natpmpc_script.service
```

Save the file with the following content. You may modify the service as-needed to better suit your configuration, change `YOURUSER` with the name of the user and check if `ExecStart` is the correct path to the script.
```
[Unit]
Description=Custom Script for NAT-PMP Control
After=network.target

[Service]
Type=simple
ExecStart=/home/YOURUSER/natpmpc_script.sh
Restart=always

[Install]
WantedBy=multi-user.target
```

Then run `sudo systemctl daemon-reload` to update the service manager.

#### Controlling the service

* Start the service: `sudo systemctl start natpmpc_script`
* Check service status: `systemctl status natpmpc_script`
*  To see full log output: `sudo journalctl -u natpmpc_script.service`
* Stop the service: `sudo systemctl stop natpmpc_script`
* Enable it to start up on boot: `sudo systemctl enable natpmpc_script`
* To disable: `sudo systemctl disable natpmpc_script`. It simply disables automatic startup of the natpmpc_script service.

## Testing the port forwarding

1) Lanuch the script either manually or using the service.
2) Retrive the opened port and configure your P2P software to use that specific port (software must respond to the port ping).
3) Connect to an open port checker website that allows you to select a specific IP address (For example https://portchecker.co/ or https://www.yougetsignal.com/tools/open-ports/).
4) Enter as Remote Address the ProtonVPN server IP, called `X.X.X.X` in the previous `natpmpc` output example.
5) Enter as Port Number the port opened by  `natpmpc`.
6) Check the port.

If the port is OPEN on the VPN endpoint you are done! Otherwise you can wait a minute and retry the test or check your configuration:
- Check your P2P application (the opened port must be in use).
- Check the script or the service log.
- Check the ProtonVPN tunnel configuration.
- Check your network.

## Customize the script
If you followed the Installation paragraph you have installed a basic version of the script that is basically a copy-paste of the loop in the from the official ProtonVPN guide with the exception that now it will run automatically in the background at the server startup. 
While in operation you should receive the same opened port at any renewal but stopping the service (or the script) and performing any other action that will lead to a shut down of the VPN tunnel will also interrupt the port forwarding. ProtonVPN doesn't assign a port to a user (by design) so after an interruption a new `natpmpc` request will give you a new port number.
If you have access to a configuration file for your P2P application it will be useful to automatically update the listening port of the application.

### qBittorrent integration
A useful application of the script is to dynamically change the listening port of [qbittorrent-nox](https://github.com/qbittorrent/qBittorrent/wiki/Running-qBittorrent-without-X-server-(WebUI-only,-systemd-service-set-up,-Ubuntu-15.04-or-newer)). 

Replace the script with the modified one:
 ```sh
curl https://raw.githubusercontent.com/giu176/ProtonVPN-auto-NATPMP/main/natpmpc_script_qbittorrent.sh -o natpmpc_script.sh
```
 Give execute permission:
 ```sh
chmod +x natpmpc_script.sh
```
Restart the service:
 ```sh
sudo systemctl restart natpmpc_script
```
### Modify the script as needed
Access the script with an editor of your choice, for example:
```cmd
sudo nano /home/YOURUSER/natpmpc_script.sh
```
And change the integration with an application if possible, the value of the opened port is stored in the variable `$port`.
An example is the qbittorrent-nox integration, `natpmpc_script_qbittorrent.sh` content is:
```sh
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

    # Check if the current_port is different from the $port
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
```
 The script interacts with qbittorrent-nox service and changes the `--torrenting-port` parameter. Every time that the opened port changes, for any reason, the port is updated. This interrupts the execution of qBittorrent but it shouldn't happen frequently while the server is in operation.
