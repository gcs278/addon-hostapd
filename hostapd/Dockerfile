ARG BUILD_FROM
FROM $BUILD_FROM

MAINTAINER David Ramos <info@davidramosweb.com>

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV LANG C.UTF-8

# Install requirements for add-on
RUN apk update && apk add --no-cache bash jq iw hostapd networkmanager net-tools sudo && rm -rf /var/cache/apk/*

# Setup base
RUN apk add --no-cache dhcp

COPY run-dhcp.sh /
COPY hostapd.conf /
COPY interfaces /etc/network/interfaces
COPY run.sh /
RUN chmod a+x /run.sh
RUN chmod a+x /run-dhcp.sh

ENV S6_KILL_GRACETIME 20000
COPY kill.sh /etc/cont-finish.d/
RUN chmod a+x /etc/cont-finish.d/kill.sh

CMD [ "/run.sh" ]
