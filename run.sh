#!/bin/bash
sed -i "s/xdebug\.remote_host\=.*/xdebug\.remote_host\=$XDEBUG_HOST/g" /etc/php/7.2/mods-available/xdebug.ini
/etc/init.d/php7.2-fpm start && nginx