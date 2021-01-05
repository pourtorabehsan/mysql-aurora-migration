#!/bin/bash

set -e

proxy_login_path="proxysql"

echo "setting rds readers online, they can accept queries now..."
mysql --login-path=$proxy_login_path < ./01_set_rds_readers_online.sql

echo "waiting for 5 seconds for the current queries to complete..."
sleep 5

echo "setting mysql readers offline, all read traffic should go to rds now..."
mysql --login-path=$proxy_login_path < ./02_set_mysql_readers_offlline.sql

echo "CUT-OVER READERS COMPLETED - Please monitor readers."
