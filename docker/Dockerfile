FROM php:7.3.27-apache-buster

ARG DRUPAL_CORE_VERSION="8.9.x"
ARG DRUSH_VERSION="9.7.2"
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod uga+x /usr/local/bin/install-php-extensions && sync && \
     install-php-extensions gd zip

RUN apt-get -qq update && apt-get -qq install -y --no-install-recommends \
    git \
    sqlite3 \
    sudo \
    curl \
    zip \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir --parents /var/lib/drupalci/workspace/phpstan-results \
    && chmod -R 777 /var/lib/drupalci/workspace \
    && mkdir --parents /var/lib/drupalci/workspace/drupal-checkouts \
    && curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
    && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
    && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
    && php /tmp/composer-setup.php --filename composer --install-dir /usr/local/bin \
    && git clone https://git.drupalcode.org/project/infrastructure.git /var/lib/drupalci/workspace/infrastructure \
    && git clone -b ${DRUPAL_CORE_VERSION} https://git.drupalcode.org/project/drupal.git /var/lib/drupalci/drupal-checkout \
    && sudo dpkg -i /var/lib/drupalci/workspace/infrastructure/stats/project_analysis/parallel_20190622_all.deb \
    && git config --global user.email "git@drupal.org" \
    && git config --global user.name "Drupalci Testbot" \
    && composer --quiet --working-dir=/var/lib/drupalci/drupal-checkout require palantirnet/drupal-rector:0.5.6 --dev \
    && composer --quiet --working-dir=/var/lib/drupalci/drupal-checkout require drupal/upgrade_status:~3.5 \
    && composer config --working-dir=/var/lib/drupalci/drupal-checkout repositories.local '{"type": "path", "url": "/var/lib/drupalci/workspace/infrastructure/stats/project_analysis/project_analysis_utils", "options": { "symlink": false}}' \
    && composer --quiet --working-dir=/var/lib/drupalci/drupal-checkout require drupalorg_infrastructure/project_analysis_utils --no-progress \
    && composer --quiet --working-dir=/var/lib/drupalci/drupal-checkout require drush/drush:${DRUSH_VERSION} --no-progress \
    && sudo chmod 777 /var/lib/drupalci/drupal-checkout/sites/default \
    && /var/lib/drupalci/drupal-checkout/vendor/bin/drush -r /var/lib/drupalci/drupal-checkout si --db-url=sqlite://sites/default/files/.ht.sqlite -y \
    && /var/lib/drupalci/drupal-checkout/vendor/bin/drush -r /var/lib/drupalci/drupal-checkout en upgrade_status -y \
    && git -C /var/lib/drupalci/drupal-checkout add sites/default/files/.ht.sqlite \
    && find /var/lib/drupalci/drupal-checkout/vendor -name .git -exec rm -rf {} \; \
    || true

COPY ./files/phpstan.neon /var/lib/drupalci/drupal-checkout/phpstan.neon
COPY ./files/rector.yml /var/lib/drupalci/drupal-checkout/rector.yml
COPY ./files/rector-no-tests.yml /var/lib/drupalci/drupal-checkout/rector-no-tests.yml
COPY ./files/memory.ini /usr/local/etc/php/conf.d/memory.ini

RUN git -C /var/lib/drupalci/drupal-checkout add . \
    && git -C /var/lib/drupalci/drupal-checkout commit -q -m "adds phpstan and drupal-rector and sqlite" \
    && cp /var/lib/drupalci/drupal-checkout/composer.lock /var/lib/drupalci/workspace/phpstan-results/drupal-composer.lock.json
