#!/bin/bash
dev= echo ${DEVNAME} | cut "-d/" -f3
date "+%Y%00m%00d.%H%M%S.%N ${DEVNAME}" >> /opt/arm/logs/udev.log
/opt/arm/identify.sh& 2>> /opt/arm/logs/udevtest.log

