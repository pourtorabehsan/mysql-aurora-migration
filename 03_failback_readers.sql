update mysql_servers set status = 'ONLINE' where hostgroup_id = 11 and comment = 'MYSQL READER';
update mysql_servers set status = 'OFFLINE_HARD' where hostgroup_id = 11 and comment = 'RDS READER';
LOAD MYSQL SERVERS TO RUNTIME;