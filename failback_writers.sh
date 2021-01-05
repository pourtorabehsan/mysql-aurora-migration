#!/bin/bash

set -e

proxy_login_path="proxysql"
mysql_login_path="mysql"
rds_login_path="aurora"

function progress {
        echo "-----------------------------"
        date
        echo $1
}

function read_slave_status {

	progress "reading slave status..."
	slave_status=$(mysql --login-path=$1 -e "SHOW SLAVE STATUS\G")

	slave_seconds_behind_master=$(echo "$slave_status" | grep "Seconds_Behind_Master" | awk '{ print $2 }')
	slave_master_log_file=$(echo "$slave_status" | grep "[^_]Master_Log_File" | awk '{ print $2 }')
	slave_read_master_log_pos=$(echo "$slave_status" | grep "Read_Master_Log_Pos" | awk '{ print $2 }')
	slave_exec_master_log_pos=$(echo "$slave_status" | grep "Exec_Master_Log_Pos" | awk '{ print $2 }')

	echo "-Seconds_Behind_Master=$slave_seconds_behind_master"
	echo "-Master_Log_File=$slave_master_log_file"
	echo "-Read_Master_Log_Pos=$slave_read_master_log_pos"
	echo "-Exec_Master_Log_Pos=$slave_exec_master_log_pos"
}

function read_master_status {

	progress "reading master status..."
	master_status=$(mysql --login-path=$1 -e "SHOW MASTER STATUS\G")

	master_log_file=$(echo "$master_status" | grep "File" | awk '{ print $2 }')
	master_log_position=$(echo "$master_status" | grep "Position" | awk '{ print $2 }')

	echo "-Master_Log_File=$master_log_file"
	echo "-Master_Log_Position=$master_log_position"
}

function start_reverese_replication {
	progress "starting reverse replication..."

	sql="CALL mysql.rds_set_external_master ('mysql-node-1', 3306, 'rds_replication', 'password', '$master_log_file', $master_log_position, 0);"
	echo "$sql"
	mysql --login-path=$rds_login_path -e "$sql"

	start_repl="CALL mysql.rds_start_replication;"
	mysql --login-path=$rds_login_path -e "$start_repl"

}

# ---------main module---------

progress "starting cutover..."

progress "setting mysql writers offline soft.."
mysql --login-path=$proxy_login_path < ./08_set_rds_writers_offlline_soft.sql

progress "waiting 2 seconds to finish active transactions..."
sleep 1

progress "setting mysql writers offline hard..."
mysql --login-path=$proxy_login_path < ./09_set_rds_writers_offlline_hard.sql

slave_seconds_behind_master=1

while :
do
	read_slave_status $mysql_login_path
	read_master_status $rds_login_path
	if [ $slave_seconds_behind_master -eq  0 ] && [ $slave_read_master_log_pos -eq $slave_exec_master_log_pos ] && [ "$master_log_file" = "$slave_master_log_file" ] && [ $master_log_position -eq $slave_read_master_log_pos ]; then
		progress "MySql replication caught up."
		break
	fi
	progress "waiting 1 second for replication to catch up..."
	sleep 1
done


progress "stopping replication..."
mysql --login-path=$mysql_login_path < ./10_stop_mysql_replication.sql
progress "replication stopped."

read_master_status $mysql_login_path
start_reverese_replication

slave_seconds_behind_master=1

while :
do
	read_slave_status $rds_login_path
	read_master_status $mysql_login_path
	if [ $slave_seconds_behind_master -eq  0 ] && [ $slave_read_master_log_pos -eq $slave_exec_master_log_pos ] && [ "$master_log_file" = "$slave_master_log_file" ] && [ $master_log_position -eq $slave_read_master_log_pos ]; then
		progress "RDS replication caught up."
		break
	fi
	progress "waiting 1 second for replication to catch up..."
	sleep 1
done

progress "setting rds writers online ..."
mysql --login-path=$proxy_login_path < ./11_set_mysql_writers_online.sql

progress "FAILBACK COMPLETED. MONITOR TRAFFIC NOW."
