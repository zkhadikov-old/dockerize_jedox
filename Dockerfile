# Jedox PS image dockerfile
FROM scratch
MAINTAINER Zurab Khadikov, "zurab.khadikov@jedox.com"
ADD ps.tar.xz /

EXPOSE 80 7777
ENTRYPOINT entrypoint
