#!/bin/bash
# shellcheck source=config
# shellcheck disable=SC1091
# Rip video using MakeMKV then eject and call transcode script
source "$ARM_CONFIG"
THE_LOG=$1
THE_DEV=$2
VIDEO_TITLE=$3
HAS_NICE_TITLE=$4
VIDEO_TYPE=$5
exec >> "$THE_LOG"
exec 2>&1

MEDIA_TYPE="ERROR"

if   [ "$ID_CDROM_MEDIA_BD" = "1" ]; then
	MEDIA_TYPE="BLURAY"
elif [ "$ID_CDROM_MEDIA_DVD" = "1" ]; then
	MEDIA_TYPE="DVD"
else
	MEDIA_TYPE="ERROR"
fi

echo "Ripping video ${VIDEO_TITLE} Labeled:${ID_FS_LABEL} from ${DEVNAME}"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S');
DEST="${RAWPATH}/${VIDEO_TITLE}_${TIMESTAMP}"
RIPSTART=$(date +%s);
mkdir -p "$DEST"
echo "Copying XML Template"


if [ "$HAS_NICE_TITLE" = true ]; then
	FINALDEST="${ARMPATH}/${VIDEO_TITLE}"
	if [ -d "$FINALDEST" ]; then
		echo "FINALDEST directory already exists... adding timestamp" 
		FINALDEST="${ARMPATH}/${VIDEO_TITLE}_${TIMESTAMP}"
	fi
else
	FINALDEST="${ARMPATH}/${VIDEO_TITLE}_${TIMESTAMP}"
fi
echo "FINALDEST ${FINALDEST} variable created"
mkdir -p "$FINALDEST"


#echo /opt/arm/video_transcode.sh \"$DEST\" \"$VIDEO_TITLE\" $TIMESTAMP >> $LOG
if [ "$RIPMETHOD" = "backup" ] && [ "$MEDIA_TYPE" = "BLURAY" ]; then
	echo "Using backup method of ripping."
	DISC="${DEVNAME: -1}"
	# shellcheck disable=SC2086
	makemkvcon backup --decrypt $MKV_ARGS -r disc:"$DISC" "$DEST"/
	eject "$DEVNAME"
elif [ "$MAINFEATURE" = true ] && "$MEDIA_TYPE" = "DVD" ]; then
	echo "Media is DVD and Main Feature parameter in config file is true.  Bypassing MakeMKV."
	echo "Transcoding DVD main feature only." 
	# echo "$HANDBRAKE_CLI -i $DEVNAME -o \"${DEST}/${LABEL}.${DEST_EXT}\" --main-feature --preset="${HB_PRESET}" --subtitle scan -F 2" >> $LOG
	# shellcheck disable=SC2086
        $HANDBRAKE_CLI -i "$DEVNAME" -o "${FINALDEST}/${LABEL}.${DEST_EXT}" --main-feature --preset="${HB_PRESET}" $HB_ARGS 
	eject "$DEVNAME"
	#rmdir "$DEST"

echo "DEST is ${DEST}"
else
	echo "Using mkv method of ripping."
	# shellcheck disable=SC2086
	makemkvcon mkv $MKV_ARGS dev:"$DEVNAME" all "$DEST" --minlength="$MINLENGTH" -r
	eject "$DEVNAME"
fi

RIPEND=$(date +%s);
RIPSEC=$((RIPEND-RIPSTART));
RIPTIME="$((RIPSEC / 3600)) hours, $(((RIPSEC / 60) % 60)) minutes and $((RIPSEC % 60)) seconds."

#eject $DEVNAME

#echo /opt/arm/notify.sh "\"Ripped: ${ID_FS_LABEL} completed from ${DEVNAME} in ${RIPTIME}\"" |at now

echo "STAT: ${ID_FS_LABEL} ripped in ${RIPTIME}"

if [ "$KODI_NOTIFY" == true ]; then /opt/arm/kodi-notify.py --hosts=$KODI_CLIENTS --msg="Rip Finished,$VIDEO_TITLE sent to transcode." 2>&1; fi

echo "/opt/arm/queue_video_transcode.sh \"$DEST\" \"$VIDEO_TITLE\" \"$HAS_NICE_TITLE\" \"$VIDEO_TYPE\" $TIMESTAMP"
echo "\"$DEST\"&\"$VIDEO_TITLE\"&\"$HAS_NICE_TITLE\"&\"$VIDEO_TYPE\"&\"$TIMESTAMP\"&\"$MEDIA_TYPE\"&\"$FINALDEST\"&\"$THE_LOG\"" >> "$RAWPATH/transcode.queue"
#echo "/opt/arm/queue_video_transcode.sh \"$DEST\" \"$VIDEO_TITLE\" \"$HAS_NICE_TITLE\" \"$VIDEO_TYPE\" \"$TIMESTAMP\" \"$MEDIA_TYPE\" \"$FINALDEST\" \"$LOG\"" | batch
echo "/opt/arm/queue_video_transcode.sh \"$DEST\" \"$VIDEO_TITLE\" \"$HAS_NICE_TITLE\" \"$VIDEO_TYPE\" \"$TIMESTAMP\" \"$MEDIA_TYPE\" \"$FINALDEST\" \"$LOG\""
echo "${ID_FS_LABEL} sent to transcoding queue..."
