#! /bin/bash -ue
# VERSION 1.0
: ${FILE:=/var/opt/homebrew/$(basename $0 .sh)}

DIR=$(dirname ${FILE})

mkdir -p ${DIR}

typeset -i count

if [[ -r ${FILE} ]] ; then
    read count < ${FILE}
else
    count=0
fi
count+=1
echo ${count}  > ${FILE}

exit 0

