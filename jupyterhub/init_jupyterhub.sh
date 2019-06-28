#!/bin/bash

. "$SPARK_HOME/sbin/spark-config.sh"
. "$SPARK_HOME/bin/load-spark-env.sh"

download_jars()
{
  wget http://central.maven.org/maven2/com/amazonaws/aws-java-sdk-s3/1.11.45/aws-java-sdk-s3-1.11.45.jar -O ${SPARK_HOME}/jars/aws-java-sdk-s3-1.11.45.jar
  wget http://central.maven.org/maven2/com/ibm/stocator/stocator/1.0.25/stocator-1.0.25.jar -O ${SPARK_HOME}/jars/stocator-1.0.25.jar
  wget http://central.maven.org/maven2/com/amazonaws/aws-java-sdk/1.11.45/aws-java-sdk-1.11.45.jar -O ${SPARK_HOME}/jars/aws-java-sdk-1.11.45.jar
  wget http://central.maven.org/maven2/com/amazonaws/aws-java-sdk-core/1.11.415/aws-java-sdk-core-1.11.415.jar -O ${SPARK_HOME}/jars/aws-java-sdk-core-1.11.415.jar
  wget http://central.maven.org/maven2/org/apache/hadoop/hadoop-aws/2.7.7/hadoop-aws-2.7.7.jar -O ${SPARK_HOME}/jars/hadoop-aws-2.7.7.jar
  echo "Jars libs added"
}

download_jars

# arg1 = json file name
# arg2 = if we should pick user or pwd
parse_json(){
	string=''
	for x in `echo $1 | jq -r '.credentials[].'$2`; do 
		string=$string$x';';
	done

	string=${string::-1}
	echo "${string}"
}

JH_USERS=$(parse_json "$JH_CREDS" "user")
JH_PWDS=$(parse_json "$JH_CREDS" "pwd")

create_users()
{
        echo $JH_USERS
        echo $JH_PWDS
        IFS=';' read -ra USERSARR <<< "$JH_USERS"
        echo $JH_PWDS
        IFS=';' read -ra PWDSARR <<< "$JH_PWDS"

        LENU=${#USERSARR[@]}
        LENP=${#PWDSARR[@]}

        echo $LENU
        echo $LENP

        if [ $LENU -ne $LENP ];
        then
                echo 'Different number of users and passwords defined' 
                exit 1
        fi

        for ((i=0;i<=$LENU;i++)); do
                echo "${USERSARR[$i]}" 
                adduser ${USERSARR[$i]}

                echo ${USERSARR[$i]}':'${PWDSARR[$i]} | chpasswd
        done
}

remove_old_dir(){
	IFS=';' read -ra USERSARR <<< "$JH_USERS"
	remove_user=1
	for dir in /home/*/ ; do
		dir=${dir%*/}
		dir=${dir##*/}

		for i in "${USERSARR[@]}"
		do
			if [ "$i" == "$dir" ] ; then
				remove_user=0
			fi
		done
		
		if [ $remove_user -eq 1 ]; then
			echo 'remove directory : '$dir
			rm -rf /home/$dir
		fi
		remove_user=1
	done
}

export SPARK_DRIVER_HOST=`hostname --ip-address`

sed -i -e 's/export SPARK_LOCAL_DIRS=\/opt//g' /spark/conf/spark-env.sh

. "$SPARK_HOME/bin/load-spark-env.sh"

sed -i -e 's/<myip>/'$SPARK_DRIVER_HOST'/g' /spark/conf/spark-defaults.conf

echo "c.Authenticator.admin_users = set(['epmadmin'])" >> /jupyterhub/jupyterhub_config.py

adduser epmadmin

echo 'epmadmin:'$JUPYTER_ADM_PWD | chpasswd

create_users

export JH_USERS=$JH_USERS';epmadmin'

remove_old_dir

export JH_CREDS=dummys
unset JH_USERS
unset JH_PWDS

jupyterhub -f /jupyterhub/jupyterhub_config.py