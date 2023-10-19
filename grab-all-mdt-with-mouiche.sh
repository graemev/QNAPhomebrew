modprobe mtdblock
cat /dev/mtd0 > mtd0
cat /dev/mtd1 > mtd1
cat /dev/mtd2 > mtd2

cat /dev/mtd4 > mtd4
cat /dev/mtd5 > mtd5


. /etc/os-release 
echo $VERSION_CODENAME

KERNEL=$(uname -r)


NAME="F_TS-412-MOUICHE_${VERSION_CODENAME}_${KERNEL}"

#cat mtd0 mtd4 mtd5 mtd1 mtd2 mtd3 > ${NAME}  # This is layout on Original & SABOTEUR

cat mtd0 mtd4 mtd5 mtd1 mtd2       > ${NAME}  # This is layout with MOUICHE

