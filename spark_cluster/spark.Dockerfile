FROM openjdk:8

ENV ENABLE_INIT_DAEMON=true
ENV INIT_DAEMON_BASE_URI=http://identifier/init-daemon
ENV INIT_DAEMON_STEP=spark_master_init

# Spark UI Proxy
ENV SPARK_UI_PY=/usr/local/spark-ui-proxy.py
ENV SERVER_PORT=80
ENV BIND_ADDR="0.0.0.0"

# Versions
ENV SPARK_VERSION="2.3.3"
ENV SPARK_HADOOP_VERSION="2.7"
ENV PY4J_VERSION="0.10.7"
ENV HADOOP_VERSION="3.1.1"
ENV SPARK_HOME=/spark
ENV HADOOP_HOME=/hadoop

# Python things
ENV PYTHONHASHSEED=1
ENV PYTHONPATH=${SPARK_HOME}/python/lib/py4j-${PY4J_VERSION}-src.zip:${SPARK_HOME}/python:${SPARK_HOME}/python/build:$PYTHONPATH
ENV PYSPARK_PYTHON=/usr/bin/python3
ENV PYSPARK_DRIVER_PYTHON=/usr/bin/python3

# Remap PATH
ENV PATH=${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${HADOOP_HOME}/bin:$PATH

# Remap LB Library
ENV LD_LIBRARY_PATH=${HADOOP_HOME}/lib/native:$LD_LIBRARY_PATH

# APACHE MIRROR
ARG APACHE_MIRROR=http://apache.mirror.iphh.net

# SPARK MIRROR
ARG SPARK_EXTRACTFOLDER=spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}
ARG SPARK_TARFILE=${SPARK_EXTRACTFOLDER}.tgz
ARG SPARK_DOWNLOAD_MIRROR=${APACHE_MIRROR}/spark/spark-${SPARK_VERSION}/${SPARK_TARFILE}
# HADOOP MIRROR
ARG HADOOP_EXTRACTFOLDER=hadoop-${HADOOP_VERSION}
ARG HADOOP_TARFILE=${HADOOP_EXTRACTFOLDER}.tar.gz
ARG HADOOP_DOWNLOAD_MIRROR=${APACHE_MIRROR}/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_TARFILE}

RUN mkdir -p ${SPARK_HOME}/logs ${HADOOP_HOME}

# Install requirements
RUN apt-get update \
    && apt install -y python3 python3-setuptools python3-pip python-minimal python-pip \
    wget curl unzip zip vim systemd dbus redis-tools git rsync axel

ARG PYTHONDEPS="python-dotenv redis pandas six ibm-db==2.0.9 cloudant==2.10.2 slackweb"
RUN python -m pip install ${PYTHONDEPS} \
    && python3 -m pip install ${PYTHONDEPS}

RUN cd /tmp && axel -n 10 ${SPARK_DOWNLOAD_MIRROR} \
    && tar -xzf ${SPARK_TARFILE} \
    && cp -a ${SPARK_EXTRACTFOLDER}/. ${SPARK_HOME}/ \
    && rm -rf ${SPARK_EXTRACTFOLDER} \
    && rm ${SPARK_TARFILE} \
    && axel -n 10 ${HADOOP_DOWNLOAD_MIRROR} \
    && tar -xzf ${HADOOP_TARFILE} \
    && cp -a ${HADOOP_EXTRACTFOLDER}/. ${HADOOP_HOME}/ \
    && rm -rf ${HADOOP_EXTRACTFOLDER} \
    && rm ${HADOOP_TARFILE} \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
    /usr/share/man \
    /usr/share/doc \
    /usr/share/doc-base

# Copy Spark config files
COPY init.sh /usr/local/bin/init.sh
RUN  chmod +x /usr/local/bin/init.sh
COPY spark-env.sh ${SPARK_HOME}/conf/
COPY spark-defaults.conf ${SPARK_HOME}/conf/spark-defaults.conf

ENTRYPOINT [ "/usr/local/bin/init.sh" ]