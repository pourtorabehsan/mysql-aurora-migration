#!/bin/bash

set -e

proxy_login_path="proxysql"

echo "failing back readers..."
mysql --login-path=$proxy_login_path < ./03_failback_readers.sql

echo "FAILBACK READERS COMPLETED"
