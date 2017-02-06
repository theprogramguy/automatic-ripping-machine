#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <linux/cdrom.h>


int main(int argc,char **argv) {
  int cdrom;
  int status=1;

cdrom = open(argv[1],O_RDONLY | O_NONBLOCK);
int result=ioctl(cdrom, CDROM_DRIVE_STATUS);

/*
exit(result);

#define CDS_NO_INFO		0
#define CDS_NO_DISC		1
#define CDS_TRAY_OPEN		2
#define CDS_DRIVE_NOT_READY	3
#define CDS_DISC_OK		4
*/
switch(result) {
  case CDS_NO_INFO: exit(1); break;
  case CDS_NO_DISC: exit(2); break;
  case CDS_TRAY_OPEN: exit(3); break;
  case CDS_DRIVE_NOT_READY: exit(4); break;
  case CDS_DISC_OK: exit(0); break;
  default: /* error */
	exit(9);
}

}
