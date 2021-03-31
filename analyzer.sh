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
COMPOSER_MEMORY_LIMIT=-1 COMPOSER_CACHE_DIR=/var/lib/drupalci/workspace/drupal-checkouts/cache$5 composer --no-interaction --no-progress require drupal/$2 $3 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.phpstan_stderr

# Ensure the directory was created where we thought it should be.
if [[ -d "/var/lib/drupalci/workspace/drupal-checkouts/drupal$5/${4#project_}s/contrib/$2" ]]; then

  php -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 -d upload_tmp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/drush --root=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 config-set system.file path.temporary /var/lib/drupalci/workspace/drupal-checkouts/drupal$5/sites/default/files/temp
  # Some projects have a different machine name than there composer project name.
  module_name=$(php -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 -d upload_tmp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/find_machinename "$6")

  php -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 -d upload_tmp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/drush --root=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 en $module_name -y
  php -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 -d upload_tmp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/drush --root=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 upgrade_status:checkstyle $module_name > /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.pre_rector.xml 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status_stderr1

  # Only run rector if we have some file messages in the XML.
  php -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 -d upload_tmp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/rector_needed /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.pre_rector.xml
  rector_needed_result=$?
  info_updatable_result=1
  # set this back to 0 when we figure what we need to do with rector
  if [ $rector_needed_result -eq 0 ]; then
    # Rename phpstan.neon because it is not needed for rector and causes some modules to fail.
    mv phpstan.neon phpstan.neon.hide
    # Create a git commit for the current state of the project
    gitCommit ${4#project_}s/contrib/$2
    create_patch=1
    php -d memory_limit=2G -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 -d upload_tmp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/rector process --verbose ${4#project_}s/contrib/$2 &>  /var/lib/drupalci/workspace/phpstan-results/$1.$3.rector_out 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.rector_stderr
    # Restore phpstan.neon
    mv phpstan.neon.hide phpstan.neon

    cd ${4#project_}s/contrib/$2
    if [ -z "$(git status --porcelain)" ]; then
      cd /var/lib/drupalci/workspace/drupal-checkouts/drupal$5
      # Working directory clean, rector didn't make any changes
      create_patch=0
      php -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 -d upload_tmp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/test_error $1.$3
      test_error_result=$?
      if [ $test_error_result -eq 0 ]; then
        # Run rector again but without tests.
        php -d memory_limit=2G -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 -d upload_tmp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/rector process --config rector-no-tests.yml --verbose ${4#project_}s/contrib/$2 &>  /var/lib/drupalci/workspace/phpstan-results/$1.$3.rector-no-tests_out 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.rector-no-tests_stderr
      fi
    fi

    cd ${4#project_}s/contrib/$2
    if [ -z "$(git status --porcelain)" ]; then
      cd /var/lib/drupalci/workspace/drupal-checkouts/drupal$5
    else
      cd /var/lib/drupalci/workspace/drupal-checkouts/drupal$5
      # Uncommitted changes
      create_patch=1
      # Check to see we can update the info file now.
      php -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 -d upload_tmp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/drush --root=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 upgrade_status:checkstyle  $module_name > /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.post_rector.xml 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status_stderr2
      php -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 -d upload_tmp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/info_updatable /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.post_rector.xml
      info_updatable_result=$?
    fi

  else
    php -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 -d upload_tmp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/info_updatable /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.pre_rector.xml
    info_updatable_result=$?
    if [ $info_updatable_result -eq 0 ]; then
      gitCommit ${4#project_}s/contrib/$2
    fi
  fi
  if [ $info_updatable_result -eq 0 ]; then
      php -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 -d upload_tmp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 ./vendor/bin/update_info /var/lib/drupalci/workspace/drupal-checkouts/drupal$5/${4#project_}s/contrib/$2/$module_name.info.yml $1.$3
      create_patch=1
  fi

  if [ $create_patch -eq 1 ]; then
    cd ${4#project_}s/contrib/$2
    php -d sys_temp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 -d upload_tmp_dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$5 /var/lib/drupalci/workspace/drupal-checkouts/drupal$5/vendor/bin/restore_nonrector_changes /var/lib/drupalci/workspace/drupal-checkouts/drupal$5/${4#project_}s/contrib/$2

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
