#! /bin/bash -ue

# 03Oct23 Inital Version
# 20Oct23 Added ability to make permanent
# 03Nov23 Added testing mode, made power saving less aggressive, support muitiple drives
# 05Dec23 Given the NOTES below, switching to -B128 and use a script to spindown disks every hour (if unused)

# Notes on MY drives:
#
# sda => SAMSUNG HD103UJ       with a setting of -B127 it goes into standby after a few seconds
#                              with a setting of -B128 (do not spindown) and a sleep time of 1hr

# sdb => SAMSUNG HD154UI       with a setting of -B127 it goes into standby after a few seconds
#                              with a setting of -B128 (do not spindown) and a sleep time of 1hr

# sdc => HGST HDN724040ALE640, with a setting of -B127 it does not immediately go to sleep (it proably does after some time) ...however
#                              with a setting of -B128 (do not spindown) and a sleep time of 1 hour, it goes into standby @ 1 hour

# sdd => SAMSUNG HD154UI       with a setting of -B127 it goes into standby after a few seconds
#                              with a setting of -B128 (do not spindown) and a sleep time of 1hr




VERSION="1.0"

TMP1=$(mktemp)

on_exit() {
    : echo 'ON_EXIT: Cleaning up...(remove tmp files, etc)'
    rm -f ${TMP1}
}

trap 'on_exit' EXIT




usage() {
    cat >&2 <<EOF

USAGE: 
       $0 [-h|--help] [-v|--verbose] {-m|--mode} {fast|medium|powersave} \
          [--B255] [-t <sec> | --timeout <sec>] [-y|--sleep] [-p | --permanent] <drive>*

       Configure the drive <drive> so that it spins down if idle for <n>.

       -h | --help          This usage messsage
       -v | --verbose       More messages 
       -m | --mode	    power saving/heat profile
       -y | --sleep	    immediately spin the drive down
       -t | --timeout	    NOT NORMALLY USED** , allows you to set a very low time until spindown happens
       -p | --permanent	    Persist the changes into  /etc/hdparms.conf
       --B255		    Workaround for a BUG in some disk firmware (needs -B255 [disable APM] in order for APM to work!)

       This script was created on a TS412, with 4 drives installed in trays + 1 eSATA SSD

       Tray1=/dev/sda , Tray2=/dev/sdb , Tray3=/dev/sdc , Tray4=/dev/sdd , eSATA/USB ...sde, sdf etc

       If you have only 3 bays populated, the eSATA (or USB) would become sdd (not sde)

       Powersaving modes:

       		   fast - Get the highest performance of the disk. They will never spin down
		   	  and will be noiser and consume more power

		   powersave - The disk will spindown if unused for several minutes
		   	  much quieter and more power efficient, however the inital disk access
			  follwoing a sleep could be very long.

		   medium - Mid way between fast & powersave. The disks can spin down if not
		   	  used for a long period (e.g overnight) this value is defined by the HDD
			  so presuably is a "safe" one.

		   testing - Sets the most agressive power saving. Useful while you'll
		   	   checking you disk spindown (without waiting hours) but proably
			   damaging if used in "production" as the disk will be stopping
			   and strtiung all the time.

		   ** A note about timeout. Be aware once set on a disk this value will persist until changed
		      setting a very low value can be damaging over the long term. You generaly only use this
		      to test how spindown works, how quite it is, how much power it drawns, is any process
		      spiing the disk up when you don't expect it.
EOF

}



typeset -i verbose
typeset -i timeout
typeset -i t
typeset -i b255bug
typeset -i sleep
typeset -i permanent



verbose=0
timeout=0
mode="m"
umode=""
t=3600
b255bug=0
sleep=0
permanent=0

PROG=$0
ARGS=`getopt -o "pyhvm:t:" -l "permanent,sleep,B255,help,verbose,mode:,timeout:" -n "${PROG}" -- "$@"`

#Bad arguments
if [ $? -ne 0 ];
then
    usage
    exit 1
fi


eval set -- "$ARGS"

while true;
do
    case "$1" in
	-y|--sleep) 
	    sleep=1
	    shift;;
	-v|--verbose) 
	    verbose+=1
	    shift;;
	-p|--permanent) 
	    permanent+=1
	    shift;;
	-m|--mode) 
	    umode=$2
	    shift 2;;
	-t|--timeout) 
	    timeout=$2
	    shift 2;;
	-h|--help) 
	    usage ${PROG}
	    exit 0
	    shift;;
	--B255)
	    b255bug=1
	    shift;;
	--)
	    shift
	    break;;
    esac
done

# Curious vulnerability here (mentioned only for education) user could pass a
# regular expression to -m option and it would get obeyed here. I don't belive it
# could cause damage in this case.

if [[ -z "${umode}" ]] ; then
   echo "Mode must be defined" 2>&2
    usage ${PROG}
    exit 1
fi


if   [[ "fast" =~ "${umode}"       || "FAST" =~ "${umode}" ]]      ; then
    mode="f";
elif [[ "medium" =~ "${umode}"     || "MEDIUM" =~ "${umode}" ]]    ; then
    mode="m";
elif [[ "powersave" =~ "${umode}"  || "POWERSAVE" =~ "${umode}" ]] ; then
    mode="p";
elif [[ "testing" =~ "${umode}"    || "TESTING" =~ "${umode}" ]] ; then
    mode="t";
else
    echo "${umode} is not a recognised mode" >&2
    usage ${PROG}
    exit 1
fi
    

if [[ $# -lt 1 ]] ; then
    usage ${PROG}
    exit 1
fi

for DEV in $@
do
    case "${DEV}" in
	tray1|Tray1|1)
	    DEV="/dev/sda"
	    ;;
	tray2|Tray2|2)
	    DEV="/dev/sdb"
	    ;;
	tray3|Tray3|3)
	    DEV="/dev/sdc"
	    ;;
	tray4|Tray4|4)
	    DEV="/dev/sdd"
	    ;;
    esac


    if [[ ${verbose} -gt 0 ]] ; then
	echo "Verbose mode enabled VERSION=${VERSION}" >&2
    fi

    if [[ ! -b ${DEV} ]] ; then
	echo "${DEV} is not a block device (so not a disk)" >&2
	exit 1
    fi

    if [[ -L ${DEV} ]] ; then
	DEV="/dev/"$(basename $(readlink ${DEV}))
    fi



    if [[ "${DEV}" =~ /dev/sd[a-z]* || "${DEV}" =~ /dev/hd[a-z]* ]] ; then
	DEV=${DEV:0:8}
	echo "Using ${DEV}"
    else
	echo "The device name ${DEV} is not usable in hdparms.conf [ needs to be sd? or hd? ]"
    fi




    if [[ $(id -u) -ne 0 ]] ; then
	echo "You are $(id -un) you need to su or sudo to root before running this" >&2
	usage $0
	exit 2
    fi

    # hddparm:
    #
    # -B - 1-127 (permit spin‐down) 128-254 (do not permit spin‐down) 255 = turn off Advanced Power Managmewnt
    # -Y - spindown right now (if permitted)
    # -S - Spindown time  (complex encoding RTFM)  (-S253, special case RTFM)
    #

    BFLAG=""
    SFLAG=""
    BVALUE=""
    SVALUE=""


    if [[ ${mode} = "f" ]] ; then  #fast
	t=0  # We won't use this value
	BFLAG="-B 254"
	BVALUE="254"
    elif [[ ${mode} = "p" ]] ; then #powersave
	t=3600  # spindown after 1 hour
	BFLAG="-B 127"    # TBD Allow spindown, but don't set it too agressive (1 was spinning down during boot!)
	BVALUE="127"
    elif [[ ${mode} = "m" ]] ; then #medium
	t=0  # not set
	BFLAG="-B 128"     # TBD Disallow spindown [in theory]
	BVALUE="128"
    elif [[ ${mode} = "t" ]] ; then # testing
	t=30  # spindown after 30 seconds
	BFLAG="-B 1"
	BVALUE="1"
    fi

    # Notwithstanding the above, if timeout was explicitly set it takes precedence

    if [[ ${timeout} -gt 0 ]] ; then
	t=${timeout}
    fi

    if [[ ${b255bug} -gt 0 ]] ; then
	BFLAG="-B 255"
	BVALUE="255"
    fi



    # Workout the SFLAG (not times between 20 and 30 mins cannot be set (!) longest we can set is 5.5 hours
    # Actualy there are acouple of "special times" (21m and 21m15S which can be set, but we ignore)
    # We also ignore the vendor defined period (since we don't know what it is)

    SFLAG=""
    SVALUE=""
    typeset -i x

    if [[ ${t} -eq 0 ]] ; then	      # If the user set timeout, all bets are off (we'll just use that)
	if   [[ ${mode} == "f" ]] ; then  
	    SFLAG="-S 0"  # Turn off spindown
	    SVALUE="0"
	elif [[ ${mode} == "m" ]] ; then
	    SFLAG="-S 253"  # Special value uses sleep defined by the vendor
	    SVALUE="253"
	fi
    else
	if   [[ ${t} -le 1200  ]] ; then  # (240 * 5 = 1200) ...so up to 20 minutes
	    t=t/5
	    SFLAG="-S "${t}             # 5 second intervals
	    SVALUE="${t}"
	else                              # (11 * 30 mins = 19800 sec) ...we can't actually set less than 30 min
	    x="t/(30*60)"
	    if   [[ ${x} -lt 1 ]] ; then
		x=1
	    elif [[ ${x} -gt 11 ]] ; then # 11 * 30 min = 5.5hrs (19800 sec)
		x=11
	    fi
	    x+=240
	    SFLAG="-S ${x}"
	    SVALUE="${x}"
	fi
    fi

    if [[ ${verbose} -gt 0 ]] then
       echo -e "\n\n\nBefore we start the disk state is..."

       hdparm -B -C -M -rR -Q -W -Aa ${DEV}
    fi

    cmd="hdparm ${BFLAG} ${SFLAG} ${DEV}"

    if [[ ${verbose} -gt 0 ]] then
       echo -e "\n==============================================\n"
       echo "Running command: ${cmd}"
    fi

    command ${cmd}


    if [[ ${sleep} -gt 0 ]] ; then

	if [[ ${verbose} -gt 0 ]] ; then
	    echo -e "\n\nPutting drive to sleep immediately"
	fi

	hdparm -Y ${DEV}
    fi

    if [[ ${verbose} -gt 0 ]] then
       
       echo -e "\n==============================================\n"

       echo -e "\n\n\nAfter we finish start the disk state is..."

       hdparm -B -C -M -rR -Q -W -Aa ${DEV}
    fi

    if [[ ${permanent} -gt 0 ]] ; then
	cat <<EOF
**** Making chnages permanent ****

Not withstanding comments in the files and elesewhere
The ONLY format for devices is /dev/sd? or /dev/hd?
see: /usr/lib/pm-utils/power.d/95hdparm-apm and /lib/udev/hdparm
and since the association of Tray1=sda Tray2=sdb ... is not persistent
ANY tray1/disk can end up as any device.
So really you can only have ONE setting and it can apply to any disk.
EOF

	match=${DEV//\//\\\/}

	# Remove any existing stanza for this disk, add our version at the end.
	# (it's not essential we remove dead stanza but it will improve performance.)
	
	cat > ${TMP1} <<EOF
/${match}/,/}/ { next }
 { print }
 END {
     print "${DEV} {"
     print "    apm = ${BVALUE}"
     print "    spindown_time = ${SVALUE}"
     print "}"
 }
EOF
	cp /etc/hdparm.conf  /etc/hdparm.conf.old
	awk  -f ${TMP1}  < /etc/hdparm.conf.old > /etc/hdparm.conf

	if [[ ${verbose} -gt 0 ]] ; then	
	    echo "Edits made to /etc/hdparm.conf :"
	    diff /etc/hdparm.conf.old  /etc/hdparm.conf
	fi
    fi

done 
