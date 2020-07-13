# Install php 7.2
sudo apt-get remove php* -y
sudo rm -r /var/lib/apt/lists/*
# sudo rm /etc/apt/trusted.gpg.d/php.gpg
sudo curl -s -o /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
sudo curl -s -o /etc/apt/trusted.gpg.d/yarn.gpg https://dl.yarnpkg.com/debian/pubkey.gpg
sudo apt-get update


sudo apt-get -qq --fix-missing install php7.2 \
                   php7.2-bcmath \
                   php7.2-cli \
                   php7.2-curl \
                   php7.2-dev \
                   php7.2-gd \
                   php7.2-intl \
                   php7.2-mbstring \
                   php7.2-mysql \
                   php7.2-pgsql \
                   php7.2-sqlite3 \
                   php7.2-xml \
                   php7.2-zip \
                   php-xdebug \
                   php-pear
