# Dockerfile started from https://writing.pupius.co.uk/apache-and-php-on-docker-44faef716150
# 
# sudo docker build -t ncompphp83dev .

# sudo docker run  -p 80:80 --add-host=host.docker.internal:host-gateway --name ncompphp83dev -d -v /var/www/html:/var/www/html ncompphp83dev

# explaining: -v /var/www/html:/var/www/html 
# The first /var/www/html (before the colon :) is the path on your host machine
# The second /var/www/html (after the colon :) is the path inside the Docker container.

# host.docker.internal = Host system ip

FROM ubuntu:latest
MAINTAINER Niel Buys <nbuys@ncomp.co.za>

# Install Apache, PHP, and supplementary programs
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install \
    apache2 php8.3 php8.3-mysql php8.3-cli php8.3-common php8.3-curl php8.3-gd php8.3-imap php8.3-intl php8.3-ldap php8.3-mbstring php8.3-opcache php8.3-readline libapache2-mod-php8.3 php8.3-xdebug php8.3-xml php8.3-zip

# Enable Apache mods
RUN a2enmod php8.3
RUN a2enmod rewrite

# Update PHP.ini file
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/8.3/apache2/php.ini
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ALL/" /etc/php/8.3/apache2/php.ini
RUN sed -i "s/display_errors = .*/display_errors = On/" /etc/php/8.3/apache2/php.ini

# Create the 20-xdebug.ini file with xdebug configuration
RUN echo "zend_extension=xdebug.so\n\
xdebug.start_with_request = yes\n\
xdebug.mode = debug\n\
xdebug.remote_handler = dbgp\n\
xdebug.client_host = host.docker.internal\n\
xdebug.log = /tmp/xdebug_remote.log\n\
xdebug.client_port = 9003" \
> /etc/php/8.3/apache2/conf.d/20-xdebug.ini

# Configure Apache Directory settings
RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/c\<Directory /var/www/html/>\n\
    Options Indexes FollowSymLinks MultiViews\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' /etc/apache2/apache2.conf

# Set Apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Expose ports for Apache
EXPOSE 80

# Start Apache in the foreground
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
