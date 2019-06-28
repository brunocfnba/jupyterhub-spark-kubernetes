#!/bin/bash
param=$(echo $1 | tr a-z A-Z)

instance=1

. "$SPARK_HOME/sbin/spark-config.sh"
. "$SPARK_HOME/bin/load-spark-env.sh"

start_nohup() {
  echo -e "$@"
  ln -sf /dev/stdout $log
  nohup -- "$@" >> /tmp/logs.out 2>&1 < /dev/null &
}

download_jars()
{
  wget http://central.maven.org/maven2/com/amazonaws/aws-java-sdk-s3/1.11.45/aws-java-sdk-s3-1.11.45.jar -O ${SPARK_HOME}/jars/aws-java-sdk-s3-1.11.45.jar
  wget http://central.maven.org/maven2/com/ibm/stocator/stocator/1.0.25/stocator-1.0.25.jar -O ${SPARK_HOME}/jars/stocator-1.0.25.jar
  wget http://central.maven.org/maven2/com/amazonaws/aws-java-sdk/1.11.45/aws-java-sdk-1.11.45.jar -O ${SPARK_HOME}/jars/aws-java-sdk-1.11.45.jar
  wget http://central.maven.org/maven2/com/amazonaws/aws-java-sdk-core/1.11.415/aws-java-sdk-core-1.11.415.jar -O ${SPARK_HOME}/jars/aws-java-sdk-core-1.11.415.jar
  wget http://central.maven.org/maven2/org/apache/hadoop/hadoop-aws/2.7.7/hadoop-aws-2.7.7.jar -O ${SPARK_HOME}/jars/hadoop-aws-2.7.7.jar
  echo "Jars libs added"
}

if [[ "$param" =~ "MASTER" ]]; then
  download_jars
  $SPARK_HOME/bin/spark-class org.apache.spark.deploy.master.Master \
    --host $SPARK_MASTER_HOST --port $SPARK_MASTER_PORT --webui-port $SPARK_MASTER_WEBUI_PORT
elif [[ "$param" =~ "WORKER" ]]; then
  download_jars
  for ((i=0; i<$SPARK_WORKER_INSTANCES; i++)); do
    worker_port=$(( $SPARK_WORKER_PORT + $i ))
    webui_port=$(( $SPARK_WORKER_WEBUI_PORT + $i ))
    instance=$(($i + 1))
    start_nohup $SPARK_HOME/bin/spark-class org.apache.spark.deploy.worker.Worker --host $SPARK_WORKER_HOST --webui-port $webui_port --port $worker_port $SPARK_MASTER
  done
  tail -f /dev/null
else
  exec $@
fi