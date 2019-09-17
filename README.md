# Docker LAMP stack for Drupal development

**The container is intended for local usage and should never be used in production environment.**

## What is inside

* Apache
* MariaDB
* PHP 7
* phpMyAdmin
* Adminer
* Xdebug
* Composer
* PHP-CS-Fixer
* Drush
* Drupalcs
* Drupal Code Generator
* MailHog
* NPM tools (Grunt, Gulp, etc)
* SSH server

## Creating the container

Basically you can create the container in two ways. The first one (classic) is exposing container services through the explicit port mapping.
```bash
#!/usr/bin/env bash

PROJECT_NAME=example
PROJECT_DIR=/var/docker/projects/$PROJECT_NAME

docker create \
 -h $PROJECT_NAME \
 -p 80:80 \
 -v $PROJECT_DIR/www:/var/www \
 -v $PROJECT_DIR/mysql:/var/lib/mysql \
 --name $PROJECT_NAME \
 --group-add sudo \
 --group-add www-data \
 attr/drupal-lamp
```
At this point the container can be started with the following command `docker start example`.
Having this done you can access web server index page by navigating to the following url: http://localhost.

The second way requires you to create custom docker network.
```bash
#!/usr/bin/env bash

docker network create \
  --subnet=172.28.0.0/16 \
  --gateway=172.28.0.254 \
  my-net
```
Now the container can be created as follows:
```bash
#!/usr/bin/env bash

PROJECT_NAME=example
PROJECT_DIR=/var/docker/projects/$PROJECT_NAME

docker create \
 -h $PROJECT_NAME \
 -v $PROJECT_DIR/www:/var/www \
 -v $PROJECT_DIR/mysql:/var/lib/mysql \
 --net my-net \
 --ip 172.28.0.1 \
 --name $PROJECT_NAME \
 --group-add sudo \
 --group-add www-data \
  attr/drupal-lamp
```
The IP address may be whatever you like but make sure it belongs the subnet you created before. It can be helpful to map the IP address to a hostname using _/etc/hosts_ file.
```
172.28.0.1 example.local
```
New containers can be attached to the same network or to a distinct one for better isolation.

## Connecting to the container

It is strongly recommended you connect to the container using **lamp** account.
```
docker exec -itu lamp:www-data example bash
```

You may create an alias for less typing.
```
echo 'alias example="docker start example && docker exec -itu lamp example bash"' >> ~/.bashrc
```

## Xdebug
Xdebug is switched off by default for performance reason. Run the following
command to switch it on before debugging.
```
sudo xdebug on
```

## Available ports
* 22 - SSH
* 80 - HTTP
* 443 - HTTPS
* 1025 - MailHog SMTP
* 3306 - MySQL
* 8025 - MailHog web UI
* 8088 - PhpMyAdmin
* 8089 - Adminer

## Access
* Host user name - lamp
* Host user password - 123
* MySQL root password - 123
