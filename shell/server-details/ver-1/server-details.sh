#!/bin/bash

# Author: Ilche Bedelovski
# Version: 1.1

EMAIL="ilche@ecomwise.com"

# 1 min load avg
MAX_LOAD=1

# max swap in kB
MAX_SWAP_USED=80000

# swap in percentage
SWAP_ALLOWED='85%'

# max memory used in kB
MAX_MEM_USED=1400000

# min memory used in kB
MIN_MEM_USED=100000

# packets per second inbound
MAX_PPS_IN=2000

# packets per second outbound
MAX_PPS_OUT=2000

# mac processes in the process list
MAX_PROCS=300

# interface
IFACE='eth0'

###################################

# i min load avg

ONE_MIN_LOADING=`cut -d . -f 1 /proc/loadavg`
echo "1 minute load avg: $ONE_MIN_LOADING"

# swap used
SWAP_TOTAL=`grep ^SwapTotal: /proc/meminfo | awk '{print $2}'`
SWAP_FREE=`grep ^SwapFree: /proc/meminfo | awk '{print $2}'`

let "SWAP_USED = (SWAP_TOTAL - SWAP_FREE)"
echo "Swap used: $SWAP_USED kB"

# mem used
MEM_TOTAL=`grep ^MemTotal: /proc/meminfo | awk '{print $2}'`
MEM_FREE=`grep ^MemFree: /proc/meminfo | awk '{print $2}'`

let "MEM_USED = (MEM_TOTAL - MEM_FREE)"
echo "Mem used: $MEM_USED kB"

# mem budders/cached
MEM_CACHED_USED=`free -k | grep buffers/cache: | awk '{print $3}'`

let "MEM_CACHED_FREE = (MEM_TOTAL - MEM_CACHED_USED)"
echo "Mem cached free: $MEM_CACHED_FREE kB"

# packets received
PACKETS_RX_1=`grep $IFACE /proc/net/dev | awk '{print $2}'`
sleep 2
PACKETS_RX_2=`grep $IFACE /proc/net/dev | awk '{print $2}'`

let "PACKETS_RX = (PACKETS_RX_2 - PACKETS_RX_1) / 2"
echo "packets received (2 secs): $PACKETS_RX"

# packet sent
PACKETS_TX_1=`grep $IFACE /proc/net/dev | awk '{print $10}'`
sleep 2
PACKETS_TX_2=`grep $IFACE /proc/net/dev | awk '{print $10}'`

let "PACKETS_TX = (PACKETS_TX_2 - PACKETS_TX_1) / 2"
echo "packets sent (2 secs): $PACKETS_TX"

let "SWAP_USED = SWAP_TOTAL - SWAP_FREE"
if [ ! "$SWAP_USED" == 0 ]; then
	PERCENTAGE_SWAP_USED=`echo $SWAP_USED / $SWAP_TOTAL | bc -l`	
	TOTAL_PERCENTAGE=`echo ${PERCENTAGE_SWAP_USED:1:2}%`
else
	TOTAL_PERCENTAGE='0%'
fi

TOTAL_PERCENTAGE_INT=`echo $TOTAL_PERCENTAGE | tr -d '%'`
SWAP_ALLOWED_INT=`echo $SWAP_ALLOWED | tr -d '%'`

# number of processes

MAX_PROC_CHECK=`ps ax | wc -l`
echo "Active processes: $MAX_PROC_CHECK"

send_alert() {
	SUBJECTLINE="`hostname` [Reason: $1] [L: $ONE_MIN_LOADING] [P: $MAX_PROC_CHECK] [M: $MEM_USED kB] [Swap Use: $TOTAL_PERCENTAGE] [pps in: $PACKETS_RX pps out: $PACKETS_TX]"
	#
	if [ -f /bin/mail ]; then
		mail=/bin/mail
		ps auxwwwf | $mail -s "$SUBJECTLINE" $EMAIL
		echo -e "sent from /bin/mail \n"
		exit
	elif [ -f /usr/sbin/sendmail ]; then
		mail=/usr/sbin/sendmail
		echo -e "Subject: $SUBJECTLINE \n`ps auxwwwf`" | $mail -v $EMAIL
		echo -e "sent from /usr/sbin/sendmail\n"
		exit
	else
		echo "please provide another mail sender"
	fi
	exit
}

if   [ $ONE_MIN_LOADING -gt $MAX_LOAD ]; then 
	arg1="High_server_load"
	send_alert $arg1
elif [ $TOTAL_PERCENTAGE_INT -gt $SWAP_ALLOWED_INT ]; then 
	arg1="High_Swap_used"
	send_alert $arg1
#elif [ $MEM_USED -gt $MAX_MEM_USED ]; then 
#	arg1="High_memory_used"
#	send_alert $arg1
elif [ $MEM_CACHED_FREE -lt $MIN_MEM_USED ]; then
	arg1="Physical_memory_full"
        send_alert $arg1
elif [ $PACKETS_RX -gt $MAX_PPS_IN ]; then 
	arg1="Received_packets_number_too_high"
	send_alert $arg1
elif [ $PACKETS_TX -gt $MAX_PPS_OUT ]; then 
	arg1="Transmited_packets_number_too_high"
	send_alert $arg1
elif [ $MAX_PROC_CHECK -gt $MAX_PROCS ]; then 
	arg1="Too_many_active_processes"
	send_alert $arg1
fi

