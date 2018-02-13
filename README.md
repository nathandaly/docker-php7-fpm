# PHP-FPM 7.2 Dockerfile

## Build image

    docker build -t php7-fpm .

## Usage

    docker run /
        -d /
        -p 8080:80 /
        -v <CONF_DIR>:/etc/php-fpm.d /
        -v <LOGS_DIR>:/var/log/php-fpm /
        -v <APP_DIR>:/var/www/html /
      	php7-fpm
