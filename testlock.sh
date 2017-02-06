#!/bin/bash
(
         flock -n 9 || exit
	 
(
	 echo "START"
	 :
	 sleep 10
	 echo "--2"
	 sleep 10
	 echo "--3"
	 sleep 10
	 echo "END"
) >> /opt/arm/$1.lock.test

) 9>/opt/arm/$1


