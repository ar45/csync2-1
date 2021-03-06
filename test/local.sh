#!/bin/bash

if [ "$1" == "" ] ; then 
    COMMAND=c
else
    COMMAND=$1
fi

NAME=`basename $0 .sh`

if [ "$NAME" == "local" ] ;  then
    PEER="peer"
else
    PEER="local"
fi

: ${PROG:=../csync2}

: ${DEBUG:=v}

: ${PORT:=30860}
: ${SERVER_PORT:=$PORT}

RECURSIVE=r
echo ${PORT} ${SERVER_PORT}

COUNT=0
echo "Running command $COMMAND" 
RES=0

function testing {
    RESULT=$1
    OLD_RESULT=${RESULT}.res
    if [ -f ${OLD_RESULT} ] ; then
	diff -w $RESULT $OLD_RESULT > ${RESULT}.diff
	rc=$?
	RES=$((RES+rc))
	cat ${RESULT}.diff
	if [ ! -s ${RESULT}.diff ] ; then 
	    rm ${RESULT}.diff
	fi
    else
	cp $RESULT $OLD_RESULT
	rm -f ${RESULT}.diff
    fi
}

function cmd {
    CMD=$1
    : ${TESTPATH:=test}
    if [ "$CMD" == "T" ] || [ "$CMD" == "TT" ] ; then
	TESTPATH=$2
	echo "T[T] $CMD ${TESTPATH} "
	shift
    fi
    DESC=$2
    echo "${COUNT}. CMD $CMD $DESC"
    if [ "$3" == "" ] ; then
	HOST=$NAME
	# TODO Fix peername somehow
    fi
    if [ "$CMD" == "daemon" ] ; then
	daemon d
	return 
    fi
    if [ "$CMD" == "killdaemon" ] && [ "$DAEMON" != "NO" ] ; then
	killdaemon
	return 
    fi
    echo cmd $CMD \"$2\" $HOST > ${TESTNAME}/${COUNT}.log 
    if [ "$LLDB" != "" ] ; then 
	$LLDB -f $PROG -- -q -P peer -p ${PORT} -K csync2_$HOST.cfg -N $HOST -${CMD}${RECURSIVE}$DEBUG "${TESTPATH}"
    elif [ "$GDB" != "" ] ; then 
	$GDB $PROG -q -P peer -p ${PORT} -K csync2_$HOST.cfg -N $HOST -${CMD}${RECURSIVE}$DEBUG "${TESTPATH}"
    else
	$PROG -q -P peer -p ${PORT} -K csync2_$HOST.cfg -N $HOST -${CMD}${RECURSIVE}$DEBUG "${TESTPATH}" >> ${TESTNAME}/${COUNT}.log 2>&1
    fi
    testing ${TESTNAME}/${COUNT}.log
    echo "select filename from file order by filename; select peername,filename,operation,other,op from dirty order by op, filename, peername;" | mysql -t -u csync2_$HOST -pcsync2_$HOST csync2_$HOST > ${TESTNAME}/${COUNT}.mysql 2> /dev/null
#    echo "select filename from file; select peername,filename,operation,other from dirty order by peername, timestamp;" | mysql -t -u csync2_$HOST -pcsync2_$HOST csync2_$HOST > ${TESTNAME}/${COUNT}.mysql 2> /dev/null
    testing ${TESTNAME}/${COUNT}.mysql
    if [ -d "test/local" ] && [ "$CMD" != "c" ] ; then 
	rsync --delete -nHav test/local/ peer:`pwd`/test/peer/ |grep -v "building file list ... done" | grep -v "bytes/sec" |grep -v "(DRY RUN)" |grep -v "sending incremental" > ${TESTNAME}/${COUNT}.rsync
	testing ${TESTNAME}/${COUNT}.rsync
    fi
    echo "${COUNT}. END $CMD ${DESC}" 
    let COUNT=$COUNT+1
    ${PAUSE}
}

function clean {
    CNAME=$1
    echo "${COUNT}. clean ${CNAME}" 
    if [ "$1" == "" ] ; then
	CNAME=local
    fi
    echo "delete from dirty ; delete from file" | mysql -u csync2_$CNAME -pcsync2_$CNAME csync2_$CNAME > ${TESTNAME}/${COUNT}.mysql 2> /dev/null
    rm -f csync_$CNAME.log mysql_$CNAME.log
    rm -rf test/$CNAME
    let COUNT=$COUNT+1
    ${PAUSE}
}

function daemon {
    if [ "$DAEMON" == "NO" ] ; then
	echo "daemon start disabled";
	return 
    fi
    # Create backupdir
    mkdir -p /tmp/csync2 
    CMD="$1"
    echo $NAME $PEER
    if [ "$CMD" == "d" ] ; then 
	${PROG} -q -K csync2_$PEER.cfg -N $PEER -z $NAME -iiii$DEBUG -p ${SERVER_PORT} > $TESTNAME/daemon.log  2>&1 &
	echo "$!" > daemon.pid
    elif [ "$CMD" == "i" ] ; then 
	if [ "LLDB" != "" ]; then
	    $LLDB -f ${PROG} -- -q -K csync2_$NAME.cfg -N $NAME -z $PEER -iiii$DEBUG -p ${SERVER_PORT}
	else
	    $GDB ${PROG} -q -K csync2_$NAME.cfg -N $NAME -z $PEER -iiii$DEBUG -p ${SERVER_PORT}
	fi
#	echo "$!" > daemon.pid
	sleep 1
    elif [ "$CMD" == "once" ] ; then 
	${PROG} -q -K csync2_$NAME.cfg -N $NAME -z $PEER -iii$DEBUG -p ${SERVER_PORT} >> daemon_${NAME}.log 2>&1 & 
    elif [ "$CMD" == "clean_once" ] ; then 
	clean peer
	${PROG} -q -K csync2_$NAME.cfg -N $NAME -z $PEER -iii$DEBUG -p ${SERVER_PORT} & 
    fi    
}

function killdaemon {
    if [ "$DAEMON" == "NO" ] ; then
	echo "daemon stop disabled";
	return 
    fi
    kill `cat daemon.pid`
    rm daemon.pid
}

function check {
    cmd c $1 $2
}

if [ ! -f csync2_${NAME}.cfg ] ; then
    echo "Missing config file:  csync2_${NAME}.cfg"
    exit 1;
fi 

TESTNAME=.
for d in $* ; do 
    if [ -f "$d" ] ; then 
	echo "Running test script $d"
	TESTNAME=`basename $d .test`
	mkdir -p ${TESTNAME}
	source $d
    else
	if [ "$COMMAND" == "C" ] ; then 
	    echo "cmd C: Do not work!" 
	    #clean $NAME
	    shift
	    COMMAND="$1"
	fi
	if [ "$COMMAND" == "i" ] ; then 
	    daemon i
	    shift
	    TESTNAME=$1
	    shift
	fi 
    fi
done
echo "Result $RES"
exit $RES
