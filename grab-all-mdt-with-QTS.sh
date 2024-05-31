# VERSION 1.0
gmodprobe mtdblock
cat /dev/mtdblock0 > mtd0
cat /dev/mtdblock1 > mtd1
cat /dev/mtdblock2 > mtd2
cat /dev/mtdblock3 > mtd3
cat /dev/mtdblock4 > mtd4
cat /dev/mtdblock5 > mtd5


. /etc/os-release 
echo $VERSION_CODENAME

KERNEL=$(uname -r)


NAME="F_TS-412-QTS_${VERSION_CODENAME}_${KERNEL}"

cat mtd0 mtd4 mtd5 mtd1 mtd2 mtd3 > ${NAME}

