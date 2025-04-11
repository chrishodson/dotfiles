#!/bin/bash

VERSION=pihole/pihole:latest # Don't do this
VERSION=pihole/pihole:2023.05.2

DNSMASQDIR=/pihole/etc-dnsmasq.d
ETCPIHOLEDIR=/pihole/etc-pihole
mkdir -p $DNSMASQDIR $ETCPIHOLEDIR

INTERFACE=$(netstat -nr | awk '$1 == "0.0.0.0" {print $8}' | grep '^e')
MYIP=$(ip addr show dev $INTERFACE | awk '/inet / {print $2}' | sed -e 's/\/.*//')

# First run sometimes requires opening up the firewall
_x="""
for service in dhcp dns http https 
do
:
  sudo firewall-cmd --permanent --add-service=${service}
done
sudo firewall-cmd --reload
"""

docker pull $VERSION &&
docker stop pihole &&
docker rm pihole

docker run -d                        \
--name pihole                        \
--network=host                       \
--restart=unless-stopped             \
--dns=127.0.0.1                      \
--dns=1.1.1.1                        \
--cap-add=NET_BIND_SERVICE           \
--cap-add=NET_RAW                    \
--cap-add=NET_ADMIN                  \
-e TZ=America/New_York               \
-e DNS1=1.1.1.1                      \
-e DNS2=1.0.0.1                      \
-e DNSSEC=False                      \
-e INTERFACE=$INTERFACE              \
-e ServerIP=$MYIP                    \
-e DNSMASQ_LISTENING=local           \
-v $DNSMASQDIR/:/etc/dnsmasq.d/      \
-v $ETCPIHOLEDIR/:/etc/pihole/       \
$VERSION pihole tail

sleep 30 && docker exec -it pihole pihole status
