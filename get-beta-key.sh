#!/bin/bash

sudo wget "http://www.makemkv.com/forum2/viewtopic.php?f=5&t=1053" -O /opt/arm/key.html 2>> /dev/null
MAKEMKV_KEY1=$(cat /opt/arm/key.html | grep "current beta" | awk -F"codecontent\">" '{print $2}' | awk -F"<" '{print $1}')
MAKEMKV_KEY2=`curl "http://www.makemkv.com/forum2/viewtopic.php?f=5&t=1053" -s | awk 'FNR == 243 {print $57}' | cut -c 21-88`
#echo $MAKEMKV_KEY1
#echo $MAKEMKV_KEY2

if [ $MAKEMKV_KEY1 == $MAKEMKV_KEY2 ] ; then
#	echo "keys match"
	echo $MAKEMKV_KEY1
else
	echo "KEY_MISMATCH"
	exit

fi

