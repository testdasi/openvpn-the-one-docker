#!/bin/bash

# install static files
mkdir -p /temp \
    && cd /temp \
    && curl -L "https://github.com/testdasi/static/archive/master.zip" -o /temp/static.zip \
    && unzip /temp/static.zip \
    && rm -f /temp/static.zip \
    && mv /temp/static-master /static

# overwrite static with repo-specific stuff
mkdir -p /temp \
    && cd /temp \
    && curl -O -L "https://raw.githubusercontent.com/testdasi/openvpn-hyrosa/master/config/flood.sh" \
    && curl -O -L "https://raw.githubusercontent.com/testdasi/openvpn-client-aio/master/config/privoxy" \
    && curl -O -L "https://raw.githubusercontent.com/testdasi/openvpn-client-aio/master/config/torrc" \
    && cp -f /temp/* /static/config/ \
    && rm -rf /temp

# fix static files for repo-specific stuff
sed -i "s|\/data\/deluge\/watch|\/data\/rtorrent\/watch|g" '/static/config/nzbhydra.yml'
sed -i "s|\/etc\/openvpn|\/root\/openvpn|g" '/static/scripts/openvpn.sh'
sed -i "s|\/etc\/openvpn|\/root\/openvpn|g" '/static/scripts/set_variables_ovpn_port_proto.sh'
sed -i "s|\/etc\/|\/root\/|g" '/static/scripts/fix_config_stubby.sh'
sed -i "s|\/etc\/|\/root\/|g" '/static/scripts/fix_config_dante.sh'
sed -i "s|\/etc\/|\/root\/|g" '/static/scripts/fix_config_tinyproxy.sh'
sed -i "s|\/etc\/|\/root\/|g" '/static/scripts/fix_config_sabnzbdplus.sh'
sed -i "s|\/etc\/|\/root\/|g" '/static/scripts/fix_config_rtorrent.sh'
sed -i "s|\/etc\/|\/root\/|g" '/static/scripts/fix_config_flood.sh'
sed -i "s|\/etc\/|\/root\/|g" '/static/scripts/fix_config_nzbhydra2.sh'
sed -i "s|\/etc\/|\/root\/|g" '/static/scripts/fix_config_sonarr.sh'
sed -i "s|\/etc\/|\/root\/|g" '/static/scripts/fix_config_radarr.sh'
sed -i "s|\/etc\/|\/root\/|g" '/static/scripts/fix_config_jackett.sh'

# flood.sh
mv -f /static/config/flood.sh /app/flood/ \
    && chmod +x /app/flood/flood.sh

# dup mono binary
cp /usr/bin/mono /usr/bin/mono-sonarr \
    && chmod +x /usr/bin/mono-sonarr
cp /usr/bin/mono /usr/bin/mono-radarr \
    && chmod +x /usr/bin/mono-radarr

# dup python3 binary
cp /usr/bin/python3 /usr/bin/python3-launcher \
    && chmod +x /usr/bin/python3-launcher

# dup python2 binary
cp /usr/bin/python2 /usr/bin/python2-launcher \
    && chmod +x /usr/bin/python2-launcher

# chmod scripts
chmod +x /*.sh

# clean up
apt-get -y autoremove \
    && apt-get -y autoclean \
    && apt-get -y clean \
    && rm -fr /tmp/* /var/tmp/* /var/lib/apt/lists/*
