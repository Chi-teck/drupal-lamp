FROM debian:jessie

# Set variables.
ENV MYSQL_ROOT_PASS=123 \
    DUMB_INIT_VERSION=1.2.0 \
    DRUSH_VERSION=8.1.11 \
    DCG_VERSION=1.15.1 \
    PHPMYADMIN_VERSION=4.7.0 \
    MAILHOG_VERSION=v1.0.0 \
    MHSENDMAIL_VERSION=v0.2.0 \
    PECO_VERSION=v0.5.1 \
    HOST_USER_NAME=lamp \
    HOST_USER_UID=1000 \
    HOST_USER_PASS=123 \
    DEBIAN_FRONTEND=noninteractive

# Install required packages.
RUN apt-get update && apt-get -y install --no-install-recommends apt-utils \
    sudo curl net-tools wget git vim zip unzip mc sqlite3 tree ncdu less \
    silversearcher-ag bsdmainutils man html2text bash-completion ca-certificates \
    apache2 mysql-server mysql-client libapache2-mod-php5 php5 php5-mysql \
    php5-curl php5-gd php5-json php5-cgi php5-xdebug php-apc php-pear

# Enable mod rewrite.
RUN a2enmod rewrite
    
# Change default document root.
COPY sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf

# Set server name.
RUN echo 'ServerName localhost' >> /etc/apache2/apache2.conf

# Install dumb-init.
RUN wget https://github.com/Yelp/dumb-init/releases/download/v$DUMB_INIT_VERSION/dumb-init_"$DUMB_INIT_VERSION"_amd64.deb && dpkg -i dumb-init_*.deb

# Copy sudoers file.
COPY sudoers /etc/sudoers

# Change mysql root password.
RUN service mysql start && mysqladmin -u root password $MYSQL_ROOT_PASS

# Change PHP settings.
COPY 20-development-apache.ini /etc/php5/apache2/conf.d/20-development.ini
COPY 20-development-cli.ini /etc/php5/cli/conf.d/20-development.ini
COPY 20-xdebug.ini etc/php5/apache2/conf.d/20-xdebug.ini
COPY 20-xdebug.ini /etc/php5/cli/conf.d/20-xdebug.ini
    
# Create host user.
RUN useradd $HOST_USER_NAME -m -u$HOST_USER_UID -Gsudo
RUN echo $HOST_USER_NAME:$HOST_USER_PASS | chpasswd
  
# Install dot files.
COPY vimrc /home/$HOST_USER_NAME/.vimrc
COPY gitconfig /home/$HOST_USER_NAME/.gitconfig
COPY gitignore /home/$HOST_USER_NAME/.gitignore
COPY config /home/$HOST_USER_NAME/.config
RUN sed -i "s/%USER%/$HOST_USER_NAME/g" /home/$HOST_USER_NAME/.config/mc/hotlist
RUN sed -i "s/%PHP_VERSION%/$PHP_VERSION/g" /home/$HOST_USER_NAME/.config/mc/hotlist
COPY bashrc /tmp/bashrc
RUN cat /tmp/bashrc >> /home/$HOST_USER_NAME/.bashrc && rm /tmp/bashrc

# Install MailHog.
RUN wget https://github.com/mailhog/MailHog/releases/download/$MAILHOG_VERSION/MailHog_linux_amd64 && \
    chmod +x MailHog_linux_amd64 && \
    mv MailHog_linux_amd64 /usr/local/bin/mailhog && \
    wget https://github.com/mailhog/mhsendmail/releases/download/$MHSENDMAIL_VERSION/mhsendmail_linux_amd64 && \
    chmod +x mhsendmail_linux_amd64 && \
    mv mhsendmail_linux_amd64 /usr/local/bin/mhsendmail

# Install PhpMyAdmin
RUN wget http://files.directadmin.com/services/all/phpMyAdmin/phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.tar.gz && \
    tar -xf phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.tar.gz && \
    mv phpMyAdmin-$PHPMYADMIN_VERSION-all-languages /usr/share/phpmyadmin && \
    rm phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.tar.gz
COPY config.inc.php /usr/share/phpmyadmin/config.inc.php
RUN sed -i "s/root_pass/$MYSQL_ROOT_PASS/" /usr/share/phpmyadmin/config.inc.php
COPY sites-available/phpmyadmin.conf /etc/apache2/sites-available/phpmyadmin.conf
RUN a2ensite phpmyadmin

# Install composer.
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer
    
# Install Drush.
RUN wget https://github.com/drush-ops/drush/releases/download/$DRUSH_VERSION/drush.phar && chmod +x drush.phar && mv drush.phar /usr/local/bin/drush
RUN mkdir /home/$HOST_USER_NAME/.drush && chown $HOST_USER_NAME:$HOST_USER_NAME /home/$HOST_USER_NAME/.drush
COPY drushrc.php /home/$HOST_USER_NAME/.drush/drushrc.php

# Install touch site extra Drush command.
RUN (cd /home/$HOST_USER_NAME/.drush && wget https://raw.githubusercontent.com/Chi-teck/touch-site/master/touch_site.drush.inc)

# Enable drush completion.
COPY drush.complete.sh /etc/bash_completion.d/drush.complete.sh

# Install DrupalRC.
RUN url=https://raw.githubusercontent.com/Chi-teck/drupalrc/master && \
    wget -O /etc/drupalrc $url/drupalrc && echo source /etc/drupalrc >> /etc/bash.bashrc && \
    wget -O /etc/bash_completion.d/drupal.complete.sh $url/drupal.complete.sh && \
    mkdir /usr/share/drupal-projects && \
    wget -P /usr/share/drupal-projects $url/drupal-projects/d6.txt && \
    wget -P /usr/share/drupal-projects $url/drupal-projects/d7.txt && \
    wget -P /usr/share/drupal-projects $url/drupal-projects/d8.txt

# Install phpcs
RUN wget https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar && chmod +x phpcs.phar && mv phpcs.phar /usr/local/bin/phpcs

# Install drupalcs
RUN cd /usr/share/php5 && drush dl coder && phpcs --config-set installed_paths /usr/share/php5/coder/coder_sniffer

# Install DCG.
RUN wget https://github.com/Chi-teck/drupal-code-generator/releases/download/$DCG_VERSION/dcg.phar && chmod +x dcg.phar && mv dcg.phar /usr/local/bin/dcg

# Install Peco.
RUN wget -P /tmp https://github.com/peco/peco/releases/download/$PECO_VERSION/peco_linux_amd64.tar.gz && \
    tar -xvf /tmp/peco_linux_amd64.tar.gz -C /tmp && \
    mv /tmp/peco_linux_amd64/peco /usr/local/bin/peco && \
    chmod +x /usr/local/bin/peco

# Install Node.js and NPM.
RUN curl -sL https://deb.nodesource.com/setup_7.x | bash - && apt-get install -y nodejs

# Copy MySql data to a temporary location. 
RUN service mysql stop && mkdir /var/lib/_mysql && cp -R /var/lib/mysql/* /var/lib/_mysql

# Set host user directory owner.
RUN chown -R $HOST_USER_NAME:$HOST_USER_NAME /home/$HOST_USER_NAME

# Empty /tmp directory.
RUN rm -rf /tmp/*

# Install cmd.sh file.
COPY cmd.sh /root/cmd.sh
RUN chmod +x /root/cmd.sh

# Default command..
CMD ["dumb-init", "-c", "--", "/root/cmd.sh"]
