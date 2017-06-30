FROM alpine:3.5

RUN set -x \
    && apk add --no-cache iptables inotify-tools bash

ADD shield.sh /
ADD entrypoint.sh /
ADD run.sh /
ADD default.acl /etc/iptables-shield/default.acl

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/run.sh", "/etc/iptables-shield/default.acl"]
