# FROM spark-jup:latest
FROM cedp-docker-local.artifactory.swg-devops.com/cedp-epm-brazil/spark-jupyter:latest

# Install requirements
RUN apt-get update \
    && apt-get install -y nodejs-legacy scala jq

ARG PYTHONDEPS="tornado==5.1.1 jupyter jupyterhub"
RUN python3 -m pip install ${PYTHONDEPS}

RUN rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
    /usr/share/man \
    /usr/share/doc \
    /usr/share/doc-base

RUN cd / && mkdir jupyterhub && cd jupyterhub

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y npm && \
    npm install -g configurable-http-proxy@3.1.1

RUN cd /usr/local/share/jupyter/kernels/ && mkdir pyspark

COPY init_jupyterhub.sh /usr/local/bin/init_jupyterhub.sh
RUN  chmod +x /usr/local/bin/init_jupyterhub.sh
COPY spark-defaults.conf /spark/conf/spark-defaults.conf
COPY pyspark-kernel.json /usr/local/share/jupyter/kernels/pyspark/kernel.json

RUN cd /jupyterhub && jupyterhub --generate-config
RUN chmod +x /jupyterhub/jupyterhub_config.py

ENTRYPOINT ["/usr/local/bin/init_jupyterhub.sh"]
