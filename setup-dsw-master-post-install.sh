#!/bin/bash

installUtils () {
	echo "*********************************Installing WGET..."
	yum install -y wget
	
	echo "*********************************Installing GIT..."
	yum install -y git
	
	echo "*********************************Installing PIP..."
	yum install -y pip
	pip install numpy
	pip install pandas
	
	
	sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	sudo yum install R R-devel libcurl-devel openssl-devel
	sudo R -e “install.packages(‘devtools’, repos = ‘http://cran.us.r-project.org’)”
	sudo R -e “install.packages(‘knitr’, repos = ‘http://cran.us.r-project.org’)”
	sudo R -e “install.packages(‘ggplot2’, repos = ‘http://cran.us.r-project.org’)”
	sudo R -e “install.packages(c(‘devtools’,‘mplot’, ‘googleVis’), repos = ‘http://cran.us.r-project.org’); require(devtools); install_github(‘ramnathv/rCharts’)”
	sudo R -e “install.packages(‘glmnet’, repos = ‘http://cran.us.r-project.org’)”
	sudo R -e “install.packages(‘pROC’, repos = ‘http://cran.us.r-project.org’)”
	sudo R -e “install.packages(‘data.table’, repos = ‘http://cran.us.r-project.org’)”
	sudo R -e “install.packages(‘caret’, repos = ‘http://cran.us.r-project.org’)”
	sudo R -e “install.packages(‘sqldf’, repos = ‘http://cran.us.r-project.org’)”
	sudo R -e “install.packages(‘wordcloud’, repos = ‘http://cran.us.r-project.org’)”
	sudo R -e “install.packages(‘roxygen2’, repos = ‘http://cran.us.r-project.org’)”
	sudo R -e “install.packages(‘sparklyr’, repos = ‘http://cran.us.r-project.org’)”
	sudo R -e “install.packages(‘pipeR’, repos = ‘http://cran.us.r-project.org’)”
	sudo R -e “install.packages(c(‘devtools’), repos = ‘http://cran.us.r-project.org’); require(devtools); install_github(‘IRkernel/repr’)”
	sudo R -e “install.packages(‘htmltools’, repos = ‘http://cran.us.r-project.org’)”
	sudo R -e “install.packages(‘base64enc’, repos = ‘http://cran.us.r-project.org’)”
	sudo R -e “install.packages(‘dplyr’, repos = ‘http://cran.us.r-project.org’)”
	sudo R -e “install.packages(‘repr’, repos = ‘http://cran.us.r-project.org’)”
	
}

waitForAmbari () {
       	# Wait for Ambari
       	LOOPESCAPE="false"
       	until [ "$LOOPESCAPE" == true ]; do
        TASKSTATUS=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -I -X GET http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME | grep -Po 'OK')
        if [ "$TASKSTATUS" == OK ]; then
                LOOPESCAPE="true"
                TASKSTATUS="READY"
        else
               	AUTHSTATUS=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -I -X GET http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME | grep HTTP | grep -Po '( [0-9]+)'| grep -Po '([0-9]+)')
               	if [ "$AUTHSTATUS" == 403 ]; then
               	echo "THE AMBARI PASSWORD IS NOT SET TO: admin"
               	echo "RUN COMMAND: ambari-admin-password-reset, SET PASSWORD: admin"
               	exit 403
               	else
                TASKSTATUS="PENDING"
               	fi
       	fi
       	echo "Waiting for Ambari..."
        echo "Ambari Status... " $TASKSTATUS
        sleep 2
       	done
}

serviceExists () {
       	SERVICE=$1
       	SERVICE_STATUS=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -X GET http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services/$SERVICE | grep '"status" : ' | grep -Po '([0-9]+)')

       	if [ "$SERVICE_STATUS" == 404 ]; then
       		echo 0
       	else
       		echo 1
       	fi
}

getServiceStatus () {
       	SERVICE=$1
       	SERVICE_STATUS=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -X GET http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services/$SERVICE | grep '"state" :' | grep -Po '([A-Z]+)')

       	echo $SERVICE_STATUS
}

waitForService () {
       	# Ensure that Service is not in a transitional state
       	SERVICE=$1
       	SERVICE_STATUS=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -X GET http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services/$SERVICE | grep '"state" :' | grep -Po '([A-Z]+)')
       	sleep 2
       	echo "$SERVICE STATUS: $SERVICE_STATUS"
       	LOOPESCAPE="false"
       	if ! [[ "$SERVICE_STATUS" == STARTED || "$SERVICE_STATUS" == INSTALLED ]]; then
        until [ "$LOOPESCAPE" == true ]; do
                SERVICE_STATUS=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -X GET http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services/$SERVICE | grep '"state" :' | grep -Po '([A-Z]+)')
            if [[ "$SERVICE_STATUS" == STARTED || "$SERVICE_STATUS" == INSTALLED ]]; then
                LOOPESCAPE="true"
            fi
            echo "*********************************$SERVICE Status: $SERVICE_STATUS"
            sleep 2
        done
       	fi
}

waitForServiceToStart () {
       	# Ensure that Service is not in a transitional state
       	SERVICE=$1
       	SERVICE_STATUS=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -X GET http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services/$SERVICE | grep '"state" :' | grep -Po '([A-Z]+)')
       	sleep 2
       	echo "$SERVICE STATUS: $SERVICE_STATUS"
       	LOOPESCAPE="false"
       	if ! [[ "$SERVICE_STATUS" == STARTED ]]; then
        	until [ "$LOOPESCAPE" == true ]; do
                SERVICE_STATUS=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -X GET http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services/$SERVICE | grep '"state" :' | grep -Po '([A-Z]+)')
            if [[ "$SERVICE_STATUS" == STARTED ]]; then
                LOOPESCAPE="true"
            fi
            echo "*********************************$SERVICE Status: $SERVICE_STATUS"
            sleep 2
        done
       	fi
}

stopService () {
       	SERVICE=$1
       	SERVICE_STATUS=$(getServiceStatus $SERVICE)
       	echo "*********************************Stopping Service $SERVICE ..."
       	if [ "$SERVICE_STATUS" == STARTED ]; then
        TASKID=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -H "X-Requested-By:ambari" -i -X PUT -d "{\"RequestInfo\": {\"context\": \"Stop $SERVICE\"}, \"ServiceInfo\": {\"maintenance_state\" : \"OFF\", \"state\": \"INSTALLED\"}}" http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services/$SERVICE | grep "id" | grep -Po '([0-9]+)')

        echo "*********************************Stop $SERVICE TaskID $TASKID"
        sleep 2
        LOOPESCAPE="false"
        until [ "$LOOPESCAPE" == true ]; do
            TASKSTATUS=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -X GET http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/requests/$TASKID | grep "request_status" | grep -Po '([A-Z]+)')
            if [ "$TASKSTATUS" == COMPLETED ]; then
                LOOPESCAPE="true"
            fi
            echo "*********************************Stop $SERVICE Task Status $TASKSTATUS"
            sleep 2
        done
        echo "*********************************$SERVICE Service Stopped..."
       	elif [ "$SERVICE_STATUS" == INSTALLED ]; then
       	echo "*********************************$SERVICE Service Stopped..."
       	fi
}

startService (){
       	SERVICE=$1
       	SERVICE_STATUS=$(getServiceStatus $SERVICE)
       	echo "*********************************Starting Service $SERVICE ..."
       	if [ "$SERVICE_STATUS" == INSTALLED ]; then
        TASKID=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -H "X-Requested-By:ambari" -i -X PUT -d "{\"RequestInfo\": {\"context\": \"Start $SERVICE\"}, \"ServiceInfo\": {\"maintenance_state\" : \"OFF\", \"state\": \"STARTED\"}}" http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services/$SERVICE | grep "id" | grep -Po '([0-9]+)')

        echo "*********************************Start $SERVICE TaskID $TASKID"
        sleep 2
        LOOPESCAPE="false"
        until [ "$LOOPESCAPE" == true ]; do
            TASKSTATUS=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -X GET http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/requests/$TASKID | grep "request_status" | grep -Po '([A-Z]+)')
            if [[ "$TASKSTATUS" == COMPLETED || "$TASKSTATUS" == FAILED ]]; then
                LOOPESCAPE="true"
            fi
            echo "*********************************Start $SERVICE Task Status $TASKSTATUS"
            sleep 2
        done
       	elif [ "$SERVICE_STATUS" == STARTED ]; then
       	echo "*********************************$SERVICE Service Started..."
       	fi
}

startServiceAndComplete (){
       	SERVICE=$1
       	SERVICE_STATUS=$(getServiceStatus $SERVICE)
       	echo "*********************************Starting Service $SERVICE ..."
       	if [ "$SERVICE_STATUS" == INSTALLED ]; then
        TASKID=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -H "X-Requested-By:ambari" -i -X PUT -d "{\"RequestInfo\": {\"context\": \"INSTALL COMPLETE\"}, \"ServiceInfo\": {\"maintenance_state\" : \"OFF\", \"state\": \"STARTED\"}}" http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services/$SERVICE | grep "id" | grep -Po '([0-9]+)')

        echo "*********************************Start $SERVICE TaskID $TASKID"
        sleep 2
        LOOPESCAPE="false"
        until [ "$LOOPESCAPE" == true ]; do
            TASKSTATUS=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -X GET http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/requests/$TASKID | grep "request_status" | grep -Po '([A-Z]+)')
            if [[ "$TASKSTATUS" == COMPLETED || "$TASKSTATUS" == FAILED ]]; then
                LOOPESCAPE="true"
            fi
            echo "*********************************Start $SERVICE Task Status $TASKSTATUS"
            sleep 2
        done
       	elif [ "$SERVICE_STATUS" == STARTED ]; then
       	echo "*********************************$SERVICE Service Started..."
       	fi
}


installNifiService () {
       	echo "*********************************Creating NIFI service..."
       	# Create NIFI service
       	curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -H "X-Requested-By:ambari" -i -X POST http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services/NIFI

       	sleep 2
       	echo "*********************************Adding NIFI MASTER component..."
       	# Add NIFI Master component to service
       	curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -H "X-Requested-By:ambari" -i -X POST http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services/NIFI/components/NIFI_MASTER
		curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -H "X-Requested-By:ambari" -i -X POST http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services/NIFI/components/NIFI_CA
		
       	sleep 2
       	echo "*********************************Creating NIFI configuration..."

       	# Create and apply configuration
		/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME nifi-ambari-config $ROOT_PATH/CloudBreakArtifacts/hdf-config/nifi-config/nifi-ambari-config.json

		/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME nifi-ambari-ssl-config $ROOT_PATH/CloudBreakArtifacts/hdf-config/nifi-config/nifi-ambari-ssl-config.json

		/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME nifi-authorizers-env $ROOT_PATH/CloudBreakArtifacts/hdf-config/nifi-config/nifi-authorizers-env.json

		/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME nifi-bootstrap-env $ROOT_PATH/CloudBreakArtifacts/hdf-config/nifi-config/nifi-bootstrap-env.json

		/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME nifi-bootstrap-notification-services-env $ROOT_PATH/CloudBreakArtifacts/hdf-config/nifi-config/nifi-bootstrap-notification-services-env.json

		/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME nifi-env $ROOT_PATH/CloudBreakArtifacts/hdf-config/nifi-config/nifi-env.json

		/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME nifi-flow-env $ROOT_PATH/CloudBreakArtifacts/hdf-config/nifi-config/nifi-flow-env.json

		/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME nifi-login-identity-providers-env $ROOT_PATH/CloudBreakArtifacts/hdf-config/nifi-config/nifi-login-identity-providers-env.json

		/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME nifi-node-logback-env $ROOT_PATH/CloudBreakArtifacts/hdf-config/nifi-config/nifi-node-logback-env.json

		/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME nifi-properties $ROOT_PATH/CloudBreakArtifacts/hdf-config/nifi-config/nifi-properties.json

		/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME nifi-state-management-env $ROOT_PATH/CloudBreakArtifacts/hdf-config/nifi-config/nifi-state-management-env.json
		
		/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME nifi-jaas-conf $ROOT_PATH/CloudBreakArtifacts/hdf-config/nifi-config/nifi-jaas-conf.json
				
		/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME nifi-logsearch-conf $ROOT_PATH/CloudBreakArtifacts/hdf-config/nifi-config/nifi-logsearch-conf.json
		
       	echo "*********************************Adding NIFI MASTER role to Host..."
       	# Add NIFI Master role to Ambari Host
       	curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -H "X-Requested-By:ambari" -i -X POST http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/hosts/$AMBARI_HOST/host_components/NIFI_MASTER

       	echo "*********************************Adding NIFI CA role to Host..."
		# Add NIFI CA role to Ambari Host
       	curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -H "X-Requested-By:ambari" -i -X POST http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/hosts/$AMBARI_HOST/host_components/NIFI_CA

       	sleep 30
       	echo "*********************************Installing NIFI Service"
       	# Install NIFI Service
       	TASKID=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -H "X-Requested-By:ambari" -i -X PUT -d '{"RequestInfo": {"context" :"Install Nifi"}, "Body": {"ServiceInfo": {"maintenance_state" : "OFF", "state": "INSTALLED"}}}' http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services/NIFI | grep "id" | grep -Po '([0-9]+)')
		
		sleep 2       	
       	if [ -z $TASKID ]; then
       		until ! [ -z $TASKID ]; do
       			TASKID=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -H "X-Requested-By:ambari" -i -X PUT -d '{"RequestInfo": {"context" :"Install Nifi"}, "Body": {"ServiceInfo": {"maintenance_state" : "OFF", "state": "INSTALLED"}}}' http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/services/NIFI | grep "id" | grep -Po '([0-9]+)')
       		 	echo "*********************************AMBARI TaskID " $TASKID
       		done
       	fi
       	
       	echo "*********************************AMBARI TaskID " $TASKID
       	sleep 2
       	LOOPESCAPE="false"
       	until [ "$LOOPESCAPE" == true ]; do
               	TASKSTATUS=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -X GET http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/requests/$TASKID | grep "request_status" | grep -Po '([A-Z]+)')
               	if [ "$TASKSTATUS" == COMPLETED ]; then
                       	LOOPESCAPE="true"
               	fi
               	echo "*********************************Task Status" $TASKSTATUS
               	sleep 2
       	done
}


waitForNifiServlet () {
       	LOOPESCAPE="false"
       	until [ "$LOOPESCAPE" == true ]; do
       		TASKSTATUS=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -X GET http://$AMBARI_HOST:9090/nifi-api/controller | grep -Po 'OK')
       		if [ "$TASKSTATUS" == OK ]; then
               		LOOPESCAPE="true"
       		else
               		TASKSTATUS="PENDING"
       		fi
       		echo "*********************************Waiting for NIFI Servlet..."
       		echo "*********************************NIFI Servlet Status... " $TASKSTATUS
       		sleep 2
       	done
}

instalHDFManagementPack () {
	wget http://public-repo-1.hortonworks.com/HDF/centos7/3.x/updates/3.0.1.1/tars/hdf_ambari_mp/hdf-ambari-mpack-3.0.1.1-5.tar.gz
ambari-server install-mpack --mpack=hdf-ambari-mpack-3.0.1.1-5.tar.gz --verbose

	sleep 2
	ambari-server restart
	waitForAmbari
	sleep 2
}

installHDPSearchManagementPack () {
  
  printf "[main]\nenabled = 0" >> /etc/yum/pluginconf.d/priorities.conf
  
  wget http://public-repo-1.hortonworks.com/HDP-SOLR/hdp-solr-ambari-mp/solr-service-mpack-3.0.0.tar.gz

  ambari-server install-mpack --mpack=solr-service-mpack-3.0.0.tar.gz
  sleep 2
  ambari-server restart
  waitForAmbari
  sleep 2
}

getHostByPosition (){
	HOST_POSITION=$1
	HOST_NAME=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -X GET http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER_NAME/hosts|grep -Po '"host_name" : "[a-zA-Z0-9_\W]+'|grep -Po ' : "([^"]+)'|grep -Po '[^: "]+'|tail -n +$HOST_POSITION|head -1)
	
	echo $HOST_NAME
}

configureAmbariRepos (){
	tee /etc/yum.repos.d/docker.repo <<-'EOF'
	[HDF-3.0]
	name=HDF-3.0
	baseurl=http://public-repo-1.hortonworks.com/HDF/centos7/3.x/updates/3.0.0.0
	path=/
	enabled=1
	gpgcheck=0
	EOF
	
	curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -d @$ROOT_PATH/CloudBreakArtifacts/hdf-config/api-payload/repo_update.json -H "X-Requested-By: ambari" -X PUT http://$AMBARI_HOST:8080/api/v1/stacks/HDP/versions/2.6/repository_versions/1
}

installMySQL (){
	yum remove -y mysql57-community*
	yum remove -y mysql56-server*
	yum remove -y mysql-community*
	rm -Rvf /var/lib/mysql

	yum install -y epel-release
	yum install -y libffi-devel.x86_64
	ln -s /usr/lib64/libffi.so.6 /usr/lib64/libffi.so.5

	yum install -y mysql-connector-java*
	ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar


	if [ $(cat /etc/system-release|grep -Po Amazon) == Amazon ]; then       	
		yum install -y mysql56-server
		service mysqld start
		chkconfig --levels 3 mysqld on
	else
		yum localinstall -y https://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
		yum install -y mysql-community-server
		#yum localinstall -y https://dev.mysql.com/get/mysql57-community-release-el7-8.noarch.rpm
#yum install -y mysql-community-server
		systemctl start mysqld.service
		systemctl enable mysqld.service
	fi
}


enablePhoenix () {
	echo "*********************************Installing Phoenix Binaries..."
	yum install -y phoenix
	echo "*********************************Enabling Phoenix..."
	/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME hbase-site phoenix.functions.allowUserDefinedFunctions true
	sleep 1
	/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME hbase-site hbase.defaults.for.version.skip true
	sleep 1
	/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME hbase-site hbase.regionserver.wal.codec org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec
	sleep 1
	/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME hbase-site hbase.region.server.rpc.scheduler.factory.class org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory
	sleep 1
	/var/lib/ambari-server/resources/scripts/configs.sh set $AMBARI_HOST $CLUSTER_NAME hbase-site hbase.rpc.controllerfactory.class org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory
}


installSolr() {
  #change this to management packs code

  yum install -y lucidworks-hdpsearch
  sudo -u hdfs hadoop fs -mkdir /user/solr
  sudo -u hdfs hadoop fs -chown solr /user/solr
}

initializeSolr () {
  cd /opt/lucidworks-hdpsearch/solr/server/solr-webapp/webapp/banana/app/dashboards/
  mv default.json default.json.orig
  wget https://raw.githubusercontent.com/abajwa-hw/ambari-nifi-service/master/demofiles/default.json

  cd /opt/lucidworks-hdpsearch/solr/server/solr/configsets/data_driven_schema_configs/conf
  mv -f solrconfig.xml solrconfig_bk.xml

    wget https://raw.githubusercontent.com/sujithasankuhdp/nifi-templates/master/templates/solrconfig.xml
}

startSolr() {
  /opt/lucidworks-hdpsearch/solr/bin/solr start -c -z $AMBARI_HOST:2181
  /opt/lucidworks-hdpsearch/solr/bin/solr create -c tweets -d data_driven_schema_configs -s 1 -rf 1 
  yum install -y ntp
  service ntpd stop
  ntpdate pool.ntp.org
  service ntpd start
}

createHiveTables () {
  sudo -u hdfs hadoop fs -mkdir /tmp/tweets_staging
  sudo -u hdfs hadoop fs -chmod -R 777 /tmp/tweets_staging


  sudo -u hdfs hive -e 'create table if not exists tweets_text_partition(
    tweet_id bigint, 
    created_unixtime bigint, 
    created_time string, 
    displayname string, 
  msg string,
  fulltext string
  )
  row format delimited fields terminated by "|"
  location "/tmp/tweets_staging";'
}

deployTemplateToNifi () {
        TEMPLATE_DIR=$1
        TEMPLATE_NAME=$2
        
        echo "*********************************Importing NIFI Template..."
        # Import NIFI Template HDF 3.x
        # TEMPLATE_DIR should have been passed in by the caller install process
        sleep 1
        TEMPLATEID=$(curl -v -F template=@"$TEMPLATE_DIR" -X POST http://$NIFI_HOST:9090/nifi-api/process-groups/root/templates/upload | grep -Po '<id>([a-z0-9-]+)' | grep -Po '>([a-z0-9-]+)' | grep -Po '([a-z0-9-]+)')
        sleep 1

        # Instantiate NIFI Template 3.x
        echo "*********************************Instantiating NIFI Flow..."
        curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -H "Content-Type:application/json" -d "{\"templateId\":\"$TEMPLATEID\",\"originX\":100,\"originY\":100}" -X POST http://$NIFI_HOST:9090/nifi-api/process-groups/root/template-instance
        sleep 1

        # Rename NIFI Root Group HDF 3.x
        echo "*********************************Renaming Nifi Root Group..."
        ROOT_GROUP_REVISION=$(curl -X GET http://$NIFI_HOST:9090/nifi-api/process-groups/root |grep -Po '\"version\":([0-9]+)'|grep -Po '([0-9]+)')

        sleep 1
        ROOT_GROUP_ID=$(curl -X GET http://$NIFI_HOST:9090/nifi-api/process-groups/root|grep -Po '("component":{"id":")([0-9a-zA-z\-]+)'| grep -Po '(:"[0-9a-zA-z\-]+)'| grep -Po '([0-9a-zA-z\-]+)')

        PAYLOAD=$(echo "{\"id\":\"$ROOT_GROUP_ID\",\"revision\":{\"version\":$ROOT_GROUP_REVISION},\"component\":{\"id\":\"$ROOT_GROUP_ID\",\"name\":\"$TEMPLATE_NAME\"}}")

        sleep 1
        curl -d $PAYLOAD  -H "Content-Type: application/json" -X PUT http://$NIFI_HOST:9090/nifi-api/process-groups/$ROOT_GROUP_ID

}

configureNifiTempate () {
  GROUP_TARGETS=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -X GET http://$AMBARI_HOST:9090/nifi-api/process-groups/root/process-groups | grep -Po '\"uri\":\"([a-z0-9-://.]+)' | grep -Po '(?!.*\")([a-z0-9-://.]+)')
    length=${#GROUP_TARGETS[@]}
    echo $length
    echo ${GROUP_TARGETS[0]}

    #for ((i = 0; i < $length; i++))
    for GROUP in $GROUP_TARGETS
    do
        #CURRENT_GROUP=${GROUP_TARGETS[i]}
        CURRENT_GROUP=$GROUP
        echo "***********************************************************calling handle ports with group $CURRENT_GROUP"
        handleGroupPorts $CURRENT_GROUP
        echo "***********************************************************calling handle processors with group $CURRENT_GROUP"
        handleGroupProcessors $CURRENT_GROUP
        echo "***********************************************************done handle processors"
    done

    ROOT_TARGET=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -X GET http://$AMBARI_HOST:9090/nifi-api/process-groups/root| grep -Po '\"uri\":\"([a-z0-9-://.]+)' | grep -Po '(?!.*\")([a-z0-9-://.]+)')

    handleGroupPorts $ROOT_TARGET

    handleGroupProcessors $ROOT_TARGET
}

handleGroupProcessors (){
        TARGET_GROUP=$1

        TARGETS=($(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -X GET $TARGET_GROUP/processors | grep -Po '\"uri\":\"([a-z0-9-://.]+)' | grep -Po '(?!.*\")([a-z0-9-://.]+)'))
        length=${#TARGETS[@]}
        echo $length
        echo ${TARGETS[0]}

        for ((i = 0; i < $length; i++))
        do
          ID=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -X GET ${TARGETS[i]} |grep -Po '"id":"([a-zA-z0-9\-]+)'|grep -Po ':"([a-zA-z0-9\-]+)'|grep -Po '([a-zA-z0-9\-]+)'|head -1)
          REVISION=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -X GET ${TARGETS[i]} |grep -Po '\"version\":([0-9]+)'|grep -Po '([0-9]+)')
          TYPE=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -X GET ${TARGETS[i]} |grep -Po '"type":"([a-zA-Z0-9\-.]+)' |grep -Po ':"([a-zA-Z0-9\-.]+)' |grep -Po '([a-zA-Z0-9\-.]+)' |head -1)
          echo "Current Processor Path: ${TARGETS[i]}"
          echo "Current Processor Revision: $REVISION"
          echo "Current Processor ID: $ID"
          echo "Current Processor TYPE: $TYPE"

            if ! [ -z $(echo $TYPE|grep "Record") ]; then
              echo "***************************This is a Record Processor"

              RECORD_READER=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -X GET ${TARGETS[i]} |grep -Po '"record-reader":"[a-zA-Z0-9-]+'|grep -Po ':"[a-zA-Z0-9-]+'|grep -Po '[a-zA-Z0-9-]+'|head -1)
                RECORD_WRITER=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -X GET ${TARGETS[i]} |grep -Po '"record-writer":"[a-zA-Z0-9-]+'|grep -Po ':"[a-zA-Z0-9-]+'|grep -Po '[a-zA-Z0-9-]+'|head -1)

                echo "Record Reader: $RECORD_READER"
                echo "Record Writer: $RECORD_WRITER"

              SCHEMA_REGISTRY=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -X GET http://$AMBARI_HOST:9090/nifi-api/controller-services/$RECORD_READER |grep -Po '"schema-registry":"[a-zA-Z0-9-]+'|grep -Po ':"[a-zA-Z0-9-]+'|grep -Po '[a-zA-Z0-9-]+'|head -1)

              echo "Schema Registry: $SCHEMA_REGISTRY"

              curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -H "Content-Type:application/json" -X PUT -d "{\"id\":\"$SCHEMA_REGISTRY\",\"revision\":{\"version\":$REVISION},\"component\":{\"id\":\"$SCHEMA_REGISTRY\",\"state\":\"ENABLED\",\"properties\":{\"url\":\"http:\/\/$AMBARI_HOST:7788\/api\/v1\"}}}" http://$AMBARI_HOST:9090/nifi-api/controller-services/$SCHEMA_REGISTRY

              curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -H "Content-Type:application/json" -X PUT -d "{\"id\":\"$RECORD_READER\",\"revision\":{\"version\":$REVISION},\"component\":{\"id\":\"$RECORD_READER\",\"state\":\"ENABLED\"}}" http://$AMBARI_HOST:9090/nifi-api/controller-services/$RECORD_READER

              curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -H "Content-Type:application/json" -X PUT -d "{\"id\":\"$RECORD_WRITER\",\"revision\":{\"version\":$REVISION},\"component\":{\"id\":\"$RECORD_WRITER\",\"state\":\"ENABLED\"}}" http://$AMBARI_HOST:9090/nifi-api/controller-services/$RECORD_WRITER

            fi
          if ! [ -z $(echo $TYPE|grep "PutKafka") ] || ! [ -z $(echo $TYPE|grep "PublishKafka") ]; then
            echo "***************************This is a PutKafka Processor"
            echo "***************************Updating Kafka Broker Porperty and Activating Processor..."
            if ! [ -z $(echo $TYPE|grep "PutKafka") ]; then
                    PAYLOAD=$(echo "{\"id\":\"$ID\",\"revision\":{\"version\":$REVISION},\"component\":{\"id\":\"$ID\",\"config\":{\"properties\":{\"Known Brokers\":\"$AMBARI_HOST:6667\"}},\"state\":\"RUNNING\"}}")
                else
                    PAYLOAD=$(echo "{\"id\":\"$ID\",\"revision\":{\"version\":$REVISION},\"component\":{\"id\":\"$ID\",\"config\":{\"properties\":{\"bootstrap.servers\":\"$AMBARI_HOST:6667\"}},\"state\":\"RUNNING\"}}")
                fi
          else
            echo "***************************Activating Processor..."
              PAYLOAD=$(echo "{\"id\":\"$ID\",\"revision\":{\"version\":$REVISION},\"component\":{\"id\":\"$ID\",\"state\":\"RUNNING\"}}")
            fi
          echo "$PAYLOAD"

          curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -H "Content-Type:application/json" -d "${PAYLOAD}" -X PUT ${TARGETS[i]}
        done
}

handleGroupPorts (){
        TARGET_GROUP=$1

        TARGETS=($(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -X GET $TARGET_GROUP/output-ports | grep -Po '\"uri\":\"([a-z0-9-://.]+)' | grep -Po '(?!.*\")([a-z0-9-://.]+)'))
        length=${#TARGETS[@]}
        echo $length
        echo ${TARGETS[0]}

        for ((i = 0; i < $length; i++))
        do
          ID=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -X GET ${TARGETS[i]} |grep -Po '"id":"([a-zA-z0-9\-]+)'|grep -Po ':"([a-zA-z0-9\-]+)'|grep -Po '([a-zA-z0-9\-]+)'|head -1)
          REVISION=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -X GET ${TARGETS[i]} |grep -Po '\"version\":([0-9]+)'|grep -Po '([0-9]+)')
          TYPE=$(curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -X GET ${TARGETS[i]} |grep -Po '"type":"([a-zA-Z0-9\-.]+)' |grep -Po ':"([a-zA-Z0-9\-.]+)' |grep -Po '([a-zA-Z0-9\-.]+)' |head -1)
          echo "Current Processor Path: ${TARGETS[i]}"
          echo "Current Processor Revision: $REVISION"
          echo "Current Processor ID: $ID"

          echo "***************************Activating Port ${TARGETS[i]}..."

          PAYLOAD=$(echo "{\"id\":\"$ID\",\"revision\":{\"version\":$REVISION},\"component\":{\"id\":\"$ID\",\"state\": \"RUNNING\"}}")

          echo "PAYLOAD"
          curl -u admin:H0rt0nw0rksDataScienceW0rsh0p -i -H "Content-Type:application/json" -d "${PAYLOAD}" -X PUT ${TARGETS[i]}
        done
}


loadPersoDetectionAddOns (){

	echo "*********************************Copying NARs..."
 	cp nifi-add-ons/nifi-BoilerpipeArticleExtractor-nar-1.7.0.3.2.0.0-520.nar /usr/hdf/current/nifi/lib/
 	chown nifi:nifi /usr/hdf/current/nifi/lib/nifi-BoilerpipeArticleExtractor-nar-1.7.0.3.2.0.0-520.nar
 
 	cp nifi-add-ons/nifi-MairessePersonalityRecognition-nar-1.5.0.3.1.2.0-7.nar /usr/hdf/current/nifi/lib/
 	chown nifi:nifi /usr/hdf/current/nifi/lib/nifi-MairessePersonalityRecognition-nar-1.5.0.3.1.2.0-7.nar
 
 
 	echo "*********************************Copying lib files..."
 	cp -R nifi-add-ons/to-upload-to-nifi-home/* /home/nifi/
 	cp /usr/hdp/current/hadoop-client/conf/core-site.xml /home/nifi/hdpconf/
 	cp /usr/hdp/current/hadoop-client/conf/hdfs-site.xml /home/nifi/hdpconf/
 	chown -R nifi:nifi /home/nifi/*
 
}



export AMBARI_HOST=$(hostname -f)

export CLUSTER_NAME=$(curl -u admin:admin -X GET http://$AMBARI_HOST:8080/api/v1/clusters |grep cluster_name|grep -Po ': "(.+)'|grep -Po '[a-zA-Z0-9\-_!?.]+')
echo "*********************************AMBARI HOST IS: $NIFI_HOST"


#echo "*********************************Waiting for cluster install to complete..."
#waitForServiceToStart YARN
#
#waitForServiceToStart HDFS
#
#waitForServiceToStart HIVE
#
#waitForServiceToStart ZOOKEEPER
#
#waitForServiceToStart NIFI
#
#sleep 10



echo "*********************************Install Utilities..."
installUtils

echo "*********************************Download Configurations"
git https://github.com/kirkhas/datascience-workshop.git
cd datascience-workshop

export ROOT_PATH=`pwd`
echo "*********************************ROOT PATH IS: $ROOT_PATH"


echo "*********************************Authenticating to Zeppelin..."
token=`curl -i --data 'userName=admin&password=H0rt0nw0rksDataScienceW0rsh0p' -X POST http://$AMBARI_HOST:9995/api/login | grep JSESSIONID | tail -1 | sed s/Set-Cookie\:\ //g | awk -F";" '{print $1}' | awk -F"=" '{print $2}'`

echo "*********************************Loading notes..."

MUSHROOM_CLASSIFIER=`cat $ROOT_PATH/zeppelin-notebooks/MushroomClassifier.json`
CENSUS_ECON=`cat $ROOT_PATH/zeppelin-notebooks/CensusECON.json`
SBIR=`cat $ROOT_PATH/zeppelin-notebooks/SBIR.json`


curl -X POST \
  http://$AMBARI_HOST:9995/api/notebook/import \
  -H 'Content-Type: application/json' \
  -b "JSESSIONID="$token"; Path=/; HttpOnly" \
  -d "'"$MUSHROOM_CLASSIFIER"'"



#echo "********************************* Configuring Nifi Template"
#configureNifiTempate
#
#echo "********************************* Adding Symbolic Links to Atlas Client..."
##Add symbolic links to Atlas Hooks
#rm -f /usr/hdf/current/storm-client/lib/atlas-plugin-classloader.jar
#rm -f /usr/hdf/current/storm-client/lib/storm-bridge-shim.jar
#
#export ATLAS_PLUGIN_CLASSLOADER=$(ls -l /usr/hdp/current/atlas-client/hook/storm/atlas-plugin-classloader*|grep -Po 'atlas-plugin-classloader-[\D\d]+')
#
#export ATLAS_STORM_BRIDGE=$(ls -l /usr/hdp/current/atlas-client/hook/storm/storm-bridge-shim-*|grep -Po 'storm-bridge-shim-[\D\d]+')
#
#ln -s /usr/hdp/current/atlas-client/hook/storm/$ATLAS_PLUGIN_CLASSLOADER /usr/hdf/current/storm-client/lib/atlas-plugin-classloader.jar
#
#ln -s /usr/hdp/current/atlas-client/hook/storm/$ATLAS_STORM_BRIDGE /usr/hdf/current/storm-client/lib/storm-bridge-shim.jar
#
#exit 0