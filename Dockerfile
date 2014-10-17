FROM debian:jessie

RUN apt-get -q update
RUN apt-get -qy install squid3
RUN apt-get -qy install iptables

RUN echo "http_port 3129 intercept" >> /etc/squid3/squid.conf
RUN sed -i "s/^#acl localnet/acl localnet/" /etc/squid3/squid.conf
RUN sed -i "s/^#http_access allow localnet/http_access allow localnet/" /etc/squid3/squid.conf

RUN mkdir -p /var/cache/squid3

ADD launch.sh launch.sh
RUN chmod +x launch.sh


ENTRYPOINT /launch.sh