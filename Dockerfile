#
# PHP-FPM Dockerfile
#

# Pull base image.
FROM linxlad/nginx

MAINTAINER Nathan Daly <nathand@openobjects.com>

# No tty
ENV DEBIAN_FRONTEND noninteractive

RUN echo "deb http://ftp.us.debian.org/debian/ stretch main contrib non-free" >> /etc/apt/sources.list
RUN echo "deb-src http://ftp.us.debian.org/debian/ stretch main contrib non-free" >> /etc/apt/sources.list

RUN wget https://www.dotdeb.org/dotdeb.gpg && apt-key add dotdeb.gpg

RUN apt-get update && \
    apt-get -y install software-properties-common && \
    apt-get update

# Install PHP
RUN apt-get -y --force-yes install php7.0-cli php7.0-fpm php7.0-dev php7.0-mcrypt php7.0-mbstring \
    php7.0-bz2 php7.0-xml php7.0-common php7.0-mysql php7.0-intl php7.0-xdebug

# Phalcon
RUN curl -s "https://packagecloud.io/install/repositories/phalcon/stable/script.deb.sh" | bash && \
    apt-get update && \
    apt-get -y --force-yes install php7.0-phalcon

RUN echo "extension=phalcon.so" >> /etc/php/7.0/fpm/conf.d/40-phalcon.ini

RUN sed -i '/daemonize /c \
    daemonize = no' /etc/php/7.0/fpm/php-fpm.conf

# tweak php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.0/fpm/php.ini && \
    sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.0/fpm/php.ini && \
    sed -i -e "s/memory_limit = .*/memory_limit = 1024M/g" /etc/php/7.0/fpm/php.ini && \
    sed -i -e "s/memory_limit = .*/memory_limit = 1024M/g" /etc/php/7.0/cli/php.ini && \
    sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.0/fpm/php.ini && \
    sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf && \
    sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i -e "s/user = www-data/user = web/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i -e "s/group = www-data/group = staff/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    echo "date.timezone = \"Europe/London\"" >> /etc/php/7.0/fpm/php.ini

# fix ownership of sock file for php-fpm
RUN sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    find /etc/php/7.0/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

RUN sed -i '/^listen /c \
    listen = 9000' /etc/php/7.0/fpm/pool.d/www.conf

RUN sed -i 's/^listen.allowed_clients/;listen.allowed_clients/' /etc/php/7.0/fpm/pool.d/www.conf

RUN sed -i "s/xdebug\.remote_host\=.*/xdebug\.remote_host\=$XDEBUG_HOST/g" /etc/php/7.0/mods-available/xdebug.ini
RUN echo "#!/bin/bash\n/etc/init.d/php7.0-fpm start && nginx" >> /run.sh
RUN chmod a+x /run.sh

COPY xdebug.ini /etc/php/7.0/mods-available/xdebug.ini
COPY run.sh /run.sh
RUN chmod a+x /run.sh

EXPOSE 9000

VOLUME ["/etc/php-fpm.d", "/var/log/php-fpm", "/var/www/html"]

ENTRYPOINT ["/run.sh"]
