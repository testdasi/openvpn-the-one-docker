#!/bin/bash

### Only run process if ovpn found ###
if [[ -f "/root/openvpn/openvpn.ovpn" ]]
then
    echo '[info] Config file detected...'
    ### Disable health check ###
    echo '[info] Disabling healthcheck while openvpn is connecting'
    touch /root/disable_healthcheck
    
    ### Set various variable values ###
    echo ''
    echo '[info] Setting variables'
    source /set_variables.sh
    echo '[info] All variables set'

    ### Fixing config files ###
    echo ''
    echo '[info] Fixing configs'
    source /fix_config.sh
    echo '[info] All configs fixed'

    ### Stubby DNS-over-TLS ###
    echo ''
    echo "[info] Run stubby in background on port $DNS_PORT"
    stubby -g -C /root/stubby/stubby.yml
    ipnaked=$(dig +short myip.opendns.com @208.67.222.222)
    echo "[warn] Your ISP public IP is $ipnaked"

    ### nftables ###
    echo ''
    echo '[info] Set up nftables rules'
    source /nftables.sh
    echo '[info] All rules created'

    ### OpenVPN ###
    echo ''
    echo "[info] Setting up OpenVPN tunnel"
    source /static/scripts/openvpn.sh
    echo '[info] Done'

    ### Dante SOCKS proxy to VPN ###
    echo ''
    echo "[info] Run danted in background on port $DANTE_PORT"
    danted -D -f /root/dante/danted.conf

    ### Tinyproxy HTTP proxy to VPN ###
    echo ''
    echo "[info] Run tinyproxy in background with no log on port $TINYPROXY_PORT"
    tinyproxy -c /root/tinyproxy/tinyproxy.conf

    ### Torsocks and Privoxy ###
    echo "[info] Run tor in background on port $TORSOCKS_PORT"
    start-stop-daemon --start --background --name tor --exec /usr/bin/tor -- -f /root/tor/torrc
    echo "[info] Run privoxy in background on port $PRIVOXY_PORT"
    privoxy /root/privoxy/config

    ### sabnzbdplus
    echo ''
    echo "[info] Run sabnzbdplus in background on HTTP port $SAB_PORT_A and HTTPS port $SAB_PORT_B"
    sabnzbdplus --daemon --config-file /root/sabnzbdplus/sabnzbdplus.ini --pidfile /root/sabnzbdplus/sabnzbd.pid

    ### transmission + flood
    echo ''
    echo "[info] Run transmission-daemon and flood in background at $FLOOD_IP:$FLOOD_PORT"
    transmission-daemon --config-dir=/root/transmission
    start-stop-daemon --start --background --name flood --chdir /usr/bin --exec flood -- --rundir=/root/flood --host=$FLOOD_IP --port=$FLOOD_PORT

    ### nzbhydra2
    echo ''
    echo "[info] Run nzbhydra2 in background on port $HYDRA_PORT"
    /app/nzbhydra2/nzbhydra2 --daemon --nobrowser --java /usr/lib/jvm/java-11-openjdk-amd64/bin/java --datafolder /root/nzbhydra2 --pidfile /root/nzbhydra2/nzbhydra2.pid
    
    ### jackett
    echo ''
    echo "[info] Run jackett in background on port $JACKETT_PORT"
    start-stop-daemon --start --background --chuid nobody --name jackett --chdir /app/jackett --exec /app/jackett/jackett -- --DataFolder=/root/jackett

    ### sonarr
    echo ''
    echo "[info] Run sonarr in background on port $SONARR_PORT"
    start-stop-daemon --start --background --name sonarr --chdir /app/sonarr --exec /usr/bin/mono-sonarr -- --debug Sonarr.exe -nobrowser -data=/root/sonarr

    ### radarr
    echo ''
    echo "[info] Run radarr in background on port $RADARR_PORT"
    start-stop-daemon --start --background --name radarr --chdir /app/radarr --exec /app/radarr/Radarr -- -nobrowser -data=/root/radarr

    ### prowlarr
    echo ''
    echo "[info] Run prowlarr in background on port $PROWLARR_PORT"
    start-stop-daemon --start --background --name prowlarr --chdir /app/prowlarr --exec /app/prowlarr/Prowlarr -- -nobrowser -data=/root/prowlarr

    ### GUI launcher
    echo ''
    echo "[info] Run WebUI launcher in background at $LAUNCHER_IP:$LAUNCHER_PORT"
    start-stop-daemon --start --background --name launcher --chdir /app/launcher --exec /app/launcher/launcher-python3.sh
    
    ### Enable health check ###
    echo '[info] Enabling healthcheck'
    rm -f /root/disable_healthcheck

    ### Periodically checking IP ###
    sleep_time=3600
    echo ''
    while true
    do
        iphiden=$(dig +short myip.opendns.com @208.67.222.222)
        echo "[info] Your VPN public IP is $iphiden"
        sleep $sleep_time
    done
else
    echo '[CRITICAL] Config file not found, quitting...'
fi
