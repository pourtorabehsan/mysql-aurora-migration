update mysql_servers set status = 'ONLINE' WHERE hostgroup_id = 10 and comment = 'RDS WRITER';
LOAD MYSQL SERVERS TO RUNTIME;
