update mysql_servers set status = 'OFFLINE_HARD' where hostgroup_id = 10 and comment = 'RDS WRITER';
LOAD MYSQL SERVERS TO RUNTIME;
