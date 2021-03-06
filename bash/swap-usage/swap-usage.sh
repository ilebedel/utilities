#!/bin/bash

# Composer: Ilche Bedelovski
# Version: 1.0
# Last update: 04-11-2016

# A script for checking swap usage

SUM=0
OVERALL=0

for DIR in `find /proc/ -maxdepth 1 -type d | egrep "^/proc/[0-9]"`; do
	PID=`echo $DIR | cut -d / -f 3`
	PROGNAME=`ps -d $PID -o comm --no-headers`
	for SWAP in `grep SWAP $DIR/smaps 2>/dev/null | awk '{ print $2 }'`; do
		let SUM=$SUM+$SWAP	
	done
	echo "PID=$PID - Swap used: $SUM - ($PROGNAME)"
	let OVERALL=$OVERALL+$SUM
	SUM=0
done

echo "Overall swap used: $OVERALL"
