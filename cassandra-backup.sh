#!/bin/bash

DATE=`date +"%Y-%m-%d--%H-%M-%S"`
FOLDER_NAME=${DATE}-daily
S3_BUCKET=s3://cassandra-bi-archive
S3_BUCKET_PATH=cassandra/full/`date +"%Y/%m/%d/%H/%M"`/`cat /etc/hostname`
SNAPSHOTID=`uuidgen --time`

echo "------ NEW RUN ------"
echo "Clearing existing snapshots"
nodetool clearsnapshot

echo "Taking daily db dump for $DATE with id=$SNAPSHOTID"
nodetool snapshot --tag $SNAPSHOTID

TABLES=`ls /mnt/cassandra/data`
for table in $TABLES
do
    echo ""
    echo "sending all $table files one by one..."
    FILES=`find /mnt/cassandra/data/${table}/*/snapshots/$SNAPSHOTID -type f`
    for filename in $FILES
    do
        # Need to deal with files one by one to not have the file usage explode
        # because we are dealing with hardlinks.
        aws s3 cp $filename $S3_BUCKET/$S3_BUCKET_PATH/$table/`basename $filename` 
        echo 'Current file is - '$filename
    done
done

echo "DONE!"
echo ""
