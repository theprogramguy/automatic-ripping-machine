#!/bin/bash
dev= echo ${DEVNAME} | cut "-d/" -f3
date "+%Y%00m%00d.%H%M%S.%N ${DEVNAME}" >> /opt/arm/logs/udev.log
echo bash /opt/arm/identify.sh /opt/arm/config | at now

