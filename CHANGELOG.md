# Changelog

## v1.4.0 
 - Added udev logging from arm_wrapper.sh into /opt/arm/logs/udev.log to diagnose udev issues, and to log double udev calls for a single insert
 - Added Flocker support for locking file to prevent a double rip getting started
 - Added small program drivestatus.bin to identify if the tray is open or closed and if media is ready or not before running script (prevents huge log entries on disc ejects)
 - Added 'nice' for all transcoding operations
 - Added makefile config to enable quick setup, just gitclone and make
 - Moved Disc identification to a function inside identify.sh
 - Added Disc identification even if ARM_CHECK_UDF is set to false
 - Changed logfile redirection to be more uniform and efficient 
 - Added Kodi support in config file
 - Added Kodi .nomedia creation in extras folder
 - Added Kodi notification support of ripping status

## v1.3.0
 - Get Title for DVD and Blu-Rays so that media servesr can identify them easily.
 - Determine if video is Movie or TV-Show from OMDB API query so that different actions can be taken (TV shows usually require manual episode identification)
 - Option for MakeMKV to rip using backup method.
 - Option to rip only main feature if so desired.

## v1.2.0
- Distinguish UDF data from UDF video discs

## v1.1.1

- Added devname to abcde command
- Added logging stats (timers). "grep STAT" to see parse them out.

## v1.1.0

- Added ability to rip from multiple drives at the same time
- Added a config file for parameters
- Changed logging
  - Log name is based on ID_FS_LABEL (dvd name) variable set by udev in order to isolate logging from multiple process running simultaneously
  - Log file name and path set in config file
  - Log file cleanup based on parameter set in config file
- Added phone notification options for Pushbullet and IFTTT
- Remove MakeMKV destination directory after HandBrake finishes transcoding
- Misc stuff

## v1.0.1

- Fix ripping "Audio CDs" in ISO9660 format like LOTR.

## v1.0.0

- Initial Release
