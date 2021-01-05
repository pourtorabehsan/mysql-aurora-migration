update mysql_servers set status = 'ONLINE' where hostgroup_id = 10 and comment = 'MYSQL WRITER';
LOAD MYSQL SERVERS TO RUNTIME;
