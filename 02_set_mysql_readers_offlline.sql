update mysql_servers set status = 'OFFLINE_HARD' where hostgroup_id = 11 and comment = 'MYSQL READER';
LOAD MYSQL SERVERS TO RUNTIME;