#!/bin/bash
#
# dockerize jedox suite script
#
# Author: Zurab Khadikov <zurab.khadikov@jedox.com>
#
# param $1 is Jedox Suite installation path
 
# set vars
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CPUS="$( cat /proc/cpuinfo | grep processor | wc -l)"

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

#
# Change to Jedox Suite installation path
#
pushd "$PS" > /dev/null

echo
echo "Import Jedox Suite into intermediate docker image jedox/ps with id:"
tar --numeric-owner --exclude=/proc --exclude=/sys --exclude='*.tar.gz' --exclude='*.log' -cf "$PS/../ps.tar" ./
cat "$PS/../ps.tar" | docker import --change "CMD while true; do ping 8.8.8.8; done" --change "ENV TERM=xterm" - jedox/ps

popd > /dev/null

docker build -t jedox/aio .
#docker rm -f jedox_ps

echo
echo "Dockerization finished. image available under jedox/aio"
