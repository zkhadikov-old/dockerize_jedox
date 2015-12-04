#!/bin/bash
#
# dockerize jedox suite script
#
# Author: Zurab Khadikov <zurab.khadikov@jedox.com>
# 

# param $1 is Jedox Suite installation path

#
# set params
#
if [ ! -d "$1" ]; then
	export PS=/opt/jedox/ps
	echo "Use default Jedox Suite installation path:"
else
	export PS="$1"
	echo "Use custom Jedox Suite installation path:"
fi

echo "$PS"

#
# check if ps exists
#
if [ ! -d "$PS" ]; then
	echo "Error: Please, first install Jedox Suite ..."
	exit 1
fi

echo
echo "Change to Jedox Suite installation path:"
pushd "$PS"

# TODO: add start scripts and patch olap start script

echo
echo "Import Jedox Suite into docker image jedox/ps whit id:"
tar --numeric-owner --exclude=/proc --exclude=/sys --exclude='*.tar.gz' -cf "$PS/../ps.tar" ./
cat "$PS/../ps.tar" | docker import - jedox/ps

echo
echo "Dockerization finished."