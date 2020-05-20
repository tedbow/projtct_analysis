#!/bin/bash
set -ux
function gitCommit() {
  cd $1
  git init
  git add .;git commit -q -m "git project before rector"
  cd -
}
create_patch=0

cd /var/lib/drupalci/workspace/drupal-checkouts/drupal$5
#COMPOSER_CACHE_DIR=/tmp/cache$5 composer config repositories.patch vcs https://github.com/greg-1-anderson/core-relaxed
#COMPOSER_CACHE_DIR=/tmp/cache$5 composer --no-interaction --no-progress require drupal/core-relaxed 8.8.x 2> /var/lib/drupalci/workspace/phpstan-results/$1.$3.phpstan_stderr
COMPOSER_CACHE_DIR=/tmp/cache$5 composer --no-interaction --no-progress require drupal/$2 $3 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.phpstan_stderr

# Ensure the directory was created where we thought it should be.
if [[ -d "/var/lib/drupalci/workspace/drupal-checkouts/drupal$5/${4#project_}s/contrib/$2" ]]; then

  sudo ~/.composer/vendor/bin/drush en $2 -y
  sudo ~/.composer/vendor/bin/drush upgrade_status:checkstyle  $2 > /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.pre_rector.xml 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status_stderr

  # Only run rector if we have some file messages in the XML.
  php -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/rector_needed /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.pre_rector.xml
  rector_needed_result=$?
  if [ $rector_needed_result -eq 0 ]; then
    # Rename phpstan.neon because it is not needed for rector and causes some modules to fail.
    mv phpstan.neon phpstan.neon.hide
    # Create a git commit for the current state of the project
    gitCommit ${4#project_}s/contrib/$2
    create_patch=1
    php -d memory_limit=2G -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/rector process --verbose ${4#project_}s/contrib/$2 &>  /var/lib/drupalci/workspace/phpstan-results/$1.$3.rector_out
    # Restore phpstan.neon
    mv phpstan.neon.hide phpstan.neon

    # Check to see we can update the info file.
    sudo ~/.composer/vendor/bin/drush upgrade_status:checkstyle  $2 > /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.post_rector.xml 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status_stderr
    php -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/info_updatable /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.post_rector.xml
    info_updatable_result=$?
  else
    php -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 /vendor/bin/info_updatable /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.pre_rector.xml
    info_updatable_result=$?
    if [ $info_updatable_result -eq 0 ]; then
      gitCommit ${4#project_}s/contrib/$2
    fi
  fi
  if [ $info_updatable_result -eq 0 ]; then
      php -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/update_info /var/lib/drupalci/workspace/drupal-checkouts/drupal$5/${4#project_}s/contrib/$2/$2.info.yml
      create_patch=1
  fi

  if [ $create_patch -eq 1 ]; then
    cd ${4#project_}s/contrib/$2
    php -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 /var/lib/drupalci/workspace/drupal-checkouts/drupal$5/vendor/bin/restore_nonrector_changes /var/lib/drupalci/workspace/drupal-checkouts/drupal$5/${4#project_}s/contrib/$2

    # git log > /var/lib/drupalci/workspace/phpstan-results/$1.$3.git_log.txt
    # git status > /var/lib/drupalci/workspace/phpstan-results/$1.$3.git_status.txt
    git diff > /var/lib/drupalci/workspace/phpstan-results/$1.$3.rector.patch
    # Delete the file if it is empty.
    find /var/lib/drupalci/workspace/phpstan-results/$1.$3.rector.patch -size  0 -print -delete

    cd /var/lib/drupalci/workspace/drupal-checkouts/drupal$5
  fi

fi

git reset --hard HEAD
sudo git clean -ffd
