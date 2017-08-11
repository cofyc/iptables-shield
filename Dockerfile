FROM alpine:3.6

RUN set -x \
    && apk add --no-cache iptables bash

ADD shield.sh /
ADD entrypoint.sh /
ADD watch.sh /
ADD default.acl /etc/iptables-shield/default.acl

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/watch.sh", "/etc/iptables-shield/default.acl"]
