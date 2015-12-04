#!/bin/bash
#
#	/etc/rc.d/init.d/jedox_tomcat
#
#	Jedox-Suite tomcat daemon
#
# chkconfig: - 70 30
# description: The Jedox-Suite server daemons provide \
#              OLAP database, Tomcat and Web functionality.
# pidfile: /tomcat/jedox_tomcat.pid
#
### BEGIN INIT INFO
# Provides:          jedox_tomcat
# Required-Start:    $remote_fs $named $time $syslog udev jedox_olap
# Required-Stop:     $remote_fs $named $time $syslog udev jedox_olap
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Jedox-Suite server daemons
# Description:       The Jedox-Suite server daemons
#	provide OLAP database, Tomcat and Web functionality.
### END INIT INFO

# Copyright (c) 2014 Jedox AG, Freiburg
#
# Author: Christoffer Anselm, Jedox AG, 2012
# Author: Jerome Meinke, Jedox AG, 2013 - 2014
#


# Source Jedox environment additions
. /etc/jedoxenv.sh

# tomcat
JEDOX_TOMCAT_HOME=/tomcat
JEDOX_TOMCAT_USER="$JEDOX_USER"

JEDOX_TOMCAT_START_BIN="$JEDOX_TOMCAT_HOME/bin/startup.sh"
JEDOX_TOMCAT_STOP_BIN="$JEDOX_TOMCAT_HOME/bin/shutdown.sh"
JEDOX_TOMCAT_PID="$JEDOX_TOMCAT_HOME/jedox_tomcat.pid"

JEDOX_TOMCAT_ENV="CATALINA_PID=\"$JEDOX_TOMCAT_PID\""
JEDOX_TOMCAT_START_ARG=
JEDOX_TOMCAT_STOP_ARG="90 -force"

JEDOX_TOMCAT_NAME="Jedox ETL $JEDOX_VERSION tomcat"

print_usage() {
	echo "Usage: $0 {start|stop|restart|force-reload}"
	echo "       $0 --help"
}

get_pid_after_start() {
	# wait 10 sec to be sure the pid file is created
	sleep 10
	pid_is_running $1
}

pid_is_running() {
	ps -eo pid | egrep "^\s*$1$" 2>&1
}

start() {
	echo "Starting $JEDOX_TOMCAT_NAME service (tomcat)..."

	if [ "${JEDOX_TOMCAT_USER}" ]; then
		eval $JEDOX_TOMCAT_ENV "su -s /bin/bash -m $JEDOX_TOMCAT_USER -c \"$JEDOX_TOMCAT_START_BIN $JEDOX_TOMCAT_START_ARG\""
	else
		eval $JEDOX_TOMCAT_ENV $JEDOX_TOMCAT_START_BIN $JEDOX_TOMCAT_START_ARG
	fi

	if [ -e "$JEDOX_TOMCAT_PID" ] && [ "$(get_pid_after_start $(cat "$JEDOX_TOMCAT_PID") )" ]; then
		echo "Starting $JEDOX_TOMCAT_NAME service (tomcat)...done"
		return 0
	else
		echo "Starting $JEDOX_TOMCAT_NAME service (tomcat)...failed!"
		return 1
	fi
}	

stop() {
	echo -n "Stopping $JEDOX_TOMCAT_NAME service (tomcat)..."

	if [ -e "$JEDOX_TOMCAT_PID" ]; then
		if [ "$(pid_is_running $(cat "$JEDOX_TOMCAT_PID") )" ]; then
			if [ "${JEDOX_TOMCAT_USER}" ]; then
				eval $JEDOX_TOMCAT_ENV "su -s /bin/bash -m $JEDOX_TOMCAT_USER -c \"$JEDOX_TOMCAT_STOP_BIN $JEDOX_TOMCAT_STOP_ARG\""
			else
				eval $JEDOX_TOMCAT_ENV $JEDOX_TOMCAT_STOP_BIN $JEDOX_TOMCAT_STOP_ARG
			fi

			if [ -e "$JEDOX_TOMCAT_PID" ] && [ "$(pid_is_running $(cat "$JEDOX_TOMCAT_PID") )" ]; then
				echo "Stopping $JEDOX_TOMCAT_NAME service (tomcat)...failed"
				return 1
			else
				echo "Stopping $JEDOX_TOMCAT_NAME service (tomcat)...done"
				return 0
			fi
		else
			echo "Found pid-file but no running service - nothing to shut down."
		fi

		rm "$JEDOX_TOMCAT_PID"

		return 0
	fi

	echo "failed"
	return 1
}

print_status() {
	if [ -e "$JEDOX_TOMCAT_PID" ]; then
		if [ "$(pid_is_running $(cat "$JEDOX_TOMCAT_PID") )" ]; then
			echo "tomcat (pid  $(cat "$JEDOX_TOMCAT_PID")) is running..."
			return 0
		else
			echo "tomcat is stopped (but pid-file exists)"
			return 1
		fi
	fi
	echo "tomcat is stopped"
	return 3
}

COMMAND=

# parse arguments
for arg; do
	case "$arg" in
		start|stop|restart|status)
			if [ "$COMMAND" ]; then
				echo "Error: Multiple actions defined on commandline!"
				exit 1
			fi
				
			COMMAND=$arg
			;;

		--help)
			print_usage
			exit 0
			;;

		*)
			echo "Error: Unrecognized argument: \"$arg\"!"
			#echo "Please see \"$0 --help\" for usage."
			print_usage
			exit 1
			;;
	esac
done

pushd / > /dev/null
# parse command
case "$COMMAND" in
	start)
		start
		;;

	stop)
		stop
		;;

	status)
		print_status
		;;

	restart|force-reload)
		stop
		start
		;;

	"")
		print_usage
		exit 1
		;;
esac
popd > /dev/null

exit $?

