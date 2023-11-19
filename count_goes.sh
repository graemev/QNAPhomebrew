#! /bin/bash -ue
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

