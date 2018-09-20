#!/bin/sh
cd /
echo 9.37.96.90 commander.rtp.dst.ibm.com >> /etc/hosts
echo 9.37.96.91 commanderuat.rtp.dst.ibm.com >> /etc/hosts
echo 9.57.199.52 b01acirdbha007.ahe.pok.ibm.com >> /etc/hosts

java -Djava.security.egd=file:/dev/./urandom -jar /app.war
