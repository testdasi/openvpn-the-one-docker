ARG FRM='testdasi/openvpn-the-one-docker-base'
ARG TAG='latest'

FROM ${FRM}:${TAG}
ARG FRM
ARG TAG

ENV LANG en_GB.UTF-8
ENV LAUNCHER_GUI_PORT 8000
ENV DNS_SERVER_PORT 53
ENV SOCKS_PROXY_PORT 9118
ENV HTTP_PROXY_PORT 8118
ENV TOR_SOCKS_PORT 9119
ENV TOR_HTTP_PORT 8119
ENV USENET_HTTP_PORT 8080
ENV USENET_HTTPS_PORT 8090
ENV TORRENT_GUI_PORT 8112
ENV SEARCHER_GUI_PORT 5076
ENV PVR_TV_PORT 8989
ENV PVR_MOVIE_PORT 7878
ENV TORZNAB_PORT 9117
ENV DNS_SERVERS 127.2.2.2
ENV HOST_NETWORK 192.168.1.0/24
ENV SERVER_IP 192.168.1.2

EXPOSE ${LAUNCHER_GUI_PORT}/tcp \
    ${DNS_SERVER_PORT}/tcp \
    ${DNS_SERVER_PORT}/udp \
    ${SOCKS_PROXY_PORT}/tcp \
    ${HTTP_PROXY_PORT}/tcp \
    ${TOR_SOCKS_PORT}/tcp \
    ${TOR_HTTP_PORT}/tcp \
    ${USENET_HTTP_PORT}/tcp \
    ${USENET_HTTPS_PORT}/tcp \
    ${TORRENT_GUI_PORT}/tcp \
    ${SEARCHER_GUI_PORT}/tcp \
    ${PVR_TV_PORT}/tcp \
    ${PVR_MOVIE_PORT}/tcp \
    ${TORZNAB_PORT}/tcp

ADD config /temp
ADD scripts /

RUN /bin/bash /install.sh \
    && rm -f /install.sh

VOLUME ["/root"]

ENTRYPOINT ["/entrypoint.sh"]

# ENTRYPOINT ["tini", "--", "/entrypoint.sh"]

HEALTHCHECK CMD /healthcheck.sh

RUN echo "$(date "+%d.%m.%Y %T") Built from ${FRM} with tag ${TAG}" >> /build_date.info
