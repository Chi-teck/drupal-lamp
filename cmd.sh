#! /bin/bash

# Return orignal mysql directory if the mounted one is empty.
if [ ! "$(ls -A "/var/lib/mysql")" ]; then
  cp -R /var/lib/_mysql/* /var/lib/mysql
  chown -R mysql:mysql /var/lib/mysql
fi

# Change document root owner.
if [ ! "$(ls -A "/var/www")" ]; then
  chown $HOST_USER_NAME:$HOST_USER_NAME /var/www
fi

service apache2 start

service mysql start

# Make sure that password for debian system account is still valid.
DEBIAN_PASS=$(cat /etc/mysql/debian.cnf | awk '/password/ {print $3; exit}') && \
mysql -uroot -p$MYSQL_ROOT_PASS -e"GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '$DEBIAN_PASS' WITH GRANT OPTION"

nohup mailhog &

tail -f /var/log/apache2/access.log
