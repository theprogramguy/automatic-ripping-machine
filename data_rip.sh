#!/bin/bash
# shellcheck disable=SC1091
# shellcheck source=config
# Rip Data using DD
source "$ARM_CONFIG"
exec >> "$LOG"
exec 2>&1

TIMESTAMP=$(date '+%Y%m%d_%H%M%S');
DEST="${DATA_DIR}${TIMESTAMP}_${ID_FS_LABEL}"
mkdir -p "$DEST"
FILENAME=${ID_FS_LABEL}_disc.iso


#dd if=/dev/sr0 of=$DEST/$FILENAME 
cat "$DEVNAME" > "$DEST/$FILENAME"
eject "$DEVNAME"

if [ "$SET_MEDIA_PERMISSIONS" = true ]; then
	chmod -R "$CHMOD_VALUE" "$DEST"	
fi

