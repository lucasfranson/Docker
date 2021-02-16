FROM php:7.4-apache

RUN apt update
RUN apt upgrade -y
RUN apt install -y apt-utils \
 apt-transport-https \
 curl \
 iputils-ping \
 less \
 nano \
 netcat \
 bison \
 exif \
 freetds-dev \
 gnupg \
 icu-doc \
 libbz2-dev \
 libcurl4 \
 libcurl3-dev \
 libdmalloc-dev \
 libfreetype6-dev \
 libjpeg-dev \
 libldb-dev \
 libldap2-dev \
 libpng-dev \
 libicu-dev \
 libmcrypt-dev \
 libpng++-dev \
 libsnmp-dev \
 libsqlite3-0 \
 libsqlite3-dev \
 sqlite3-doc \
 libssl-dev \
 libtidy-dev \
 libxml2-dev \
 libxpm-dev \
 libxslt1-dev \
 libzip-dev \
 mcrypt \
 openssl \
 snmp \
 unixodbc \
 unixodbc-dev \
 unzip \
 wget

RUN echo /usr/lib/x86_64-linux-gnu >> /etc/ld.so.conf && \
 echo /usr/local/lib64 >> /etc/ld.so.conf && \
 echo /usr/local/lib >> /etc/ld.so.conf && \
 echo /usr/lib >> /etc/ld.so.conf && \
 echo /usr/lib64 >> /etc/ld.so.conf && \
 ldconfig

# modules stuff
#RUN pecl install xdebug-2.9.0 && \
# docker-php-ext-enable xdebug
RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu && \
 docker-php-ext-install ldap
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
 docker-php-ext-install -j$(nproc) gd

RUN docker-php-ext-install mysqli
RUN docker-php-ext-install pdo_mysql


RUN pecl install sqlsrv pdo_sqlsrv
RUN docker-php-ext-enable sqlsrv pdo_sqlsrv

RUN apache2ctl -k stop && \
 a2dismod mpm_event && \
 a2enmod mpm_prefork rewrite ssl headers

RUN docker-php-ext-install -j$(nproc) intl
RUN docker-php-ext-install snmp bcmath bz2 calendar exif opcache pcntl soap sockets tidy xmlrpc xsl zip

#WORKDIR /usr/local/etc/php/conf.d
#RUN echo "xdebug.default_enable=1" >> docker-php-ext-xdebug.ini && \
# echo "xdebug.remote_enable=1" >> docker-php-ext-xdebug.ini && \
# echo "xdebug.remote_autostart=1" >> docker-php-ext-xdebug.ini && \
# echo "xdebug.remote_connect_back=0" >> docker-php-ext-xdebug.ini && \
# echo "xdebug.remote_port=9001" >> docker-php-ext-xdebug.ini && \
# echo "xdebug.remote_host=host.docker.internal" >> docker-php-ext-xdebug.ini && \
# echo "xdebug.idekey=PHPSTORM" >> docker-php-ext-xdebug.ini && \
# echo "xdebug.remote_log=/www/xdebug_log" >> docker-php-ext-xdebug.ini && \
# echo "xdebug.remote_log_level=7" >> docker-php-ext-xdebug.ini

#composer config
WORKDIR /root
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
 php -r "if (hash_file('sha384', 'composer-setup.php') === '756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
 php composer-setup.php && \
 php -r "unlink('composer-setup.php');" && \
 mv composer.phar /usr/local/bin/composer && \
 composer selfupdate

# directory config
WORKDIR /var/log
RUN mkdir httpd
WORKDIR /var/log/httpd
RUN touch access_log.sample_80 && \
 touch error_log.sample_80
WORKDIR /var/log
RUN chown www-data:www-data -R httpd/
WORKDIR /var/www
RUN mkdir sample
WORKDIR /var/www/sample
RUN mkdir public
WORKDIR /var/www
RUN chown www-data:www-data -R sample/

# servicebus config
COPY apache-sample.conf /etc/apache2/sites-available/sample.conf

RUN a2ensite sample

# add 9001/tcp for xdebug
EXPOSE 80/tcp

ENTRYPOINT ["apache2ctl", "-D", "FOREGROUND"]
