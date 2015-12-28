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
cat "$PS/../ps.tar" | docker import --change "ENTRYPOINT while true; do ping 8.8.8.8; done" --change "ENV TERM=xterm" - jedox/ps

popd > /dev/null

echo
echo "Create and start intermediate container with id:"
echo "Current directory= $THIS_DIR"
docker run --name jedox_ps -d -v $THIS_DIR/patches:/opt jedox/ps

echo 
echo "Copy scripts"
docker exec jedox_ps /bin/bash -c "cp /opt/.bashrc /root/.bashrc"
docker exec jedox_ps /bin/bash -c "cp /opt/bin/* /bin/"

echo "patching startup files"
docker exec jedox_ps /bin/bash -c "patch /etc/init.d/jedox_olap < /opt/olap_patch.diff"
docker exec jedox_ps /bin/bash -c "patch /tomcat/jedox_tomcat.sh < /opt/etl_patch.diff"


echo 
echo "Update rpm packages:"
docker exec jedox_ps /bin/bash -c "yum update -y"

echo
echo "Install wget, nano and oracle jre:"
docker exec jedox_ps /bin/bash -c "yum install -y wget nano"
docker exec jedox_ps /bin/bash -c "cd /root && wget --header \"Cookie: oraclelicense=accept-securebackup-cookie\" http://download.oracle.com/otn-pub/java/jdk/8u66-b17/jre-8u66-linux-x64.rpm"
docker exec jedox_ps /bin/bash -c "cd /root && yum install -y jre-8u66-linux-x64.rpm && rm -f jre-8u66-linux-x64.rpm"
docker exec jedox_ps /bin/bash -c "yum clean all"


echo
echo "Stop intermediate container:"
docker stop jedox_ps

echo
echo "Commit changes to final image jedox/aio with id: "
docker commit -c "CMD /bin/entrypoint" -c "EXPOSE 80 7777" jedox_ps jedox/aio

docker rm -f jedox_ps

echo
echo "Dockerization finished. image available under jedox/aio"
