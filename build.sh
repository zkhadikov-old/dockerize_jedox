#!/bin/bash
#
# dockerize jedox suite script
#
# Author: Zurab Khadikov <zurab.khadikov@jedox.com>
#
# param $1 is Jedox Suite installation path
 
# set vars
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

echo
echo "Import Jedox Suite into docker image jedox/ps whit id:"
tar --numeric-owner --exclude=/proc --exclude=/sys --exclude='*.tar.gz' --exclude='*.log' -cf "$PS/../ps.tar" ./
cat "$PS/../ps.tar" | docker import --change "ENTRYPOINT while true; do ping 8.8.8.8; done" - jedox/ps

echo
echo "Change back:"
popd

echo
echo "Create and start container:"
docker run --name jedox_ps -d -v $THIS_DIR/patches:/opt jedox/ps 2> /dev/null

echo 
echo "Copy scripts and patches"
docker exec jedox_ps /bin/bash -c "cp /opt/.bashrc /root/.bashrc"
docker exec jedox_ps /bin/bash -c "cp -f /opt/jedox_olap /etc/init.d/jedox_olap"
docker exec jedox_ps /bin/bash -c "cp -f /opt/jedox_tomcat.sh /tomcat/jedox_tomcat.sh"
docker exec jedox_ps /bin/bash -c "cp /opt/bin/* /bin/"

echo 
echo "Update rpm packages:"
docker exec jedox_ps /bin/bash -c "yum update -y"

echo
echo "Install wget and oracle jre:"
docker exec jedox_ps /bin/bash -c "yum install -y wget"
docker exec jedox_ps /bin/bash -c "cd /root && wget --header \"Cookie: oraclelicense=accept-securebackup-cookie\" http://download.oracle.com/otn-pub/java/jdk/8u66-b17/jre-8u66-linux-x64.rpm"
docker exec jedox_ps /bin/bash -c "cd /root && yum install -y jre-8u66-linux-x64.rpm && rm -f jre-8u66-linux-x64.rpm"

echo
echo "Clean all:"
docker exec jedox_ps /bin/bash -c "yum clean all"

echo
echo "Stop container:"
docker stop jedox_ps

#echo 
#echo "Build Jedox Suite jedox/aio image with Dockerfile:"
#docker build --tag="jedox/aio" .

echo
echo "Dockerization finished."
