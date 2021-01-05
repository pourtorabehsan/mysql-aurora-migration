update mysql_servers set status = 'ONLINE' WHERE hostgroup_id = 11 and comment = 'RDS READER';
update mysql_servers set status = 'OFFLINE_SOFT' where hostgroup_id = 11 and comment = 'MYSQL READER';
LOAD MYSQL SERVERS TO RUNTIME;