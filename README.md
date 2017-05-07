# Docker LAMP stack for Drupal development

**The container is intended for local usage and should never be used in production environment.**

## Included software

* Apache
* MySQL
* PHP (5.6)
* phpMyAdmin
* Xdebug
* Composer
* Drush
* DrupalRC
* PHP code sniffer
* Drupal code generator
* MailHog

## Running the container

Basically you can run the container in two ways. The first one (classic) is exposing container services through the explicit port mapping.
```bash
#! /bin/bash

PROJECTS_DIR=/var/docker/projects/
PROJECT_NAME=example

docker run -dit \
 -h $PROJECT_NAME \
 -p 80:80 \
 -v $PROJECTS_DIR/$PROJECT_NAME/www:/var/www \
 -v $PROJECTS_DIR/$PROJECT_NAME/mysql:/var/lib/mysql \
 --name $PROJECT_NAME \
  attr/drupal-lamp
```
Having this done you can access web server index page by navigating to the following url: http://localhost.

The second way requires you to create custom docker network.
```bash
#! /bin/bash

docker network create \
  --subnet=172.28.0.0/16 \
  --gateway=172.28.0.254 \
  my-net
```
Now the container can be created as follows:
```bash
#! /bin/bash

PROJECTS_DIR=/var/docker/projects/
PROJECT_NAME=example

docker run -dit \
 -h $PROJECT_NAME \
 -v $PROJECTS_DIR/$PROJECT_NAME/www:/var/www \
 -v $PROJECTS_DIR/$PROJECT_NAME/mysql:/var/lib/mysql \
 --net my-net \
 --ip 172.28.0.1 \
 --name $PROJECT_NAME \
  attr/drupal-lamp
```
The IP address may be whatever you like but make sure it belongs the subnet you created before. It can be helpful to map the IP address to a hostname using system hosts file.
```
172.28.0.1 example.local
```
New containers can be attached to the same network or to a distinct one for better isolation.

## Connecting to the container

It is strongly recommended you connect to the container using **lamp** account.
```bash
docker exec -itu lamp:www-data example bash
```
You may want to create an alias for less typing.
```bash
echo 'alias example="docker start example && docker exec -itu lamp:www-data example bash"' >> ~/.bashrc
```

## Available ports
* 80 - Main HTTP
* 3306 - MySql
* 1025 - MailHot SMTP
* 8025 - MailHog web UI
* 8088 - PhpMyAdmin

## Access
* Host user name - lamp
* Host user password - 123
* MySql root password - 123
