#!/bin/bash
set -ux

cd /var/lib/drupalci/workspace/drupal-checkouts/drupal$5
#COMPOSER_CACHE_DIR=/tmp/cache$5 composer config repositories.patch vcs https://github.com/greg-1-anderson/core-relaxed
#COMPOSER_CACHE_DIR=/tmp/cache$5 composer --no-interaction --no-progress require drupal/core-relaxed 8.8.x 2> /var/lib/drupalci/workspace/phpstan-results/$1.$3.phpstan_stderr
COMPOSER_CACHE_DIR=/tmp/cache$5 composer --no-interaction --no-progress require drupal/$2 $3 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.phpstan_stderr
php -d memory_limit=2G -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/phpstan analyse --no-progress --error-format checkstyle -c ./phpstan.neon  ./${4#project_}s/contrib/$2 > /var/lib/drupalci/workspace/phpstan-results/$1.$3.phpstan_results.xml 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.phpstan_stderr
git reset --hard HEAD
git clean -ffd
