# sudo docker build -t ncompphp86dev .

# Linux
# sudo docker run  -p 80:80 --add-host=host.docker.internal:host-gateway --name ncompphp86dev -d -v /var/www/html:/var/www/html ncompphp86dev
# Windows
# docker run  -p 80:80 --name ncompphp86dev -d -v C:/html:/var/www/html ncompphp86dev

# explaining: -v /var/www/html:/var/www/html 
# The first /var/www/html (before the colon :) is the path on your host machine
# The second /var/www/html (after the colon :) is the path inside the Docker container.

# host.docker.internal = Host system ip

# opening Docker environment from vscode terminal
# docker exec -it ncompphp86dev /bin/bash

FROM ubuntu:26.04
LABEL maintainer="Niel Buys <nbuys@ncomp.co.za>"

# NOTE: ppa:ondrej/php is NOT used anymore. Ondrej stopped adding new Ubuntu LTS
# releases to the Launchpad PPA - it stops at noble/24.04. From 26.04 onwards the
# packages live at packages.sury.org, which is where php8.6 comes from below.

# Install Apache, PHP, and supplementary programs
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install \
    software-properties-common lsb-release ca-certificates curl

# Add the deb.sury.org PHP repository (replaces add-apt-repository ppa:ondrej/php)
RUN curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
RUN dpkg -i /tmp/debsuryorg-archive-keyring.deb && rm /tmp/debsuryorg-archive-keyring.deb
RUN echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
RUN apt-get update

# php8.6 is a pre-release (currently 8.6.0~beta3). php8.6-xdebug is not built yet,
# so it is left out of this list - see the xdebug section below.
RUN apt-get -y install \
    apache2 php8.6 php8.6-mysql php8.6-cli php8.6-common php8.6-curl php8.6-gd php8.6-intl php8.6-ldap php8.6-mbstring \
    php8.6-readline libapache2-mod-php8.6 php8.6-xml php8.6-zip php8.6-dev php-pear \
    unixodbc-dev curl vim composer zip npm

# --- sqlsrv / pdo_sqlsrv -----------------------------------------------------
# COMMENTED OUT: the current pecl releases (sqlsrv 5.13.3) have not been built
# against PHP 8.6 yet and fail to compile. Uncomment once Microsoft ships a
# PHP 8.6 compatible release - same as we did during the PHP 8.5 pre-releases.
# RUN pecl install sqlsrv
# RUN pecl install pdo_sqlsrv
# RUN printf "; priority=20\nextension=sqlsrv.so\n" > /etc/php/8.6/mods-available/sqlsrv.ini
# RUN printf "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/8.6/mods-available/pdo_sqlsrv.ini

# The Microsoft ODBC driver itself is PHP independent and does have a 26.04 build,
# so it stays in - the sqlsrv PHP extensions above just cannot use it yet.
RUN curl -sSL -O https://packages.microsoft.com/config/ubuntu/$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2)/packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb
RUN apt-get update
RUN ACCEPT_EULA=Y apt-get install -y msodbcsql18

# Enable Apache mods
RUN a2enmod php8.6
RUN a2enmod rewrite
# COMMENTED OUT: re-enable together with the pecl installs above
# RUN phpenmod -v 8.6 sqlsrv pdo_sqlsrv

# Update PHP.ini file
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/8.6/apache2/php.ini
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ALL/" /etc/php/8.6/apache2/php.ini
RUN sed -i "s/display_errors = .*/display_errors = On/" /etc/php/8.6/apache2/php.ini
# Allow 20 MB uploads; post_max_size must stay above upload_max_filesize so the
# rest of the form still fits alongside the file
RUN sed -i "s/^upload_max_filesize = .*/upload_max_filesize = 20M/" /etc/php/8.6/apache2/php.ini
RUN sed -i "s/^post_max_size = .*/post_max_size = 25M/" /etc/php/8.6/apache2/php.ini

# Opcode cache for the command line, kept in files so it carries over between runs.
# On a Windows host the code is bind-mounted across the Windows-to-Linux filesystem
# boundary, where every file read is slow, and each CLI run (test runners, cron
# scripts) starts cold, reading and compiling every file again. The opcode cache is
# already on for Apache but off for the CLI by default. With a file cache each CLI run
# reuses what the last one compiled. Timestamps are still checked, so edits show up.
RUN printf "; priority=99\nopcache.enable_cli=1\nopcache.file_cache=/tmp/opcache\n" > /etc/php/8.6/cli/conf.d/99-opcache-cli.ini
RUN mkdir -p /tmp/opcache && chmod 1777 /tmp/opcache

# --- Xdebug ------------------------------------------------------------------
# COMMENTED OUT: there is no php8.6-xdebug package yet, and released Xdebug
# (3.5.x) refuses to build on PHP >= 8.6.0. Uncomment both blocks once
# php8.6-xdebug appears at packages.sury.org.
#
# Create the 20-xdebug.ini file with xdebug configuration
# RUN echo "zend_extension=xdebug.so\n\
# xdebug.start_with_request = yes\n\
# xdebug.mode = debug\n\
# xdebug.remote_handler = dbgp\n\
# xdebug.client_host = host.docker.internal\n\
# xdebug.log = /tmp/xdebug_remote.log\n\
# xdebug.client_port = 9003" \
# > /etc/php/8.6/apache2/conf.d/20-xdebug.ini

# Configure Apache Directory settings
RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/c\<Directory /var/www/html/>\n\
    Options Indexes FollowSymLinks MultiViews\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' /etc/apache2/apache2.conf

# Trust the git repositories under the mounted web root. On a Linux host the
# mounted files belong to the host user, not root, and git then refuses them as
# "dubious ownership" (e.g. git describe in a project's build script fails).
# Docker Desktop on Windows mounts them as root, where this changes nothing.
RUN git config --system --add safe.directory '/var/www/html/*'

# Set Apache environment variables
ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2
ENV APACHE_PID_FILE=/var/run/apache2.pid

# Expose ports for Apache
EXPOSE 80

# Start Apache in the foreground
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
