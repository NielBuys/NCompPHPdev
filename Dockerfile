# sudo docker build -t ncompphp84dev .

# sudo docker run  -p 80:80 --add-host=host.docker.internal:host-gateway --name ncompphp84dev -d -v /var/www/html:/var/www/html ncompphp84dev

# explaining: -v /var/www/html:/var/www/html 
# The first /var/www/html (before the colon :) is the path on your host machine
# The second /var/www/html (after the colon :) is the path inside the Docker container.

# host.docker.internal = Host system ip

FROM ubuntu:24.04
MAINTAINER Niel Buys <nbuys@ncomp.co.za>

# Install Apache, PHP, and supplementary programs
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install software-properties-common

RUN add-apt-repository ppa:ondrej/php

RUN apt-get -y install \
    apache2 php8.4 php8.4-mysql php8.4-cli php8.4-common php8.4-curl php8.4-gd php8.4-imap php8.4-intl php8.4-ldap php8.4-mbstring \
    php8.4-opcache php8.4-readline libapache2-mod-php8.4 php8.4-xdebug php8.4-xml php8.4-zip php8.4-dev php-pear \
    unixodbc-dev curl

RUN pecl install sqlsrv
RUN pecl install pdo_sqlsrv
RUN printf "; priority=20\nextension=sqlsrv.so\n" > /etc/php/8.4/mods-available/sqlsrv.ini
RUN printf "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/8.4/mods-available/pdo_sqlsrv.ini

RUN curl -sSL -O https://packages.microsoft.com/config/ubuntu/$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2)/packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb
RUN apt-get update
RUN ACCEPT_EULA=Y apt-get install -y msodbcsql18

# Enable Apache mods
RUN a2enmod php8.4
RUN a2enmod rewrite
RUN phpenmod -v 8.4 sqlsrv pdo_sqlsrv

# Update PHP.ini file
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/8.4/apache2/php.ini
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ALL/" /etc/php/8.4/apache2/php.ini
RUN sed -i "s/display_errors = .*/display_errors = On/" /etc/php/8.4/apache2/php.ini

# Create the 20-xdebug.ini file with xdebug configuration
RUN echo "zend_extension=xdebug.so\n\
xdebug.start_with_request = yes\n\
xdebug.mode = debug\n\
xdebug.remote_handler = dbgp\n\
xdebug.client_host = host.docker.internal\n\
xdebug.log = /tmp/xdebug_remote.log\n\
xdebug.client_port = 9003" \
> /etc/php/8.4/apache2/conf.d/20-xdebug.ini

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
