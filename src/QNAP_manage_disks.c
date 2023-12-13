/*
 * Copyright (C) 2023 Graeme Vetterlein (graeme.debian@vetterlein.com)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef VERSION
#define VERSION "0.2"
#endif

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
#include <glob.h>
#include <time.h>
#include <limits.h>

#include <sys/utsname.h>

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

/* Possible disk states ... */

#define IS_UNKNOWN  0
#define IS_STANDBY  1
#define IS_SPINDOWN 2
#define IS_SPINUP   3
#define IS_IDLE     4
#define IS_ACTIVE   5

static char * str_disk_state(int state) {
	char * s;
	switch(state) {

	case IS_STANDBY : s="STANDBY"  ; break;
	case IS_SPINDOWN: s="SPINDOWN" ; break;
	case IS_SPINUP  : s="SPINUP"   ; break;
	case IS_IDLE    : s="IDLE"     ; break;
	case IS_ACTIVE  : s="ACTIVE"   ; break;
	default:
	case IS_UNKNOWN : s="UNKNOWN"     ;
	}
	return(s);  /* safe as we return only value (a pointer) and string are CONST+static */
}
       


/* Possible disk actions ... */

#define NO_ACTION   0
#define STOP_SPIN   1
/* there are other actions we could take, short to total stop of spinning */

static char * str_disk_action(int action) {
	char * s;
	switch(action) {

	case NO_ACTION  : s="No Action"  ; break;
	case STOP_SPIN  : s="Spindown"  ; break;
	default		: s="Unknown"    ;
	}
	return(s);  /* safe as we return only value (a pointer) and string are CONST+static */
}
       

#define MAX_DISKS 10

/* 4 internal disks, 2XeSATA, 4XUSB */
static const char sda[]="sda";
static const char sdb[]="sdb";
static const char sdc[]="sdc";
static const char sdd[]="sdd";

static const char sde[]="sde";
static const char sdf[]="sdf";

static const char sdg[]="sdg";
static const char sdh[]="sdh";
static const char sdi[]="sdi";
static const char sdj[]="sdj";


struct names {const char * const  longname; const char * const shortname;};

static	struct names names[]={
	{"/dev/sda","sda"},
	{"tray1"   ,sda},
	{"sda"     ,sda},

	{"/dev/sdb",sdb},
	{"tray2"   ,sdb},
	{"sdb"     ,sdb},

	{"/dev/sdc",sdc},
	{"tray3"   ,sdc},
	{"sdc"     ,sdc},

	{"/dev/sdd",sdd},
	{"tray4"   ,sdd},
	{"sdd"     ,sdd},

	{"/dev/sde",sde},
	{"sde"     ,sde},

	{"/dev/sdf",sdf},
	{"sdf"     ,sdf},

	{"/dev/sdg",sdg},
	{"sdg"     ,sdg},

	{"/dev/sdh",sdh},
	{"sdh"     ,sdh},

	{"/dev/sdi",sdi},
	{"sdi"     ,sdi},

	{"/dev/sdj",sdj},
	{"sdj"     ,sdj},

	{NULL     ,NULL}
};

static	bool verbose       = false;
static	bool debug         = false;
static	bool notemperature = false;
static	bool dryrun        = false;



static char  kernel[64];  /* annoyingly length is undefined */

struct datum {
	int	state;   /* eg spinning or not */
	int	action;	 /* action we took, e.g. sleeping disk */
	long	reads;
	long	writes;
	int	temp;
};

struct datapoint {
	time_t	timestamp;
	struct datum *data; /* array , one per disk */
};

/* Arrays of unchanging data. The names of the disks, the names of the
   temperature sensors and the name of the IO stats "file" */

const char *disks[MAX_DISKS]	   = {NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL};
char      **sensors;
char      **stats;

char	   *prog;


/* get the shortname (sda, sdb,sdc etc) for the drive name passed */
static const char *getname(const char* string) {
	struct names	*p;
	char const	*result = NULL;
	
	for (p=names; p->longname; ++p) {
		if (strcasecmp(string, p->longname) == 0) {
			result=p->shortname;
			break;
		} 
	}
	return (result);
}

static void usage(const char *prog) {

	fprintf(stderr, 
		"USAGE: %s [-V|--version]\n"
		"\t\t[-T|--notemperature]\n"
		"\t\t[{-s|--sleep} <seconds>]\n"
		"\t\t[{-v|--verbose}]\n"
		"\t\t[{-d|--debug}]\n"
		"\t\t[{-l|--logevery} <n>]\n"
		"\t\t[-n|--dry-run]\n"
		"\t\t[-h|--help]\n"
		"\t\t<drive>*\n"
		"\t\t\n"
		"\t\t-V|--version		- Just print version No and then exit\n"
		"\t\t-T|-notemperature    - Don't attempt to monitor disk temperature\n"
		"\t\t-s|--sleep <seconds> - default 3600 , wake up after this many seconds and take action\n"
		"\t\t-v|--verbose}	- be verbose, normally we report very little\n"
		"\t\t-l|--logevery	- default 24 Write (to log) every n wakups (e.g. once a day)\n"
		"\t\t-n|--dry-run		- Don't actually spin down the disks, just log\n"
		"\t\t<drive>*		- list of drives to be managed.\n",
		prog
		);
}

/* e.g.: /sys/block/${disk}/stat */
static char ** enumerate_stats  (int no_disks, const char **drives) {
	char  **stats;
	char    buffer[32];
	int	i;

	stats = calloc(no_disks, sizeof(char*));

	for (i=0; i<no_disks; ++i) {
		sprintf(buffer, "/sys/block/%s/stat", drives[i]);
		stats[i]=strdup(buffer);
	}
	return stats;
}


/* e.g.: /sys/block/${disk}/device/hwmon/hwmon* /temp1_input  */
static char ** enumerate_sensors  (int no_disks, const char **drives) {
	char  **sensors;
	char    buffer[64];
	glob_t  glob_struct;
	int	i;

	sensors = calloc(no_disks, sizeof(char*));

	for (i=0; i<no_disks; ++i) {
		sprintf(buffer, "/sys/block/%s/device/hwmon/hwmon*/temp1_input", drives[i]);
		
		if (glob(buffer, GLOB_ERR,  NULL, &glob_struct)) {
			fprintf(stderr, "no temperature sensor for %s consider reruning with -T\n", drives[i]);
			sensors=NULL;
			break;
		}
		else {
			sensors[i]=strdup(glob_struct.gl_pathv[0]); /* should only be one */
		}
		globfree(&glob_struct);
	}
	return sensors;
}

static char * getkernel() {
	struct utsname buf;

	if (uname(&buf) == -1) {
		perror("uname:");
		exit(2);
	}
	strncpy(kernel, buf.release, 64);
	return (kernel);
}


/* find out if disk is spinning ... based on code taken from hdparm */
int get_disk_state(const char disk[]) { /* just sda or sdb etc */   /* TBD */
	int rc;
	char devicename[16];
	int	fd;
	
	__u8 args[4] = {ATA_OP_CHECKPOWERMODE1,0,0,0};

	sprintf(devicename, "/dev/%s", disk);
	
	if ((fd = open(devicename, O_RDONLY|O_NONBLOCK)) ==-1 ) {
		fprintf(stderr, "%s" , devicename);
		perror("-open: (are we root?)");
	}
	
	if (   (rc=do_drive_cmd(fd, args, 0)) == -1) { /* MODE1=0xe5  */
		args[0] = ATA_OP_CHECKPOWERMODE2;      /* try again with MODE2=0x98 */
		rc=do_drive_cmd(fd, args, 0);
	}

	if (rc == -1)
		perror("Check powermode failed");
	
	else {
		switch (args[2]) {
		case 0x00: rc=IS_STANDBY;  break;
		case 0x40: rc=IS_SPINDOWN; break;
		case 0x41: rc=IS_SPINUP;   break;
		case 0x80: rc=IS_IDLE;     break;
		case 0xff: rc=IS_ACTIVE;   break;
		}
	}
	close(fd);

	return rc;  /* errno will bet set iff rc==-1 */
}


/* stop the disk spinning ... based on code taken from hdparm */
int spindown_disk(const char disk[]) { /* just sda or sdb etc */   /* TBD */

	int  rc;
	char devicename[16];
	int  fd;

	__u8 mode1_args[4] = {ATA_OP_SLEEPNOW1,0,0,0};
	__u8 mode2_args[4] = {ATA_OP_SLEEPNOW2,0,0,0};

	if (dryrun)
		return 0;

	sprintf(devicename, "/dev/%s", disk);

	if ((fd = open(devicename, O_RDONLY|O_NONBLOCK)) ==-1 ) {
		fprintf(stderr, "%s" , devicename);
		perror("-open: (are we root?)");
	}
	
	if (((rc=do_drive_cmd(fd, mode1_args, 0)) == -1) &&  /* Mode1 sleep fails AND */
		(do_drive_cmd(fd, mode2_args, 0) == -1)) {  /* Mode2 sleep fails THEN */
		perror("Drive sleep failed");
	}
	
	close(fd);
	
	return rc;  /* errno will bet set iff rc==-1 */
}

/* so a single "datapoint" is one reading for ALL these values for ALL drives NOW */
static void capture_datapoint(int no_disks, const char *drives[], struct datapoint *d) {

	int rio, rm, rs, rt, wio, wm, ws, wt, iff, iot, tiq, dio, dm, ds, dt;

	int temp;

	FILE  *f;

	char   buffer[256];

	int	i;
	struct datum  *pdata;   /* array of datum    */
	struct datum  *pdatum;  /* instance of datum */

	d->timestamp=time(NULL);

	pdata=d->data;

	for (i=0; i<no_disks; ++i) {

		pdatum = &pdata[i];

		pdatum->state = get_disk_state(disks[i]);			/* STATE  */
		pdatum->action= NO_ACTION;					/* ACTION */

		f=fopen(stats[i], "r");   /* eg  /sys/block/sdc/stat  */
		fgets(buffer, 256, f);
		sscanf(buffer, "%d %d %d %d  %d %d %d %d  %d %d %d  %d %d %d %d" ,
		       &rio, &rm, &rs, &rt,   &wio, &wm, &ws, &wt,   &iff, &iot, &tiq,  &dio, &dm, &ds, &dt);
		pdatum->reads  = rs;						/* READS */
		pdatum->writes = ws;						/* WRITES*/
		fclose(f);

		if (notemperature)
			pdatum->temp = 0;
		else {
			if (NULL==(f=fopen(sensors[i], "r")))  /* eg /sys/block/sdc/device/hwmon/hwmon3/temp1_input  */
			    pdatum->temp = -1;
			    else {
				    fgets(buffer, 256, f);
				    sscanf(buffer, "%d" , &temp);		/* TEMP*/
				    pdatum->temp = temp;
				    fclose(f);
			    }
		}

	}
}

/*
 * Since we never spin a disk up, if the disk is sleeping (IS_STANDBY) the we do nothing.
 * Otherwise if the current{read/write} == prev(read/write) we choose to spin it down
 *
 * FUTURE ENHANCEMENT. Allow each disk a (different) grace period, so only
 * spindown after 2 or 3 no-IO samples. This would allow different strategies
 * for different disks. e.g a filesystem known to have overnight only access
 * (say backups) would be used intensively then could be stopped if there was no
 * IO for 5 minutes (meaning backups are over) another that gets used ad-hoc
 * during the day then not at all at night, we may want to wait a couple of
 * hours to be sure people were finished for the day.
 */

static void action_data(int no_disks, struct datapoint *pprev, struct datapoint *pcurrent) {

	int i;

	for (i=0; i<no_disks; ++i) {
		if (pcurrent->data[i].state == IS_STANDBY) {
			pcurrent->data[i].action = NO_ACTION;
		}

		else if ((pcurrent->data[i].reads  == pprev->data[i].reads) &&
			 (pcurrent->data[i].writes == pprev->data[i].writes)) {
			pcurrent->data[i].action = STOP_SPIN;
			spindown_disk(disks[i]);
		}
	}
}

/* TBD a complicated report on what we did */
void	print_summary(int no_samples, int no_disks, struct datapoint *alldata) {
	
	int sample;
	int disk;
	struct datum *ad;  /* array of datum */
	struct datum *d;   /* single datum   */

	struct datum *prev_ad;  /* array of datum */
	struct datum *prev_d;   /* single datum   */

	struct tm     timestamp;
	char          buffer[32];

	int	      sleep_count[MAX_DISKS]; /* Number of times we put the disk to sleep (should be low) */
	int	      high_C[MAX_DISKS];      /* high temperature */
	int	      low_C[MAX_DISKS];       /* low temperature */

	
	
	if (debug) {
		fprintf(stderr, "\n\nDEBUG: alldata %d samples each with %d disks:\n", no_samples, no_disks);

		for (sample=0; sample<no_samples; ++ sample) {
			fprintf(stderr, "DEBUG: sample %d datapoint %p:\n", sample, alldata+sample);
			fprintf(stderr, "DEBUG:   timestamp=%ld data=%p:\n", alldata[sample].timestamp,alldata[sample].data );

			ad = alldata[sample].data;

			for (disk=0; disk<no_disks; ++disk) {
				d=ad+disk;  /* same thing as &(ad[disk) */
				fprintf(stderr, "DEBUG:     datum=%p, disk_no=%d, disk=%s ", d, disk, disks[disk]);
				fprintf(stderr, "state=%d,action=%d,reads=%ld,writes=%ld,temp=%d\n",
					d->state,d->action,d->reads,d->writes,d->temp);
			}
		}
	}

	if (verbose) {
		printf("%s: %d samples %d disks (1st sample not shown)\n"   , prog, no_samples, no_disks);
		for (sample=1; sample<no_samples; ++ sample) {
			(void)strftime(buffer, 32,"%F-%T%z  ",localtime_r(&(alldata[sample].timestamp), &timestamp));

			printf("@ %s: \n", buffer );
			ad = alldata[sample].data;  prev_ad = alldata[sample-1].data;
			for (disk=0; disk<no_disks; ++disk) {
				d=ad+disk; prev_d=prev_ad+disk;
				printf("    Disk %s was in state %s its temperature was %d C, we decided to %s "
				       "it had done %ld reads and %ld writes since prev sample\n",
				       disks[disk], str_disk_state(d->state), d->temp/1000, str_disk_action(d->action),
				       d->reads-prev_d->reads,d->writes-prev_d->writes);
			}
		}
	}
	for (disk=0; disk<MAX_DISKS; ++disk) {
		sleep_count[disk] = high_C[disk] = 0;
		low_C[disk] = INT_MAX;
	}
	for (sample=1; sample<no_samples; ++ sample) {
		ad = alldata[sample].data;
		for (disk=0; disk<no_disks; ++disk) {
			d=ad+disk;
			if (d->action == STOP_SPIN)
				sleep_count[disk]+=1;
			if (d->temp > high_C[disk])
				high_C[disk] = d->temp;
			if (d->temp < low_C[disk])
				low_C[disk] = d->temp;
		}
	}


	(void)strftime(buffer, 32,"%F-%T%z  ",localtime_r(&(alldata[0].timestamp), &timestamp));          /* starttime */
	printf("Between %s and ",  buffer);
	(void)strftime(buffer, 32,"%F-%T%z  ",localtime_r(&(alldata[no_samples-1].timestamp), &timestamp)); /* endtime */
	printf("%s %d samples: ",  buffer, no_samples);
	
	for (disk=0; disk<no_disks; ++disk) {
		printf(" %s stopped %d times",  disks[disk], sleep_count[disk]);

		if (notemperature)
			printf(" its temperature was not measured");
		else
			printf(" Temp %dC-%dC", low_C[disk]/1000, high_C[disk]/1000);
	}
	printf("\n");
}

/* load the required kernel module */
static int load_drivetemp() {

	int rc=0;
	// Did consider this route (to avoid touching the disk, eg loding other programs
	// see: https://stackoverflow.com/questions/5947286/how-to-load-linux-kernel-modules-from-c-code
	// Also man  finit_module(2)
	// But modprobe(8) does a lot of dependency checking that is good to do
	// So we only do this right at the start...this is not a function that needs calling more than once
	// (OK it's possible if somebody is messing with unloading module but that's going to break stuff)

	if (system("modprobe drivetemp") != 0) {
		fprintf(stderr, "%s: problems with 'modprobe drivetemp',  carrying on, we may hit problem later\n", prog);
		rc=-1;
	}
	return rc;
}


int main(int argc, char **argv)
{
	bool help          = false;
	bool version       = false;
	int  sleep_time    = 3600;
	int  logevery      = 24;
	
	int  i;
	int  j;
	int  no_disks;
	const char *p;

	int	sample  = 0; // e.g. 0-23 (typically hours)

	struct datapoint *alldata;  /* actually an array of datapoints */
	
	prog=argv[0];
	
	while (1) {
		struct option long_options[] = {
			{"version",		no_argument,       0, 'V' },
			{"notemperature",	no_argument,       0, 'T' },
			{"help",		no_argument,       0, 'h' },
			{"dry-run",		no_argument,       0, 'n' },
			{"verbose",		no_argument,       0, 'v' },
			{"debug",		no_argument,       0, 'd' },
			{"sleep",		required_argument, 0, 's' },
			{"logevery",		required_argument, 0, 'l' },
			{0, 0, 0, 0}
		};

		int opt = getopt_long(argc, argv, "VThnvds:l:", long_options, NULL);

		if (opt == -1)
			break;

		switch (opt)
			{
			case 'V': version=true;		break;
			case 'T': notemperature=true;	break;
			case 'v': verbose=true;		break;
			case 'd': debug=true;		break;
			case 'h': help=true;            break;
			case 'n': dryrun=true;		break;
			case 's': sleep_time=atoi(optarg);break;
			case 'l': logevery=atoi(optarg);  break;
			case '?':                         break;
			}
	}

	argc -= optind;
	argv += optind;

	if (argc == 0) {
		usage(prog);
		exit(1);
	}

	if (help) {
		fprintf(stderr, "%s VERSION=%s\n", prog, VERSION);
		usage(prog);
		exit(1);
	}

	if (version) {
		fprintf(stderr, "%s VERSION=%s\n", prog, VERSION);
		exit(1);
	}

	for (i=0,j=0; i<argc; ++i) {
		if (j>=MAX_DISKS) {
			fprintf(stderr, "Too many disk arguments\n");
			exit(1);
		}

		if ((p=getname(argv[i])) == NULL) {
			fprintf(stderr, "%s is not a valid disk name\n", argv[i] );
			exit(1);
		}
		disks[j++]=p;
	}
	
	no_disks = j;

	if (dryrun)
		fprintf(stderr, "This is a dryrun, disks will NOT be spun down\n");
	
	if (verbose) {
		fprintf(stderr,
			"%s version %s\n"
			"verbose option, we will be noisy...may wake up disks\n"
			"The disks being managed are ",
			prog,
			VERSION
			);

		for (i=0; i<no_disks; ++i) 
			fprintf(stderr, "%s ", disks[i]);
		

		fprintf(stderr,
			"\nSleep time is %d seconds\n"
			"Logging will happen every %d wake ups\n",
			sleep_time,
			logevery);
	}

	

	stats = enumerate_stats  (no_disks, disks);  /* get the names of the IO stats "file" */

	
	if (!notemperature) {
		(void)load_drivetemp();			     /*consider turning on notemperature if load failed*/
		sensors=enumerate_sensors(no_disks, disks);  /* get the names of the temperature "file"        */

		if (sensors == NULL) {
			fprintf(stderr, "Temperature sensors are not available, will run without\n");
			notemperature=true;
		}
	}
	
	fprintf(stderr, "Kernel=%s\n", getkernel());


	if (debug) {
		fprintf(stderr, "Will monitor these /sys files\n");
		for (i=0; i<no_disks; ++i) {
			fprintf(stderr, "Disk [%s], IO=[%s], temperature=[%s]\n",
				disks[i],
				stats[i],
				(sensors?sensors[i]:"NULL"));
		}
	}


	/*======================================================================================================*/

	/*
	 *  alldata ---> datapoint[0]
	 *               datapoint[1]
	 *                datapoint[2].timestamp  
	 *                datapoint[2].data ---------------->  datum[0] (ie sda)
	 *               datapoint[3]                          datum[1] (ie sdb)
	 *               datapoint[4]                          datum[2]
	 *               datapoint[5]                           datum[3].state
	 *               ...                                    datum[3].action
	 *               datapoint[logevery-1]                  datum[3].writes
	 *                                                      datum[3].temp
	 *
	 * So higlighted here is the 3rd sample (no 2) 
	 *   on the 3rd sample the fourth datum (e.g. sdd) 
	 *     
	 *  so the "state" here would be the state (spinning or not) of /dev/sdd in e.g. the 3rd hour of the run.
	 *
	 * This data structure is malloced once and then never freed. It gets freed when we exit.
	 *
	 *
	 *
	 *
	 *
	 */

	if (verbose) {
		printf("Space used by data structures is %d + %d bytes\n",
		       logevery*sizeof(struct datapoint), logevery * (no_disks*sizeof(struct datum)));
	}

	alldata = calloc(logevery, sizeof(struct datapoint));    /* eg 24 datapoints */

	if (debug)
		fprintf(stderr, "alldata=%p\n", alldata);


	for (i=0; i<logevery; ++i) {
		alldata[i].timestamp = 0;
		alldata[i].data      = calloc(no_disks, sizeof(struct datum));
		if (debug)
			fprintf(stderr, "alldata[%d].data=%p\n", i, alldata[i].data);

	}
	
	while (true) {						   /* Run forever */
		for (i=0; i<logevery; ++i) 
			alldata[i].timestamp = 0;		  /* zero all timestamps (we reuse this structure) so on abnormal exit we know its invalid */
	       
		capture_datapoint(no_disks,disks,&(alldata[0]));   /* (single datapoint) grab the initial numbers */

		for (sample=1; sample<logevery; ++sample) {
			sleep(sleep_time);
			capture_datapoint(no_disks, disks, alldata+sample); /* grab the current numbers */
			action_data(no_disks, &alldata[sample-1], &alldata[sample]);   /* take action based on old vs new numbers */
		}
		print_summary(logevery, no_disks, alldata);			    /* dump a log of what we found */
	}
}


/*
--
-- Local variables:
-- mode: C
-- c-basic-offset: 8
-- End:
*/
