#!/bin/bash
# shellcheck source=config
# shellcheck disable=SC1091
# Transcodes Video files using HandBrake and removes source files when done
source "$ARM_CONFIG"
exec >> "$LOG"
exec 2>&1

SRC=$1
LABEL=$2
HAS_NICE_TITLE=$3
VIDEO_TYPE=$4
TIMESTAMP=$5


	TRANSSTART=$(date +%s);
	echo "Start video transcoding script" 

	if [ "$HAS_NICE_TITLE" = true ]; then
		echo "transcoding with a nice title"
		DEST="${ARMPATH}/${LABEL}"
		echo "dest ${DEST} variable created"
		if [ -d "$DEST" ]; then
			echo "directory already exists... adding timestamp" 
			DEST="${ARMPATH}/${LABEL}_${TIMESTAMP}"
		fi
	else
		echo "transcoding without a nice title" 
		DEST="${ARMPATH}/${LABEL}_${TIMESTAMP}"
	fi	

	# DEST="${ARMPATH}/${LABEL}_${TIMESTAMP}"
	mkdir -p "$DEST"
	if [ "$SKIP_TRANSCODE" = true ] && [ "$RIPMETHOD" = "mkv" ]; then
		# this only works for files ripped by MakeMKV into .mkv files
		echo "Skipping transcode.  Moving files from $SRC to $DEST" 
		mv "$SRC"/* "$DEST"/  
	elif [ "$RIPMETHOD" = "backup" ] && [ "$MAINFEATURE" = true ] && [ "$ID_CDROM_MEDIA_BD" = "1" ]; then
		echo "Transcoding BluRay main feature only." 
		# shellcheck disable=SC2086
		nice $HANDBRAKE_CLI -i "$SRC" -o "$DEST/$LABEL.$DEST_EXT" --main-feature --preset="$HB_PRESET" $HB_ARGS
		rmdir "$SRC"	
	elif [ "$RIPMETHOD" = "backup" ] && [ "$MAINFEATURE" = false ] && [ "$ID_CDROM_MEDIA_BD" = "1" ]; then		
		echo "Transcoding BluRay all titles above minlength."
		# Itterate through titles of MakeMKV backup
		# First check if this is the main title
		MAINTITLENO="$(echo ""|HandBrakeCLI --input "$SRC" --title 0 --scan |& grep -B 1 "Main Feature" | sed 's/[^0-9]*//g')"

		# Get number of titles
		TITLES="$(echo ""|HandBrakeCLI --input "$SRC" --scan |& grep -Po '(?<=scan: BD has )([0-9]+)')"
		echo "$TITLES titles on BluRay Disc"

		for TITLE in $(seq 1 "$TITLES")
		do
			echo "Processing title $TITLE"

			TIME="$(echo ""|HandBrakeCLI --input "$SRC" --title "$TITLE" --scan |& grep 'duration is' | sed -r 's/.*\((.*)ms\)/\1/')"
			
			SEC=$(( TIME / 1000 ))
			echo "Title length is $SEC seconds." 
			if [ $SEC -gt "$MINLENGTH" ]; then
				echo "HandBraking title $TITLE"
				# shellcheck disable=SC2086
				nice $HANDBRAKE_CLI -i "$SRC" -o "$DEST/$LABEL-$TITLE.$DEST_EXT" --min-duration="$MINLENGTH" -t "$TITLE" --preset="$HB_PRESET" $HB_ARGS

				# Check for main title and rename
				if [ "$MAINTITLENO" = "$TITLE" ] && [ "$HAS_NICE_TITLE" = true ]; then
					echo "Sending the following command: mv -n \"$DEST/$LABEL-$TITLE.$DEST_EXT\" \"${DEST}/${LABEL}.${DEST_EXT}\""
					mv -n "$DEST/$LABEL-$TITLE.$DEST_EXT" "${DEST}/${LABEL}.${DEST_EXT}" 
				fi
			else    
				echo "Title $TITLE lenth less than $MINLENGTH.  Skipping." 
			fi
		done	
		rm -rf "$SRC"
	elif [ "$MAINFEATURE" = true ] && [ "$ID_CDROM_MEDIA_DVD" = "1" ]; then
		echo "Transcoding DVD main feature only." 
		# echo "$HANDBRAKE_CLI -i $DEVNAME -o \"${DEST}/${LABEL}.${DEST_EXT}\" --main-feature --preset="${HB_PRESET}" --subtitle scan -F 2" >> $LOG
		# shellcheck disable=SC2086
        	nice $HANDBRAKE_CLI -i "$DEVNAME" -o "${DEST}/${LABEL}.${DEST_EXT}" --main-feature --preset="${HB_PRESET}" $HB_ARGS 
		#2>> "$LOG"
		eject "$DEVNAME"
	else
		echo "Transcoding all files." 
		# shellcheck disable=SC2045
	        for FILE in $(ls "$SRC")
                	do
                	filename=$(basename "$FILE")

                	#extension=${filename##*.}
                	filename=${filename%.*}

			echo "Transcoding file $FILE" 
				# shellcheck disable=SC2086
                	nice $HANDBRAKE_CLI -i "$SRC/$FILE" -o "$DEST/$filename.$DEST_EXT" --preset="$HB_PRESET" $HB_ARGS 
			rm "$SRC/$FILE"
       		done
		rmdir "$SRC"
	fi

	embyrefresh ()
	{
			ApiKey="$(curl -s -H "Authorization: MediaBrowser Client=\"$EMBY_CLIENT\", Device=\"$EMBY_DEVICE\", DeviceId=\"$EMBY_DEVICEID\", Version=1.0.0.0, UserId=\"$EMBY_USERID\"" -d "username=$EMBY_USERNAME" -d "password=$EMBY_PASSWORD" "http://$EMBY_SERVER:$EMBY_PORT/users/authenticatebyname?format=json" | python -m json.tool | grep 'AccessToken' | sed 's/\"//g; s/AccessToken://g; s/\,//g; s/ //g')"

			RESPONSE=$(curl -d 'Library' "http://$EMBY_SERVER:$EMBY_PORT/Library/Refresh?api_key=$ApiKey")

			if [ ${#RESPONSE} = 0 ]; then
				# scan was successful
				echo "Emby refresh command sent successfully" 
			else
				# scan failed
				echo "Emby refresh command failed for some reason.  Probably authentication issues" 
			fi
	}

	if [ "$VIDEO_TYPE" = "movie" ] && [ "$MAINFEATURE" = true ] && [ "$HAS_NICE_TITLE" = true ] && [ "$EMBY_SUBFOLDERS" = false ]; then
		# move the file to the final media directory
		# shellcheck disable=SC2129,SC2016
		echo '$VIDEO_TYPE is movie, $MAINFEATURE is true, $HAS_NICE_TITLE is true, $EMBY_SUBFOLDERS is false' 
		echo "Moving a single file." 
        echo "Checing for existing file..." 
		if [ ! -f "$MEDIA_DIR/$LABEL.$DEST_EXT" ]; then
			echo "No file found.  Moving \"$DEST/$LABEL.$DEST_EXT to $MEDIA_DIR/$LABEL.$DEST_EXT\"" 
			mv -n "$DEST/$LABEL.$DEST_EXT" "$MEDIA_DIR/$LABEL.$DEST_EXT"
			
			if [ "$SET_MEDIA_PERMISSIONS" = true ]; then
			
			chmod -R "$CHMOD_VALUE" "$MEDIA_DIR"
							
			fi

			if [ "$EMBY_REFRESH" = true ]; then
				# signal emby to scan library
				embyrefresh
			else
				echo "Emby Refresh False.  Skipping library scan" 
			fi
		else	
			echo "Warning: $MEDIA_DIR/$LABEL.$DEST_EXT File exists! File moving aborted" 
        fi
    elif [ "$VIDEO_TYPE" = "movie" ] && [ "$MAINFEATURE" = true ] && [ "$HAS_NICE_TITLE" = true ] && [ "$EMBY_SUBFOLDERS" = true ]; then
		# shellcheck disable=SC2129,SC2016
		echo '$VIDEO_TYPE is movie, $MAINFEATURE is true, $HAS_NICE_TITLE is true, $EMBY_SUBFOLDERS is true' 
        echo "Moving a single file to emby subfolders" 
		mkdir -p "$MEDIA_DIR/$LABEL" 
		if [ ! -f "$MEDIA_DIR/$LABEL/$LABEL.$DEST_EXT" ]; then
			echo "No file found.  Moving \"$DEST/$LABEL.$DEST_EXT to $MEDIA_DIR/$LABEL/$LABEL.$DEST_EXT\"" 
			mv -n "$DEST/$LABEL.$DEST_EXT" "$MEDIA_DIR/$LABEL/$LABEL.$DEST_EXT"
			
			if [ "$SET_MEDIA_PERMISSIONS" = true ]; then
			
			chmod -R "$CHMOD_VALUE" "$MEDIA_DIR/$LABEL"
						
			fi

			if [ "$EMBY_REFRESH" = true ]; then
				# signal emby to scan library
				embyrefresh
			else
				echo "Emby Refresh False.  Skipping library scan" 
			fi
		else	
			echo "Warning: $MEDIA_DIR/$LABEL/$LABEL.$DEST_EXT File exists! File moving aborted" 
        fi
	elif [ "$VIDEO_TYPE" = "movie" ] && [ "$MAINFEATURE" = false ] && [ "$HAS_NICE_TITLE" = true ] && [ "$EMBY_SUBFOLDERS" = false ]; then
		# shellcheck disable=SC2129,SC2016
		echo '$VIDEO_TYPE is movie, $MAINFEATURE is false, $HAS_NICE_TITLE is true, $EMBY_SUBFOLDERS is false' 
		# hopefully this is never happen because it will cause a lot of duplicate files
		echo "***WARNING!*** This will likely leave files in the transcoding directory as there is very likely existing files in the media directory"
        echo "Moving multiple files to emby movie folder" 
		mv -n "$DEST/$LABEL.$DEST_EXT" "$MEDIA_DIR/$LABEL.$DEST_EXT"
		
		if [ "$SET_MEDIA_PERMISSIONS" = true ]; then
			
		chmod -R "$CHMOD_VALUE" "$MEDIA_DIR"
					
		fi
		
		if [ "$EMBY_REFRESH" = true ]; then
			# signal emby to scan library
			embyrefresh
		else
			echo "Emby Refresh False.  Skipping library scan" 
		fi
	elif [ "$VIDEO_TYPE" = "movie" ] && [ "$MAINFEATURE" = false ] && [ "$HAS_NICE_TITLE" = true ] && [ "$EMBY_SUBFOLDERS" = true ]; then
		# shellcheck disable=SC2129,SC2016
		echo '$VIDEO_TYPE is movie, $MAINFEATURE is false, $HAS_NICE_TITLE is true, $EMBY_SUBFOLDERS is true' 
        echo "Moving multiple files to emby movie subfolders" 
		echo "First move main title" 
        mkdir -p -v "$MEDIA_DIR/$LABEL" 
		if [ ! -f "$MEDIA_DIR/$LABEL/$LABEL.$DEST_EXT" ]; then
			echo "No file found.  Moving \"$DEST/$LABEL.$DEST_EXT to $MEDIA_DIR/$LABEL/$LABEL.$DEST_EXT\"" 
			mv -n "$DEST/$LABEL.$DEST_EXT" "$MEDIA_DIR/$LABEL/$LABEL.$DEST_EXT" 
			
			if [ "$SET_MEDIA_PERMISSIONS" = true ]; then
			
			chmod -R "$CHMOD_VALUE" "$MEDIA_DIR/$LABEL"
						
			fi
			
		fi

		#now move "extras"
		if [ "$PLEX_SUPPORT" = true ]; then
		
			# shellcheck disable=SC2129,SC2016
			mkdir -p -v "$MEDIA_DIR/$LABEL/Featurettes" 
			
			# Create Emby ignore file for "extras" Folder
			touch "$MEDIA_DIR/$LABEL/Featurettes/.ignore"  
			
			# shellcheck disable=SC2086
       			echo "Sending command: mv -n "\"$DEST/$LABEL/*\"" "\"$MEDIA_DIR/$LABEL/Featurettes/\""" 
       			mv -n "${DEST}"/* "$MEDIA_DIR/$LABEL/Featurettes/" 
			
			# Move Largest file to main folder for Plex/Emby/Kodi to detect main movie
			# shellcheck disable=SC2012
			ls -S "$MEDIA_DIR/$LABEL/Featurettes/" | head -1 | xargs -I '{}' mv "$MEDIA_DIR/$LABEL/Featurettes/"{} "$MEDIA_DIR/$LABEL/$LABEL.mkv" 
			
			if [ "$SET_MEDIA_PERMISSIONS" = true ]; then
			
			chmod -R "$CHMOD_VALUE" "$MEDIA_DIR/$LABEL"
						
			fi
		else
				
			# shellcheck disable=SC2129,SC2016
			mkdir -p -v "$MEDIA_DIR/$LABEL/extras" 
				
			# Create Plex ignore file for "extras" Folder
			touch "$MEDIA_DIR/$LABEL/extras/.plexignore"  
			touch "$MEDIA_DIR/$LABEL/extras/.nomedia"  
			
			# shellcheck disable=SC2086
      			echo "Sending command: mv -n "\"$DEST/$LABEL/*\"" "\"$MEDIA_DIR/$LABEL/extras/\""" 
       			mv -n "${DEST}"/* "$MEDIA_DIR/$LABEL/extras/" 
			
			# Move Largest file to main folder for Plex/Emby/Kodi to detect main movie
			# shellcheck disable=SC2012
			ls -S "$MEDIA_DIR/$LABEL/extras/" | head -1 | xargs -I '{}' mv "$MEDIA_DIR/$LABEL/extras/"{} "$MEDIA_DIR/$LABEL/$LABEL.mkv" 
			
			if [ "$SET_MEDIA_PERMISSIONS" = true ]; then
			
			chmod -R "$CHMOD_VALUE" "$MEDIA_DIR/$LABEL"
						
			fi
			
			if [ "$EMBY_REFRESH" = true ]; then
				# signal emby to scan library
					embyrefresh
			else
					echo "Emby Refresh False.  Skipping library scan" 
			fi
				
		fi
		rmdir "$DEST"
	fi

rmdir "$SRC" 

TRANSEND=$(date +%s);
TRANSSEC=$((TRANSEND-TRANSSTART));
TRANSTIME="$((TRANSSEC / 3600)) hours, $(((TRANSSEC / 60) % 60)) minutes and $((TRANSSEC % 60)) seconds."

echo "STAT: ${ID_FS_LABEL} transcoded in ${TRANSTIME}" 

#echo /opt/arm/rename.sh $DEST
if [ "$KODI_SUPPORT" == true ]; then /opt/arm/kodi-update.py --hosts=$KODI_CLIENTS 2>&1; fi
echo /opt/arm/notify.sh "\"Transcode: ${ID_FS_LABEL} completed in ${TRANSTIME}\"" |at now
