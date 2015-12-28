FROM jedox/ps

#RUN echo "Update rpm packages:"
#RUN yum update -y

#INSTALL Java and other utils
ENV JAVA_VERSION 8u66
ENV BUILD_VERSION b17
RUN echo "Install wget, nano and oracle jre: $JAVA_VERSION - $BUILD_VERSION"

RUN yum install -y wget nano
RUN wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/$JAVA_VERSION-$BUILD_VERSION/jdk-$JAVA_VERSION-linux-x64.rpm" -O /tmp/jdk-8-linux-x64.rpm
RUN yum -y install /tmp/jdk-8-linux-x64.rpm
RUN rm -f /tmp/jdk-8-linux-x64.rpm
RUN yum clean all
RUN alternatives --install /usr/bin/java jar /usr/java/latest/bin/java 200000
RUN alternatives --install /usr/bin/javaws javaws /usr/java/latest/bin/javaws 200000
RUN alternatives --install /usr/bin/javac javac /usr/java/latest/bin/javac 200000

ENV JAVA_HOME /usr/java/latest
#popd > /dev/null


RUN echo "patching startup files"
ADD patches/* /opt/
RUN patch /etc/init.d/jedox_olap < /opt/olap_patch.diff
RUN patch /tomcat/jedox_tomcat.sh < /opt/etl_patch.diff
#RUN rm -fr /opt/*

RUN echo "Copy scripts"
ADD patches/bin/* /bin/

ENV TERM=xterm

ENTRYPOINT /bin/entrypoint
EXPOSE 80 7777