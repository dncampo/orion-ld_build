# This Dockerfile sets up an Ubuntu 18.04.3 image with necessary dependencies for building and running the Orion-LD
# application. It installs build-essential, scons, curl, python-pip, libssl1.0-dev, libcurl4-gnutls-dev, libsasl2-dev,
# libgnutls28-dev, libgcrypt-dev, uuid-dev, libboost-dev, libboost-regex-dev, and libboost-thread-dev. It also creates a
# new user named "builder" and sets the default command to "/bin/bash".

FROM ubuntu:18.04


RUN apt-get update
RUN apt-get install -y aptitude sudo wget vim
RUN aptitude install -y build-essential scons curl python-pip \
    libssl1.0-dev libcurl4-gnutls-dev libsasl2-dev libgnutls28-dev \
    libgcrypt-dev uuid-dev libboost-dev libboost-regex-dev libboost-thread-dev \
    libboost-filesystem-dev git 

## Add a new group number 1100
#RUN groupadd -g 1100 builder

# Add a new user named "builder" and create a home directory for it 
RUN useradd -u 1101 -m -s /bin/bash builder
RUN echo "builder:builder" | chpasswd

#RUN apt-get install -y sudo wget

# install cmake
RUN mkdir -p /opt/cmake
WORKDIR /opt/cmake
RUN wget https://cmake.org/files/v3.14/cmake-3.14.5.tar.gz && tar -xvzf cmake-3.14.5.tar.gz
WORKDIR /opt/cmake/cmake-3.14.5
RUN ./bootstrap --prefix=/usr/local && make && make install
RUN chown -R builder:builder /opt/cmake

#install Mongo C++ Driver
RUN mkdir -p /opt/mongoclient
WORKDIR /opt/mongoclient
RUN wget https://github.com/mongodb/mongo-cxx-driver/archive/legacy-1.1.2.tar.gz && tar xfvz legacy-1.1.2.tar.gz
WORKDIR mongo-cxx-driver-legacy-1.1.2
RUN scons --disable-warnings-as-errors --ssl --use-sasl-client
RUN scons install --prefix=/usr/local --disable-warnings-as-errors --ssl --use-sasl-client
RUN chown -R builder:builder /opt/mongoclient


#install Mongo C Driver
RUN mkdir -p /opt/mongoc
WORKDIR /opt/mongoc
RUN wget https://github.com/mongodb/mongo-c-driver/releases/download/1.22.0/mongo-c-driver-1.22.0.tar.gz && tar -xvzf mongo-c-driver-1.22.0.tar.gz
WORKDIR mongo-c-driver-1.22.0
RUN mkdir cmake-build
WORKDIR cmake-build
RUN cmake -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF ..
RUN cmake --build .
RUN cmake --build . --target install
RUN chown -R builder:builder /opt/mongoc

#install libmicrohttpd
RUN mkdir -p /opt/libmicrohttpd
WORKDIR /opt/libmicrohttpd
RUN wget https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-0.9.75.tar.gz && tar -xvzf libmicrohttpd-0.9.75.tar.gz
WORKDIR libmicrohttpd-0.9.75
RUN ./configure --disable-messages --disable-postprocessor --disable-dauth
RUN make && make install
RUN chown builder:builder /opt/libmicrohttpd

#install rapidjson
RUN mkdir -p /opt/rapidjson
WORKDIR /opt/rapidjson
RUN wget https://github.com/miloyip/rapidjson/archive/v1.0.2.tar.gz && tar xfvz v1.0.2.tar.gz
RUN mv rapidjson-1.0.2/include/rapidjson/ /usr/local/include
RUN chown -R builder:builder /opt/rapidjson


#work as a regular user
USER builder:builder
RUN mkdir -p /home/builder/git 


#install kbase
WORKDIR "/home/builder/git"
RUN git clone https://gitlab.com/kzangeli/kbase.git && cd kbase && git checkout "release/0.8"  && make install

#install klog
WORKDIR "/home/builder/git"
RUN git clone https://gitlab.com/kzangeli/klog.git && cd "/home/builder/git/klog" && git checkout 'release/0.8' && make install

#install kalloc
WORKDIR "/home/builder/git"
RUN git clone https://gitlab.com/kzangeli/kalloc.git && cd kalloc && git checkout "release/0.8" && make install

#install kjson
WORKDIR "/home/builder/git"
RUN git clone https://gitlab.com/kzangeli/kjson.git && cd kjson && git checkout "release/0.8.2" && make install

#install khash
WORKDIR "/home/builder/git"
RUN git clone https://gitlab.com/kzangeli/khash.git && cd khash && git checkout "release/0.8" && make install

#install Eclipse Paho MQTT
USER root:root
RUN aptitude install -y doxygen graphviz
RUN apt-get install -y libpq-dev

USER builder:builder
RUN rm -f /usr/local/lib/libpaho*
WORKDIR "/home/builder/git"
RUN git clone https://github.com/eclipse/paho.mqtt.c.git
WORKDIR paho.mqtt.c
RUN git checkout tags/v1.3.1 && make html && make
USER root:root
RUN make install

### Python paho-mqtt library
USER builder:builder
RUN pip install paho-mqtt

# Prometheus C Client Library
WORKDIR "/home/builder/git"
RUN git clone https://github.com/digitalocean/prometheus-client-c.git && cd prometheus-client-c && git checkout release-0.1.3 && \
    sed 's/\&promhttp_handler,/(MHD_AccessHandlerCallback) \&promhttp_handler,/' promhttp/src/promhttp.c > XXX && \
    mv XXX promhttp/src/promhttp.c && \
    ./auto build



## Last and not from container
## Compile Orion-LD source code
#WORKDIR "/home/builder/git"
#RUN git clone https://github.com/FIWARE/context.Orion-LD.git
#RUN cd context.Orion-LD
#USER root:root
#WORKDIR "/home/builder/git/context.Orion-LD"
#RUN touch /usr/bin/orionld && chown builder:builder /usr/bin/orionld
#RUN touch /etc/init.d/orionld && chown builder:builder /etc/init.d/orionld
#RUN touch /etc/default/orionld && chown builder:builder /etc/default/orionld
#USER builder:builder
#RUN cd "/home/builder/git/context.Orion-LD" && make install

# install Mosquito
USER root:root
RUN aptitude install -y mosquitto #systemd
RUN aptitude install -y lsb-core
#RUN systemctl enable mosquitto
#RUN systemctl start mosquitto
RUN service mosquitto start


#install Postgres 12
ARG DEBIAN_FRONTEND=noninteractive
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && \
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

RUN apt update
RUN apt -y install postgresql-12 postgresql-client-12 postgis postgresql-12-postgis-3 postgresql-12-postgis-3-scripts

##Add timescale db and postgis
RUN aptitude install -y software-properties-common
RUN add-apt-repository ppa:timescale/timescaledb-ppa
RUN apt-get update && apt install -y timescaledb-postgresql-12
#RUN systemctl enable postgresql

#Edit postgresql.conf, enabling timescaledb
RUN echo "shared_preload_libraries = 'timescaledb'" | tee -a /etc/postgresql/12/main/postgresql.conf
##RUN /etc/init.d/postgresql restart
#RUN service postgresql enable
RUN service postgresql start

#Create the Posgress user for Orion-LD

USER root:root
RUN mkdir -p /home/builder/git/context.Orion-LD && chown -R builder:builder /home/builder/git/context.Orion-LD
WORKDIR "/home/builder/git/context.Orion-LD"

RUN echo "hello"

