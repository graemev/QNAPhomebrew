#include <errno.h>

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <unistd.h>
#include <getopt.h>

#include <fcntl.h>


#include <sys/stat.h>
#include <sys/types.h>
#include <sys/un.h>


#include <sys/ioctl.h>
#include <linux/types.h>
#include <scsi/sg.h>


/* These are just copied directly from the hdparm package. This is pretty poor
   show, they should be installed somewhere */

#include "sgio.h"

  


#define VERSION "0.1"

char *version = "myhdparm " VERSION "\n";
char *usage = "Usage: myhdparm [OPTION...] disks\n"
              "      --help                 Give this help list\n"
              "  -C, --check                check state of disk\n\n"
              "  -Y, --sleep                send dsik to sleep\n\n"
              "  -V, --version              Print program version\n\n"
	;

enum mode {
	checkit,
	sleepit
};

static  struct scsi_sg_io_hdr io_hdr;  
static  unsigned char         cdb[SG_ATA_16_LEN];                                                             // command buffer
static  unsigned char         sb[32] = {0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0};  // Sense bytes



int do_sleep(int fd) {
	int rc;

	__u8 mode1_args[4] = {ATA_OP_SLEEPNOW1,0,0,0};
	__u8 mode2_args[4] = {ATA_OP_SLEEPNOW2,0,0,0};

	if (rc=((do_drive_cmd(fd, mode1_args, 0) == -1) &&  /* Mode1 sleep fails AND */
		(do_drive_cmd(fd, mode2_args, 0) == -1))) {  /* Mode2 sleep fails THEN */
		perror("Dive sleep failed");
	}
	return rc;  /* errno will bet set iff rc==-1 */
}

/*
 * Check if the disk is spundown ... 
 *
 */

#define IS_UNKNOWN  0
#define IS_STANDBY  1
#define IS_SPINDOWN 2
#define IS_SPINUP   3
#define IS_IDLE     4
#define IS_ACTIVE   5


int do_check(int fd) {
	int err;
	int rc;

	__u8 args[4] = {ATA_OP_CHECKPOWERMODE1,0,0,0};

	const char *state = "unknown";
	
	if (   (rc=do_drive_cmd(fd, args, 0)) == -1) { /* MODE1=0xe5  */
		args[0] = ATA_OP_CHECKPOWERMODE2;      /* try again with MODE2=0x98 */
		rc=do_drive_cmd(fd, args, 0);
	}
	

	if (rc == -1)
		perror("Check powermode failed");
	
	else {
		switch (args[2]) {
		case 0x00: state = "standby";		rc=IS_STANDBY;  break;
		case 0x40: state = "NVcache_spindown";	rc=IS_SPINDOWN; break;
		case 0x41: state = "NVcache_spinup";	rc=IS_SPINUP;   break;
		case 0x80: state = "idle";		rc=IS_IDLE;     break;
		case 0xff: state = "active/idle";	rc=IS_ACTIVE;   break;
		}
	}
	printf(" drive state is:  %s\n", state);

	return rc;  /* errno will bet set iff rc==-1 */
}




int main(int argc, char **argv)
{
	bool       help = false;
	enum mode  mode = checkit;
	char      *device;
	
	int        err = 0;
	int        fd;
	
	while (1) {
		struct option long_options[] = {
			{"sleep",       no_argument,       0, 'Y' },
			{"check",       no_argument,       0, 'C' },

			{"help",        no_argument,       0, 'h' },
			{"version",     no_argument,       0, 'V' },
			{0, 0, 0, 0}
		};

		int opt = getopt_long(argc, argv, "YChV",
				      long_options, NULL);

		if (opt == -1)
			break;

		switch (opt) {
		case 'Y': mode = sleepit;		break;
		case 'C': mode = checkit;		break;

		case 'h': help = 1;                     break;
		case 'V': printf("%s", version);        return 0;
		case '?':                               break;
		}
	}
		
	if (help) {
		fprintf(stderr, "%s", usage);
		return 0;
	}


	argc -= optind;
	argv += optind;

	//------------------------------------

	while (argc--) {
		device=*argv;
		argv++;

		if ((fd = open(device, O_RDONLY|O_NONBLOCK)) ==-1 ) {
			fprintf(stderr, "%s" , device);
			perror("-open: ");
		}
		else {
			printf("%s: ", device);
		

			switch (mode) {
			case checkit:
				do_check(fd);
				break;
			case sleepit:
				do_sleep(fd);
				break;
			}

			close(fd);
		}
	}
}

/*
--
-- Local variables:
-- mode: C
-- c-basic-offset: 8
-- End:
*/
