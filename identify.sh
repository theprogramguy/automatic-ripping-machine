#!/bin/bash
# shellcheck source=config
# shellcheck disable=SC1091

########## DECLARE VARS ###########
theUser=$(whoami)
STARTTIME=$(date "+%Y%00m%00d.%H%M%S.%N")
TRAYSTATUS=9
GET_TITLE_OUTPUT=""
GET_TITLE_RESULT=""
VIDEO_TITLE=""
HAS_NICE_TITLE=""
VIDEO_TYPE=""
VTYPE=""
MEDIA_TYPE="ERROR"
FS_TYPE="CD"


### FUNCTIONS ###
ID_VIDEO(){


	GET_TITLE_OUTPUT=$(/opt/arm/getmovietitle.py -p /mnt"${DEVNAME}" 2>&1)
	GET_TITLE_RESULT=$?

	if [ $GET_TITLE_RESULT = 0 ]; then
		echo "Obtained Title $GET_TITLE_OUTPUT"
		HAS_NICE_TITLE=true
		VIDEO_TITLE=${GET_TITLE_OUTPUT}
	else
		echo "failed to get title $GET_TITLE_OUTPUT"
		HAS_NICE_TITLE=false
		VIDEO_TITLE=${ID_FS_LABEL} 
	fi


	if [ $HAS_NICE_TITLE == true ]; then
		VTYPE=$(/opt/arm/getvideotype.py -t "${VIDEO_TITLE}" 2>&1)

		#handle year mismath if found
		if [[ $VTYPE =~ .*#.* ]]; then
			VIDEO_TYPE=$(echo "$VTYPE" | cut -f1 -d#)
			NEW_YEAR=$(echo "$VTYPE" | cut -f2 -d#)
			echo "VIDEO_TYPE is $VIDEO_TYPE and NEW_YEAR is $NEW_YEAR"
			VIDEO_TITLE="$(echo "$VIDEO_TITLE" | cut -f1 -d\()($NEW_YEAR)" 
			echo "Year mismatch found.  New video title is $VIDEO_TITLE"
		else
			VIDEO_TYPE="$VTYPE"
		fi
	else
		VIDEO_TYPE="unknown"
	fi
	if [ echo $VIDEO_TITLE | grep -i "SEASON" ]; then
		VIDEO_TYPE="tv"
	fi
}


LOCKFILE="${DEVNAME///}.lock"
(
	####### LOCK WITH $LOCKFILE, IF LOCKED, EXIT ####### 
        flock -n 9 || exit
	echo "Starting identify.sh ${DEVNAME}" >> /opt/arm/logs/identify.log
	/opt/arm/drivestatus.bin ${DEVNAME} || exit
	if [ -z "$1" ]; then
		export ARM_CONFIG="/opt/arm/config"
	else
		export ARM_CONFIG=$1
	fi
	sleep 6

	echo "$ARM_CONFIG"

	
	source "$ARM_CONFIG"

	# Create log dir if needed
	mkdir -p "$LOGPATH"

	#shellcheck disable=SC2094


	exec >> "$LOG"
	exec 2>&1
	echo "#######################################################"
	echo "################# NEW LOG ENTRY #######################"
	echo "#######################################################"
	##CHECK CD TRAY##
	if [ ! -f "/opt/arm/drivestatus.bin" ]; then
		echo "/usr/bin/gcc /opt/arm/drivestatus.c -o /opt/arm/drivestatus.bin" | at now
		sleep 2
		echo "drivestatus.bin doesnt exist"
		if [ ! -f "/opt/arm/drivestatus.bin" ]; then
			echo "failed to compile, please run 'gcc /opt/arm/drivestatus.c -o /opt/arm/drivestatus.bin'"
			exit
		fi
	fi
	echo "CHECKING ${DEVNAME} STATUS"
	/opt/arm/drivestatus.bin ${DEVNAME}
	TRAYSTATUS=$?
	if [ "$TRAYSTATUS" == "0" ]; then
		echo "drivestatus reported $TRAYSTATUS, Continue"
	else
		echo "drivestatus reported $TRAYSTATUS, Exit"
		exit
	fi

	echo "Starting Identify Script @ $STARTTIME as $theUser  @ PID $BASHPID ..."
	echo "################ ENVIRONMENT ##########################"
	printenv
	echo "################### UDEV ##############################"
	# Output UDEV info
	udevadm info -q env -n "$DEVNAME"
	echo "################## CONFIG #############################"
	# echo all config parameters to logfile
	# excludes sensative parameters
	# shellcheck disable=SC2129
	# shellcheck disable=SC2002
	cat "$ARM_CONFIG"|sed '/^[#;].*$/d;/^$/d;/if/d;/^ /d;/^else/d;/^fi/d;/KEY=/d;/PASSWORD/d'
	echo "################### LOG CLEANUP #######################"



	#Clean up old log files
	FILESFOUND=( $(find "$LOGPATH" -mtime +"$LOGLIFE" -type f))
	echo "Deleting ${#FILESFOUND[@]} old log files: ${FILESFOUND[*]}"
	find "$LOGPATH" -mtime +"$LOGLIFE" -type f -delete

	echo "#######################################################"
	echo "#######################################################"
	echo "#######################################################"




	# Set Home to home folder of user that is setup to run MakeMKV
	export HOME="/root/"

	

	if   [ "$ID_CDROM_MEDIA_BD" == "1" ]; then
		MEDIA_TYPE="BLURAY"
	elif [ "$ID_CDROM_MEDIA_DVD" == "1" ]; then
		MEDIA_TYPE="DVD"
	elif [ "$ID_CDROM_MEDIA_CD" == "1" ]; then
		MEDIA_TYPE="CD"
	else
		MEDIA_TYPE="ERROR"
	fi

	if   [ "$ID_FS_TYPE" == "udf" ]; then
		FS_TYPE="UDF-DATA"
	elif [ "$ID_FS_TYPE" == "iso9660" ]; then
		MEDIA_TYPE="ISO-DATA"
	elif [ $ID_CDROM_MEDIA_TRACK_COUNT_AUDIO > 0 ]; then
		FS_TYPE="AUDIO"
	else
		FS_TYPE="ERROR"
	fi
	echo  "$MEDIA_TYPE is $FS_TYPE" 

	## some OLD commercial dvds and home burnt DVDs use iso9660 ?!?
exit
	
	##lets handle the easiest ones first
	case $FS_TYPE in
		AUDIO)
			abcde -c /opt/arm/.abcde.conf -N -x -d "$DEVNAME" 2>>/dev/null
			echo "ABCDE finished"
			exit
		;;



	esac

	


	if [ "$ID_FS_TYPE" == "udf" ]; then
		echo "identified udf"
		echo "found ${ID_FS_LABEL} on ${DEVNAME}"

		if [ "$ARM_CHECK_UDF" == true ]; then
			# check to see if this is really a video
			mkdir -p /mnt/"$DEVNAME"
			mount "$DEVNAME" /mnt/"$DEVNAME"
			if [[ -d /mnt/${DEVNAME}/VIDEO_TS || -d /mnt/${DEVNAME}/BDMV ]]; then
				echo "identified udf as video"

				if [ "$GET_VIDEO_TITLE" == true ]; then

					ID_VIDEO

				else
					HAS_NICE_TITLE=false
					VIDEO_TITLE=${ID_FS_LABEL} 
				fi

				echo "HAS_NICE_TITLE is ${HAS_NICE_TITLE}"
				echo "video title is now ${VIDEO_TITLE}"
				echo "video type is ${VIDEO_TYPE}"

				umount "/mnt/$DEVNAME"
				if [ "$KODI_NOTIFY" == true ]; then /opt/arm/kodi-notify.py --hosts=$KODI_CLIENTS --msg="Rip Started,$VIDEO_TITLE started." 2>&1; fi
				/opt/arm/queue_video_rip.sh "$LOG" "$DEVNAME" "$VIDEO_TITLE" "$HAS_NICE_TITLE" "$VIDEO_TYPE"
			else
				umount "/mnt/$DEVNAME"
				echo "identified udf as data" 
				/opt/arm/data_rip.sh
				eject "$DEVNAME"

			fi
		else
			echo "ARM_CHECK_UDF is false, assuming udf is video" 
			mkdir -p /mnt/"$DEVNAME"
			mount "$DEVNAME" /mnt/"$DEVNAME"
			ID_VIDEO
			echo "HAS_NICE_TITLE is ${HAS_NICE_TITLE}"
			echo "video title is now ${VIDEO_TITLE}"
			echo "video type is ${VIDEO_TYPE}"
			umount "/mnt/$DEVNAME"

			if [ "$KODI_NOTIFY" == true ]; then /opt/arm/kodi-notify.py --hosts=$KODI_CLIENTS --msg="Rip Started,$VIDEO_TITLE started." 2>&1; fi
			/opt/arm/video_rip.sh "$LOG"
		fi	


	elif (("$ID_CDROM_MEDIA_TRACK_COUNT_AUDIO" > 0 )); then
		echo "identified audio" 
		

	elif [ "$ID_FS_TYPE" == "iso9660" ]; then
		echo "identified data" 
		/opt/arm/data_rip.sh "$LOG"
		eject "$DEVNAME"
	else
		echo "unable to identify"
		echo "$ID_CDROM_MEDIA_TRACK_COUNT_AUDIO" 
		echo "$ID_FS_TYPE" 
		#eject "$DEVNAME"
	fi


) 9>/opt/arm/$LOCKFILE 																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																					
