#!/usr/bin/env bash

# Return orignal mysql directory if the mounted one is empty.
if [ ! "$(ls -A "/var/lib/mysql")" ]; then
  cp -R /var/lib/mysql_default/* /var/lib/mysql
  chown -R mysql:mysql /var/lib/mysql
fi

# Change document root owner.
if [ ! "$(ls -A "/var/www")" ]; then
  chown $HOST_USER_NAME:$HOST_USER_NAME /var/www
fi

nohup mailhog &

service apache2 start && xdebug off

service mysql start

service ssh start

tail -f /var/log/apache2/access.log
