#!/bin/bash

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

pidlist=$(pidof rtorrent)
if [ -z "$pidlist" ]
then
    crashed=$(( $crashed + 1 ))
    screen -d -m -fa -S rtorrent /usr/bin/rtorrent
fi

pidlist=$(pidof npm)
if [ -z "$pidlist" ]
then
    crashed=$(( $crashed + 1 ))
    start-stop-daemon --start --background --name flood --chdir /app/flood --exec /app/flood/flood.sh
fi

pidlist=$(pgrep nzbhydra2)
if [ -z "$pidlist" ]
then
    crashed=$(( $crashed + 1 ))
    /app/nzbhydra2/nzbhydra2 --daemon --nobrowser --java /usr/lib/jvm/java-11-openjdk-amd64/bin/java --datafolder /root/nzbhydra2 --pidfile /root/nzbhydra2/nzbhydra2.pid
fi

pidlist=$(pidof mono-sonarr)
if [ -z "$pidlist" ]
then
    crashed=$(( $crashed + 1 ))
    start-stop-daemon --start --background --name sonarr --chdir /app/sonarr --exec /usr/bin/mono-sonarr -- --debug NzbDrone.exe -nobrowser -data=/root/sonarr
fi

pidlist=$(pidof mono-radarr)
if [ -z "$pidlist" ]
then
    crashed=$(( $crashed + 1 ))
    start-stop-daemon --start --background --name radarr --chdir /app/radarr --exec /usr/bin/mono-radarr -- --debug Radarr.exe -nobrowser -data=/root/radarr
fi

pidlist=$(pidof jackett)
if [ -z "$pidlist" ]
then
    crashed=$(( $crashed + 1 ))
    start-stop-daemon --start --background --chuid nobody --name jackett --chdir /app/jackett --exec /app/jackett/jackett -- --DataFolder=/root/jackett
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
