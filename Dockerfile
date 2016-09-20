FROM phusion/baseimage:latest
MAINTAINER Daniel Graziotin <daniel@ineed.coffee>

# based on dgraziotin/docker-osx-lamp
# MAINTAINER Fernando Mayo <fernando@tutum.co>, Feng Honglin <hfeng@tutum.co>
ENV DOCKER_USER_ID 501 
ENV DOCKER_USER_GID 20

ENV BOOT2DOCKER_ID 1000
ENV BOOT2DOCKER_GID 50

# Tweaks to give Apache/PHP write permissions to the app
RUN usermod -u ${BOOT2DOCKER_ID} www-data && \
    usermod -G staff www-data

RUN groupmod -g $(($BOOT2DOCKER_GID + 10000)) $(getent group $BOOT2DOCKER_GID | cut -d: -f1)
RUN groupmod -g ${BOOT2DOCKER_GID} staff

# Install packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
  apt-get -y install apt-utils && \
  apt-get -y install supervisor wget git apache2 php libapache2-mod-php mcrypt php-mcrypt php-mbstring php-gettext php-mysql php-zip pwgen zip unzip  && \
  echo "ServerName localhost" >> /etc/apache2/apache2.conf

# needed for phpMyAdmin
run phpenmod mcrypt
run phpenmod mbstring

# Add image configuration and scripts
ADD start-apache2.sh /start-apache2.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh
ADD supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf

# config to enable .htaccess
ADD apache_default /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Configure /app folder with sample app
RUN mkdir -p /app && rm -fr /var/www/html && ln -s /app /var/www/html
ADD app/ /app

#Environment variables to configure php
ENV PHP_UPLOAD_MAX_FILESIZE 10M
ENV PHP_POST_MAX_SIZE 10M

# Add volumes for the app and MySql
VOLUME  ["/app" ]

EXPOSE 80
CMD ["/run.sh"]
