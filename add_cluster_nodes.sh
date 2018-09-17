#!/bin/bash

ipaddr=$(hostname -i | awk ' { print $1 } ')

for i in $(curl --key /etc/docker/ssl/calculonc-key.pem --cert /etc/docker/ssl/calculonc.pem --cacert /etc/docker/ssl/ca.pem https://$DISCOVERY_SERVICE/v2/keys/pxc-cluster/$CLUSTER_NAME/ | jq -r '.node.nodes[]?.key' | awk -F'/' '{print $(NF)}')
do
	echo $i 
        mysql -h $i -uroot -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL ON *.* TO '$MYSQL_PROXY_USER'@'$ipaddr' IDENTIFIED BY '$MYSQL_PROXY_PASSWORD'"
        mysql -h 127.0.0.1 -P6032 -uadmin -p$PROXYSQL_ADMIN_PASSWORD -e "INSERT INTO mysql_servers (hostgroup_id, hostname, port, max_replication_lag) VALUES (10, '$i', 3306, 20);"
 done

mysql -h 127.0.0.1 -P6032 -uadmin -p$PROXYSQL_ADMIN_PASSWORD -e "INSERT INTO mysql_users (username, password, active, default_hostgroup, max_connections) VALUES ('$MYSQL_PROXY_USER', '$MYSQL_PROXY_PASSWORD', 1, 0, 200);"
mysql -h 127.0.0.1 -P6032 -uadmin -p$PROXYSQL_ADMIN_PASSWORD -e "LOAD MYSQL SERVERS TO RUNTIME; SAVE MYSQL SERVERS TO DISK; LOAD MYSQL USERS TO RUNTIME; SAVE MYSQL USERS TO DISK;"
