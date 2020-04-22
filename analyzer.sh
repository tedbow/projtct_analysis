#!/bin/bash
set -ux

cd /var/lib/drupalci/workspace/drupal-checkouts/drupal$5
#COMPOSER_CACHE_DIR=/tmp/cache$5 composer config repositories.patch vcs https://github.com/greg-1-anderson/core-relaxed
#COMPOSER_CACHE_DIR=/tmp/cache$5 composer --no-interaction --no-progress require drupal/core-relaxed 8.8.x 2> /var/lib/drupalci/workspace/phpstan-results/$1.$3.phpstan_stderr
COMPOSER_CACHE_DIR=/tmp/cache$5 composer --no-interaction --no-progress require drupal/$2 $3 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.phpstan_stderr
php -d memory_limit=2G -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/phpstan analyse --no-progress --error-format checkstyle -c ./phpstan.neon  ./${4#project_}s/contrib/$2 > /var/lib/drupalci/workspace/phpstan-results/$1.$3.phpstan_results.xml 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.phpstan_stderr

# Only run rector if we have some file messages in the XML.
if grep -q '<file name' /var/lib/drupalci/workspace/phpstan-results/$1.$3.phpstan_results.xml; then
  # Create a git commit for the current state of the project
  cd ${4#project_}s/contrib/$2
  git init
  git add .;git commit -q -m "git project before rector"
  cd /var/lib/drupalci/workspace/drupal-checkouts/drupal$5
  php -d memory_limit=2G -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/rector process ${4#project_}s/contrib/$2
  cd ${4#project_}s/contrib/$2
  git diff > /var/lib/drupalci/workspace/phpstan-results/$1.$3.rector.patch
  # Delete the file if it is empty.
  find /var/lib/drupalci/workspace/phpstan-results/$1.$3.rector.patch -size  0 -print -delete
fi

git reset --hard HEAD
git clean -ffd
