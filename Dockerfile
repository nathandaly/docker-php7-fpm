#
# PHP-FPM Dockerfile
#

# Pull base image.
FROM linxlad/nginx

MAINTAINER Nathan Daly <nathand@openobjects.com>

# No tty
ENV DEBIAN_FRONTEND noninteractive

RUN add-apt-repository ppa:ondrej/php && apt-get update && \
    apt-get -y install software-properties-common && \
    apt-get update

RUN apt-cache search php7

# Install PHP
RUN apt-get -y --force-yes install php7.2-cli php7.2-fpm php7.2-dev php7.2-mcrypt php7.2-mbstring \
    php7.2-bz2 php7.2-xml php7.2-common php7.2-mysql php7.2-intl php-pear

# Phalcon
RUN curl -s "https://packagecloud.io/install/repositories/phalcon/stable/script.deb.sh" | bash && \
    apt-get update && \
    apt-get -y --force-yes install php7.2-phalcon

RUN echo "extension=phalcon.so" >> /etc/php/7.2/fpm/conf.d/40-phalcon.ini

# Install xdebug
#RUN pecl install xdebug
#
#RUN echo "zend_extension=xdebug.so" >> /etc/php/7.2/fpm/conf.d/40-xdebug.ini \
#RUN echo "xdebug.remote_enable=1" >> /etc/php/7.2/fpm/conf.d/40-xdebug.ini \
#RUN echo "xdebug.remote_host=localhost" >> /etc/php/7.2/fpm/conf.d/40-xdebug.ini \
#RUN echo "xdebug.remote_port=9108" >> /etc/php/7.2/fpm/conf.d/40-xdebug.ini \
#RUN echo "xdebug.remote_handler=\"dbgp\"" >> /etc/php/7.2/fpm/conf.d/40-xdebug.ini \
#RUN echo "xdebug.remote_connect_back=1" >> /etc/php/7.2/fpm/conf.d/40-xdebug.ini

RUN sed -i '/daemonize /c \
    daemonize = no' /etc/php/7.2/fpm/php-fpm.conf

# tweak php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.2/fpm/php.ini && \
    sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.2/fpm/php.ini && \
    sed -i -e "s/memory_limit = .*/memory_limit = 1024M/g" /etc/php/7.2/fpm/php.ini && \
    sed -i -e "s/memory_limit = .*/memory_limit = 1024M/g" /etc/php/7.2/cli/php.ini && \
    sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.2/fpm/php.ini && \
    sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.2/fpm/php-fpm.conf && \
    sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.2/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.2/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.2/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.2/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.2/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.2/fpm/pool.d/www.conf && \
    sed -i -e "s/user = www-data/user = web/g" /etc/php/7.2/fpm/pool.d/www.conf && \
    sed -i -e "s/group = www-data/group = staff/g" /etc/php/7.2/fpm/pool.d/www.conf && \
    echo "date.timezone = \"Europe/London\"" >> /etc/php/7.2/fpm/php.ini

# fix ownership of sock file for php-fpm
RUN sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.2/fpm/pool.d/www.conf && \
    find /etc/php/7.2/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

RUN sed -i '/^listen /c \
    listen = 9000' /etc/php/7.2/fpm/pool.d/www.conf

RUN sed -i 's/^listen.allowed_clients/;listen.allowed_clients/' /etc/php/7.2/fpm/pool.d/www.conf
RUN echo "#!/bin/bash\n/etc/init.d/php7.2-fpm start && nginx" >> /run.sh
RUN chmod a+x /run.sh

EXPOSE 9000

VOLUME ["/etc/php-fpm.d", "/var/log/php-fpm", "/var/www/html"]

ENTRYPOINT ["/run.sh"]
