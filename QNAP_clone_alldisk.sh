#! /bin/bash -ue

# 12Oct23 Inital Version

PATH=/usr/local/bin:$PATH export PATH

VERSION="1.0"

on_exit() {
    : echo 'ON_EXIT: Cleaning up...(remove tmp files, etc)'
#    rm -f ${TMP1}
}

trap 'on_exit' EXIT




usage() {
    cat <<EOF

USAGE: 
       $0 

       Clone all drives for use in NAS, using "homebrewNAS" config.

       -v | --version	    Just print version number and exit
       -h | --help	    Just print this message and exit

       Designed to be used in a start-up or cronjob. Simply calls
       QNAP_clone_disk.sh on all the drives bar the current one.

       So if we are booted with root2 mounted on "/" and boot1-5
       are found., it will call it with the options

       QNAP_clone_disk -q -b1
       QNAP_clone_disk -q -b3
       QNAP_clone_disk -q -b4
       QNAP_clone_disk -q -b5

       NB QNAP_clone_disk clones boot,root,var & home

       This script was created on a TS412, with 4 drives installed in trays + 1 eSATA SSD

       Tray1=/dev/sda , Tray2=/dev/sdb , Tray3=/dev/sdc , Tray4=/dev/sdd , eSATA/USB ...sde, sdf etc

       If you have only 3 bays populated, the eSATA (Uor USB) would become sdd (not sde)

EOF
}

typeset -i version

version=0

PROG=$0
ARGS=`getopt -o "Vh" -l "version,help" -n "${PROG}" -- "$@"`

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
	-V|--version) 
	    version+=1
	    shift;;
	-h|--help) 
	    usage ${PROG}
	    shift;;
	--)
	    shift
	    break;;
    esac
done

if [[ $# -ne 0 ]] ; then
    usage ${PROG}
    exit 1
fi


if [[ ${version} -gt 0 ]] ; then
    echo "${PROG} VERSION=${VERSION}" >&2
    exit 0
fi

typeset -i b

# Determine OUR boot number (ugly)
x=$(df /)
ourbootnumber=$(echo ${x} | sed "s/.*by-label\/[a-z]*\([0-9]\).*/\1/")

drives=""
for ((b=0; b<10; b++))
do
    DEV=/dev/disk/by-label/root${b}
    if [[ -b ${DEV} ]] ; then
:	echo "$DEV found"
	# We can't copy to ourselves
	if [[ ${b} -eq ${ourbootnumber} ]] ; then
:	    echo "Skipping $b, as we are booted from there"
	else
	    drives+=" ${b}"
	fi
    else
:    	echo "$DEV absent"
    fi
done

cat <<EOF
We are booted from ${ourbootnumber}
The list of drives we will clone to is: $drives

EOF


if [[ $(id -u) -ne 0 ]] ; then
    echo "You are $(id -un) you need to su or sudo to root before running this" >&2
    usage $0
    exit 2
fi

typeset -i start prev now duration

start=$(date "+%s")
now=$(date "+%s")

for drive in ${drives}
do
    prev=${now}
    echo "Doing drive ${drive}"
    QNAP_clone_disk -q -b ${drive}
    now=$(date "+%s")
    
    duration=now-prev

    echo "That clone (drive ${drive}) took $duration seconds"
done

now=$(date "+%s")
duration=now-start

echo "Total clone took $duration seconds (started at $(date -d @${start}), ended at $(date -d @${now}))"


