# openvpn-the-one-docker
I found having to maintain a dozen of various dockers behind OpenVPN client very tedious. So I coded this "app" to have everything in 1 docker.

## High-level instructions
* Create an appdata folder in host and create a openvpn subfolder
* Copy your OpenVPN configuration to the above openvpn subfolder (must include openvpn.ovpn + credentials + certs).
* Don't forget to map /data in the docker to the host (you can map the parent or individual subfolders depending on needs).
* Start docker (other apps should configure themselves on first run).
  * Default login for flood is admin/flood

## Key features
1. OpenVPN client to connect to your favourite VPN provider. Full freedom with what you want to do with the ovpn file.
2. 2 sets of kill switches. NFT kill switch to block connection when VPN is down. Piping kill switch HTTP proxy -> SOCKS5 proxy -> VPN tun0 / TOR tunnel.
3. Stubby for DNS server to connec to DoT (dns-over-tls) services (ip:53 or 127.2.2.2:5253). Use Google and Cloudflare for best performance.
4. Dante for SOCKS5 proxy to your VPN (ip:9118)
5. Tinyproxy for HTTP proxy to your VPN (ip:8118)
6. Torsocks for SOCKS5 proxy to TOR (ip:9119)
7. Privoxy for HTTP proxy to TOR (ip:8119)
8. Radarr (ip:7878)
9. Sonarr (ip:8989)
10. Transmission-daemon for torrenting
11. Flood for simple web interface to Transmission (ip:3000)
12. Jackett for torrent index (ip:9117)
13. SABnzbdPlus for usenet (ip:8080 or ip:8090 for https)
14. NZBHydra2 for usenet index (ip:5076)
15. A quick WebUI launcher (ip:8000) to quickly access the various apps above (or as always, just go directly to each app).

## Bits and bobs
* OpenVPN config files MUST be named openvpn.ovpn. The certs and credentials can be included in the config file or split into separate files. The flexibility is yours.
* Explaining the parameters (the values you see in Usage section are default values)
  * SERVER_IP: IP of the docker host (if bridge network) or the static IP you give to the docker (if macvlan bridge e.g. Unraid br0 / br1)
  * LAUNCHER_GUI_PORT: the WebUI quick launcher is accessible at SERVER_IP:LAUNCHER_GUI_PORT.
  * DNS_SERVERS: set to 127.2.2.2 will point to stubby (which in turn points to Google / Cloudflare DoT services). Your DNS queries out of the VPN exit will also be encrypted before arriving at Google / Cloudflare for even more privacy. Change it to other comma-separated IPs (e.g. 1.1.1.1,8.8.8.8) will use normal unencrypted DNS, or perhaps a pihole in the local network.
  * HOST_NETWORK: to enable free flow between host network and the docker (e.g. when using docker bridge network). Otherwise, your proxies will only work from within the docker network. Must be in CIDR format e.g. 192.168.1.0/24
  * DNS_SERVER_PORT: the docker will serve as a DNS server for the local network so everything, including DNS, comes out of the VPN exit.
    * Work best if set to 53 as most things can't handle DNS on other ports. In which case, you have to give the docker its own static IP (i.e. use docker macvlan network) if the host also uses port 53 e.g. if you run a Pihole on the host IP. For Unraid, use Custom : br0 / br1 network (to enable this, go to Settings -> Docker).
    * You will need to set each device DNS to the docker IP.
    * Alternatively, you can set your router DHCP to set DNS to the docker IP.
  * SOCKS/HTTP_PROXY_PORT: use these proxies if you want to exit through your VPN. Useful if you need to route other apps (e.g. Sonarr/Radarr) through the same VPN exit.
  * USENET_HTTP_PORT/USENET_HTTPS_PORT/TORRENT_GUI_PORT/SEARCHER_GUI_PORT/PVR_TV_PORT/PVR_TV_PORT/PVR_MOVIE_PORT/TORZNAB_PORT: use these to access the GUI of SABnzbdPlus (http or https), Flood (with underlying Transmission-daemon), NZBHydra2, Sonarr, Radarr, Jackett.
  * The docker port mappings map host ports to docker ports. The docker ports are determined by the aforementioned PORT variables. So if you change the docker variables, you should also change the port mappings accordingly.
    * There is a quirk with the WebUI quick launcher. On bridge network (i.e. no static IP), if you want to change the port mapping of NZBHydra2 / Flood / Sabnzbd, please change the ENV variable + the container port + the mapped host port to the same value.
* Pre-configured NZBHydra2 will *attempt* drop torrent / nzb files into the respective "black holes", which Transmission / SABnzbdPlus can pick up automagically.
* I tested the trio of rtorrent, qbittorrent and transmission backends for Flood and eventually (Jan-2022) settled on Transmission. It ticks all 3-s for me (simplicity, speed, stability) with no bells and whistles.

## Usage
    docker run -d \
        --name=<container name> \
        --cap-add=NET_ADMIN \
        -v <host path for config>:/config \
        -v <host path for data>:/data \
        -e DNS_SERVERS=127.2.2.2 \
        -e HOST_NETWORK=192.168.1.0/24 \
        -e SERVER_IP=192.168.1.2 \
        -p 8000:8000/tcp \
        -p 53:53/tcp \
        -p 53:53/udp \
        -p 9118:9118/tcp \
        -p 8118:8118/tcp \
        -p 8080:8080/tcp \
        -p 8090:8090/tcp \
        -p 3000:3000/tcp \
        -p 5076:5076/tcp \
        -e LAUNCHER_GUI_PORT=8000 \
        -e DNS_SERVER_PORT=53 \
        -e SOCKS_PROXY_PORT=9118 \
        -e HTTP_PROXY_PORT=8118 \
        -e USENET_HTTP_PORT 8080 \
        -e USENET_HTTPS_PORT 8090 \
        -e TORRENT_GUI_PORT 3000 \
        -e SEARCHER_GUI_PORT 5076 \
        testdasi/openvpn-hyrosa:<tag>

## Unraid example
    docker run -d \
        --name='OpenVPN-HyDeSa' \
        --net='bridge' \
        --cap-add=NET_ADMIN \
        -v '/mnt/user/appdata/openvpn-hyrosa':'/config':'rw' \
        -v '/mnt/user/downloads/':'/data':'rw' \
        -e 'DNS_SERVERS'='127.2.2.2' \
        -e 'HOST_NETWORK'='192.168.1.0/24' \
        -e 'SERVER_IP'='192.168.1.2' \
        -p '8000:8000/tcp' \
        -p '8153:53/tcp' \
        -p '8153:53/udp' \
        -p '9118:9118/tcp' \
        -p '8118:8118/tcp' \
        -p '8080:8080/tcp' \
        -p '8090:8090/tcp' \
        -p '3000:3000/tcp' \
        -p '5076:5076/tcp' \
        -e 'LAUNCHER_GUI_PORT'='8000' \
        -e 'DNS_SERVER_PORT'='53' \
        -e 'SOCKS_PROXY_PORT'='9118' \
        -e 'HTTP_PROXY_PORT'='8118' \
        -e 'USENET_HTTP_PORT'='8080' \
        -e 'USENET_HTTPS_PORT'='8090' \
        -e 'TORRENT_GUI_PORT'='3000' \
        -e 'SEARCHER_GUI_PORT'='5076' \
        -e 'LANG'='en_GB.UTF-8' \
        -e TZ="Europe/London" \
        -e HOST_OS="Unraid" \
        'testdasi/openvpn-hyrosa:stable-amd64' 

## Notes
* I code for fun and my personal uses; hence, these niche functionalties that nobody asks for. ;)
* Tested only with PIA since I can't afford anything else. Theoretically, it should work with any VPN services that support OpenVPN.
* If you like my work, [a donation to my burger fund](https://paypal.me/mersenne) is very much appreciated.

[![Donate](https://raw.githubusercontent.com/testdasi/testdasi-unraid-repo/master/donate-button-small.png)](https://paypal.me/mersenne). 
