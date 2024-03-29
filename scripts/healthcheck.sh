#!/bin/bash

### No healthcheck if openvpn is connecting ###
if [[ -f "/root/disable_healthcheck" ]]
then
    echo '[info] Healthcheck disabled when openvpn is connecting...'
else
    ### Autoheal ###
    crashed=0

    pidlist=$(pidof stubby)
    if [ -z "$pidlist" ]
    then
        crashed=$(( $crashed + 1 ))
        stubby -g -C /root/stubby/stubby.yml
    fi

    pidlist=$(pidof danted)
    if [ -z "$pidlist" ]
    then
        crashed=$(( $crashed + 1 ))
        danted -D -f /root/dante/danted.conf
    fi

    pidlist=$(pidof tinyproxy)
    if [ -z "$pidlist" ]
    then
        crashed=$(( $crashed + 1 ))
        tinyproxy -c /root/tinyproxy/tinyproxy.conf
    fi

    pidlist=$(pidof tor)
    if [ -z "$pidlist" ]
    then
        crashed=$(( $crashed + 1 ))
        start-stop-daemon --start --background --name tor --exec /usr/bin/tor -- -f /root/tor/torrc
    fi

    pidlist=$(pidof privoxy)
    if [ -z "$pidlist" ]
    then
        crashed=$(( $crashed + 1 ))
        privoxy /root/privoxy/config
    fi

    pidlist=$(pgrep sabnzbdplus)
    if [ -z "$pidlist" ]
    then
        crashed=$(( $crashed + 1 ))
        sabnzbdplus --daemon --config-file /root/sabnzbdplus/sabnzbdplus.ini --pidfile /root/sabnzbdplus/sabnzbd.pid
    fi

    pidlist=$(pgrep nzbhydra2)
    if [ -z "$pidlist" ]
    then
        crashed=$(( $crashed + 1 ))
        /app/nzbhydra2/nzbhydra2 --daemon --nobrowser --java /usr/lib/jvm/java-11-openjdk-amd64/bin/java --datafolder /root/nzbhydra2 --pidfile /root/nzbhydra2/nzbhydra2.pid
    fi

    pidlist=$(pidof transmission-daemon)
    if [ -z "$pidlist" ]
    then
        crashed=$(( $crashed + 1 ))
        transmission-daemon --config-dir=/root/transmission
    fi

    # Flood #
    pidlist=$(pidof node)
    if [ -z "$pidlist" ]
    then
        crashed=$(( $crashed + 1 ))
        start-stop-daemon --start --background --name flood --chdir /usr/bin --exec flood -- --rundir=/root/flood --host=${SERVER_IP} --port=${TORRENT_GUI_PORT}
    fi

    pidlist=$(pidof jackett)
    if [ -z "$pidlist" ]
    then
        crashed=$(( $crashed + 1 ))
        start-stop-daemon --start --background --chuid nobody --name jackett --chdir /app/jackett --exec /app/jackett/jackett -- --DataFolder=/root/jackett
    fi

    pidlist=$(pidof mono-sonarr)
    if [ -z "$pidlist" ]
    then
        crashed=$(( $crashed + 1 ))
        start-stop-daemon --start --background --name sonarr --chdir /app/sonarr --exec /usr/bin/mono-sonarr -- --debug Sonarr.exe -nobrowser -data=/root/sonarr
    fi

    pidlist=$(pidof Radarr)
    if [ -z "$pidlist" ]
    then
        crashed=$(( $crashed + 1 ))
        start-stop-daemon --start --background --name radarr --chdir /app/radarr --exec /app/radarr/Radarr -- -nobrowser -data=/root/radarr
    fi

    pidlist=$(pidof Prowlarr)
    if [ -z "$pidlist" ]
    then
        crashed=$(( $crashed + 1 ))
        start-stop-daemon --start --background --name prowlarr --chdir /app/prowlarr --exec /app/prowlarr/Prowlarr -- -nobrowser -data=/root/prowlarr
    fi

    pidlist=$(pidof python3-launcher)
    if [ -z "$pidlist" ]
    then
        crashed=$(( $crashed + 1 ))
        start-stop-daemon --start --background --name launcher --chdir /app/launcher --exec /app/launcher/launcher-python3.sh
    fi

    ### Critical check ###
    pidlist=$(pidof openvpn)
    if [ -z "$pidlist" ]
    then
        # kill the docker (by killing init script) if openvpn crashed
        pidentry=$(pgrep entrypoint.sh)
        kill $pidentry
        exit 1
    else
        # return exit code for healthcheck
        if (( $crashed > 0 ))
        then
            exit 1
        else
            exit 0
        fi
    fi
fi
