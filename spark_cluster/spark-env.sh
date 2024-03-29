# Spark
export SPARK_LOCAL_DIRS=/opt
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

# Master
export SPARK_MASTER="spark://spark-master-jh:7077"
# export SPARK_MASTER="spark://172.17.0.2:7077"
export SPARK_MASTER_HOST=`hostname -s`
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=8080
export SPARK_MASTER_LOG=$SPARK_HOME/logs

# Worker
echo "WORKER ENVS!"
export SPARK_WORKER_HOST=`hostname --ip-address`
export SPARK_WORKER_INSTANCES=1
export SPARK_WORKER_CORES=2
export SPARK_WORKER_MEMORY=4g
export SPARK_WORKER_PORT=4077
export SPARK_WORKER_WEBUI_PORT=8081
export SPARK_WORKER_LOG=$SPARK_HOME/logs
export SPARK_WORKER_LOG_DIR=$SPARK_HOME/logs