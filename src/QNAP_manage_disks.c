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

#include <sys/utsname.h>


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


struct names {const char const *longname; const char const *shortname;};

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

static char  kernel[64];  /* annoyingly length is undefined */

struct datapoint {
	int	count;  /* wakup in this session (e.g. 1 of 24) */
	time_t	timestamp;
	long	reads[MAX_DISKS];
	long	writes[MAX_DISKS];
	long	temp[MAX_DISKS];
};

/* Arrays of unchanging data. The names of the disks, the names of the
   temperature sensors and the name of the IO stats "file" */

const char *disks[MAX_DISKS]	   = {NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL};
char      **sensors;
char      **stats;

char	   *prog;



/* so a single "datapoint" is one reading for all these values for all drives NOW */
static void capture_datapoint(int count, int no_disks, char drives[], struct datapoint *d) {

	int rio;
	int rm;
	int rs;
	int rt;
	int wio;
	int wm;
	int ws;
	int wt;
	int iff;
	int iot;
	int tiq;
	int dio;
	int dm;
	int ds;
	int dt;

	int temp;
	
	FILE  *f;
	char  *line = NULL;
	size_t len = 0;

	char   buffer[256];

	int	i;
	
	d->count=count;
	d->timestamp=time(NULL);

	for (i=0; i<no_disks; ++i) {
	
		f=fopen(stats[i], "r");

		fgets(buffer, 256, f);
	
		sscanf(buffer, "%d %d %d %d  %d %d %d %d  %d %d %d  %d %d %d %d" ,
		       rio, rm, rs, rt,   wio, wm, ws, wt,   iff, iot, tiq,  dio, dm, ds, dt);
		d->reads[i]  = rs;
		d->writes[i] = ws;

		fclose(f);

		f=fopen(sensors[i], "r");

		fgets(buffer, 256, f);
		sscanf(buffer, "%d" , temp);

		d->temp[i] = temp;		
	}
	
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




static const char *getname(const char* string){
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



int main(int argc, char **argv)
{
	bool help          = false;
	bool version       = false;
	bool verbose       = false;
	bool debug         = false;
	bool notemperature = false;
	bool dryrun        = false;
	int  sleep         = 3600;
	int  logevery      = 24;
	
	int  i;
	int  j;
	int  no_disks;
	const char *p;

	int	count   = 0; // e.g. 0-23 (typically hours)
	int	session = 0; // 0..maxint (typically days)
	
	
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
			case 's': sleep=atoi(optarg);	break;
			case 'l': logevery=atoi(optarg);break;
			case '?':                       break;
			}
	}

	argc -= optind;
	argv += optind;

	if (argc == 0) {
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
			sleep,
			logevery);
	}

	stats  =enumerate_stats  (no_disks, disks);  /* get the names of the IO stats "file" */

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



	exit(0);

	
	while (true) {
		for (count=0; count<logevery; ++count) {

			/*-------------------		
		do-stuff;
		sleep;

			
		}
		dump_data;
		reset;
		---------------------*/
		
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
