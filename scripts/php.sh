#!/usr/bin/env bash

export LANG=C.UTF-8

PHP_TIMEZONE=$1
HHVM=$2
PHP_VERSION=$3

if [[ $HHVM == "true" ]]; then

    echo ">>> Installing HHVM"

    # Get key and add to sources
    wget --quiet -O - http://dl.hhvm.com/conf/hhvm.gpg.key | sudo apt-key add -
    echo deb http://dl.hhvm.com/ubuntu trusty main | sudo tee /etc/apt/sources.list.d/hhvm.list

    # Update
    sudo apt-get update

    # Install HHVM
    # -qq implies -y --force-yes
    sudo apt-get install -qq hhvm

    # Start on system boot
    sudo update-rc.d hhvm defaults

    # Replace PHP with HHVM via symlinking
    sudo /usr/bin/update-alternatives --install /usr/bin/php php /usr/bin/hhvm 60

    sudo service hhvm restart
else
    echo ">>> Installing PHP $PHP_VERSION"

    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C

    if [ $PHP_VERSION == "5.5" ]; then
        # Add repo for PHP 5.5
        sudo add-apt-repository -y ppa:ondrej/php5
    else
        # Add repo for PHP 5.6
        sudo add-apt-repository -y ppa:ondrej/php5-5.6
    fi

    sudo apt-key update
    sudo apt-get update

# Install PHP
    # -qq implies -y --force-yes
    if [ $PHP_VERSION == "5.3" ]; then
        echo ">>>>>> Dependencies to PHP $PHP_VERSION"
        sudo apt-get -qq install synaptic libxml2-dev libcurl4-openssl-dev pkg-config. libpng-dev libt1-dev libmcrypt-dev libmysqlclient-dev libjpeg-dev libpcre3 libpcre3-dev libbz2-dev libminiupnpc-dev libgdbm-dev libdb-dev libgd2-xpm-dev libgmp-dev unixodbc-dev freetds-dev libpq-dev libpspell-dev libsnmp-dev libtidy-dev  libxslt-dev bison re2c php-pear

        # Fix to freetype.h
        echo ">>>>>> Link to freetype"
        sudo mkdir -p /usr/include/freetype2/freetype
        sudo ln -s /usr/include/freetype2/freetype.h /usr/include/freetype2/freetype/freetype.h
        #sudo ln -s /usr/include/freetype2 /usr/include/freetype2/freetype

        echo ">>>>>> Link to gmp.h"
        sudo sudo ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h

        # DOWNLOAD PHP
        # wget -O /var/tmp/php-5.3.29.tar.gz  http://br1.php.net/distributions/php-5.3.29.tar.gz
        echo ">>>>>> Download PHP $PHP_VERSION"
        wget -O /var/tmp/php-${PHP_VERSION}.29.tar.gz  http://br1.php.net/distributions/php-${PHP_VERSION}.29.tar.gz

        # Extract PHP sources
        echo ">>>>>> Extract sources of PHP $PHP_VERSION"
        sudo mkdir -p /opt/build
        sudo tar -zxvf /var/tmp/php-${PHP_VERSION}.29.tar.gz -C /opt/build
        cd /opt/build/php-${PHP_VERSION}.29

        echo ">>>>>> Configuring PHP $PHP_VERSION"
        sudo ./configure \
                            --with-apxs2=/usr/bin/apxs2 \
                            --with-curl \
                            --with-gd \
                            --with-mcrypt \
                            --with-mhash \
                            --with-mysql \
                            --with-pdo-mysql \
                            --with-snmp \
                            --enable-soap \
                            --with-openssl \
                            --with-xsl \
                            --with-config-file-path=/etc/php5 \
                            --enable-bcmath \
                            --with-zlib \
                            --enable-sysvsem \
                            --with-gd \
                            --with-jpeg-dir=/usr/lib \
                            --with-png-dir=/usr/lib \
                            --with-readline \
                            --enable-mbstring \
                            --enable-intl \
                            --prefix=/opt/php-5.3.10


        # Install PHP
        echo ">>>>>> Making PHP $PHP_VERSION"
        sudo make

        #sudo make test
        echo ">>>>>> Installing PHP $PHP_VERSION"
        sudo make -i install

        echo ">>>>>> Go to ~"
        cd ~

        # Create an php-cli
        echo ">>>>>> Copy of php.ini-development to /usr/local/lib/php.ini"
        sudo cp /opt/build/php-${PHP_VERSION}.29/php.ini-development /usr/local/lib/php.ini

#        echo ">>>>>> Installing PHP-FPM"
#        sudo apt-get -y install php5-fpm


    else
        # Install default versions to repositori from ondrej
        sudo apt-get install -qq php5-cli php5-fpm php5-mysql php5-pgsql php5-sqlite php5-curl php5-gd php5-gmp php5-mcrypt php5-memcached php5-imagick php5-intl php5-xdebug
    fi

    # Set PHP FPM to listen on TCP instead of Socket
    sudo sed -i "s/listen =.*/listen = 127.0.0.1:9000/" /etc/php5/fpm/pool.d/www.conf

    # Set PHP FPM allowed clients IP address
    sudo sed -i "s/;listen.allowed_clients/listen.allowed_clients/" /etc/php5/fpm/pool.d/www.conf

    # Set run-as user for PHP5-FPM processes to user/group "vagrant"
    # to avoid permission errors from apps writing to files
    sudo sed -i "s/user = www-data/user = vagrant/" /etc/php5/fpm/pool.d/www.conf
    sudo sed -i "s/group = www-data/group = vagrant/" /etc/php5/fpm/pool.d/www.conf

    sudo sed -i "s/listen\.owner.*/listen.owner = vagrant/" /etc/php5/fpm/pool.d/www.conf
    sudo sed -i "s/listen\.group.*/listen.group = vagrant/" /etc/php5/fpm/pool.d/www.conf
    sudo sed -i "s/listen\.mode.*/listen.mode = 0666/" /etc/php5/fpm/pool.d/www.conf


    # xdebug Config
    cat > $(find /etc/php5 -name xdebug.ini) << EOF
zend_extension=$(find /usr/lib/php5 -name xdebug.so)
xdebug.remote_enable = 1
xdebug.remote_connect_back = 1
xdebug.remote_port = 9000
xdebug.scream=0
xdebug.cli_color=1
xdebug.show_local_vars=1

; var_dump display
xdebug.var_display_max_depth = 5
xdebug.var_display_max_children = 256
xdebug.var_display_max_data = 1024
EOF

    # PHP Error Reporting Config
    sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/fpm/php.ini
    sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/fpm/php.ini

    # PHP Date Timezone
    sudo sed -i "s/;date.timezone =.*/date.timezone = ${PHP_TIMEZONE/\//\\/}/" /etc/php5/fpm/php.ini
    sudo sed -i "s/;date.timezone =.*/date.timezone = ${PHP_TIMEZONE/\//\\/}/" /etc/php5/cli/php.ini

    sudo service php5-fpm restart
fi
