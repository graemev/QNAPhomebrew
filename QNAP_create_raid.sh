#! /bin/bash -ue

# 10Oct23 Inital Version

echo "This was abandoned mid way, looks like Media vault has facility builtin


VERSION="0.1"

on_exit() {
    : echo 'ON_EXIT: Cleaning up...(remove tmp files, etc)'
#    rm -f ${TMP1}
}

trap 'on_exit' EXIT




usage() {
    cat <<EOF

USAGE: 
       $0 [-v|--verbose] [-V|--version] [-h|--help] [<name> [<n>] 

       Configure the drive with labels <name>1, <name>2, <name>3, <name>4 

       -v | --verbose       More messages (also passed ot mkfs)
       -V | --version       print version no and exit

       name defaults to "data"
       n defults to 4

       This script was created on a TS412, with 4 drives installed in trays + 1 eSATA SSD

       Tray1=/dev/sda , Tray2=/dev/sdb , Tray3=/dev/sdc , Tray4=/dev/sdd , eSATA/USB ...sde, sdf etc

       If you have only 3 bays populated, the eSATA (Uor USB) would become sdd (not sde)


       If you've followed the convention of "homebrew"  trays 1-4 will have a partition
       with the label data0...data4. It will have a filesystem on it, bit this 
       script will blow it away. 

       If you only have 3 drives , set n to 3 n=5 would allow you to use eSATA
       (or USB) drives.

EOF

}


typeset -i verbose
typeset -i verbose
typeset -i quiet

version=0
verbose=0
quiet=0

PROG=$0
ARGS=`getopt -o "hvV" -l "help,verbose,version" -n "${PROG}" -- "$@"`

n=4
name="data"

typeset -i count
typeset -i i


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
	-v|--verbose) 
	    verbose+=1
	    shift;;
	-V|--version) 
	    version+=1
	    shift;;
	-q|--quiet) 
	    quiet+=1
	    shift;;
	-h|--help) 
	    usage ${PROG}
	    shift;;
	--)
	    shift
	    break;;
    esac
done

if [[ $# -gt 0 ]] ; then
    name=$1 ; shift
fi

if [[ $# -gt 0 ]] ; then
    n=$1 ; shift
fi

if [[ $# -gt 0 ]] ; then
    usage ${PROG}
    exit 1
fi

if [[ ${version} -gt 0 ]] ; then
    echo "${PROG} VERSION=${VERSION}" >&2
    exit 0
fi

if [[ ${verbose} -gt 0 ]] ; then
    echo "Verbose mode enabled VERSION=${VERSION}" >&2
fi

case "${n}" in
    3|4|5|6)
	count=${n}
	;;
    *)
	echo "This will be raid 5 , need 3-6 drives"
	exit 2
	;;
esac

# Check we have the drives we need.

volumes=""

for ((i=1; i<=n; i+=1))
do
    volume="/dev/disk/by-label/${name}${i}"
    if [[ -b ${volume} ]] ; then
	volumes+="${volume} "
    else
	echo "Device ${volume} does not exist" >&2
	failed="yes"
    fi
done

if [[ -n ${failed} ]] ; then
    echo "Aborting due to missing devices" >&2
fi




echo "mdadm --verbose --create /dev/md0 --level=5 --raid-devices=${n} ${volumes} "

echo "mkfs -text5 /dev/md0"


