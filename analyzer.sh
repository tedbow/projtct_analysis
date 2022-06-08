#!/bin/bash
set -uxv

# Arguments are
# 1: project name, 2: composer name, 3: release version,
# 4: type of extension, 5: number of workspace, 6: concatenated component composer requirements

function gitCommit() {
  cd $1
  git init
  git add .;git commit -q -m "git project before rector"
  cd -
}
create_patch=0

CHECKOUT_DIR="/var/lib/drupalci/workspace/drupal-checkouts/drupal$5"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


# Add the requested project to this composer environment ($5 is the number of this workspace, $1 is project name, $2 is the composer name and $3 is the version).
cd $CHECKOUT_DIR
COMPOSER_MEMORY_LIMIT=-1 COMPOSER_CACHE_DIR=/var/lib/drupalci/workspace/drupal-checkouts/cache$5 composer --no-interaction --no-progress require drupal/$2 $3 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.phpstan_stderr

# Ensure the directory was created where we thought it should be based on the project machine name.
if [[ -d "$CHECKOUT_DIR/${4#project_}s/contrib/$2" ]]; then

  # Set file paths relative to our workspace, so they don't mix up between workspaces.
  php -d sys_temp_dir=$CHECKOUT_DIR -d upload_tmp_dir=$CHECKOUT_DIR ./vendor/bin/drush --root=$CHECKOUT_DIR config-set system.file path.temporary $CHECKOUT_DIR/sites/default/files/temp

  # Some projects have a different machine name than their composer project name. ($6 is the composer metadata)
  module_name=$(php -d sys_temp_dir=$CHECKOUT_DIR -d upload_tmp_dir=$CHECKOUT_DIR ./vendor/bin/find_machinename "$6")

  # Enable the module based on the machine name.
  php -d sys_temp_dir=$CHECKOUT_DIR -d upload_tmp_dir=$CHECKOUT_DIR ./vendor/bin/drush --root=$CHECKOUT_DIR en $module_name -y

  # Run Upgrade Status to get a baseline of results of current status.
  php -d sys_temp_dir=$CHECKOUT_DIR -d upload_tmp_dir=$CHECKOUT_DIR ./vendor/bin/drush --root=$CHECKOUT_DIR upgrade_status:checkstyle $module_name > /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.pre_rector.xml 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status_stderr1

  # Check if we need to run rector based on results from Upgrade Status.
  php -d sys_temp_dir=$CHECKOUT_DIR -d upload_tmp_dir=$CHECKOUT_DIR ./vendor/bin/rector_needed /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.pre_rector.xml
  rector_needed_result=$?
  info_updatable_result=1
  composer_json_updatable_result=1

  # set this back to 0 when we figure what we need to do with rector
  if [ $rector_needed_result -eq 0 ]; then
    # Create a git commit for the current state of the project, so we can diff clearly later.
    gitCommit ${4#project_}s/contrib/$2
    create_patch=1
    # Run rector to see if we can fix anything automatically.
    php -d memory_limit=2G -d sys_temp_dir=$CHECKOUT_DIR -d upload_tmp_dir=$CHECKOUT_DIR ./vendor/bin/rector process --verbose ${4#project_}s/contrib/$2 &>  /var/lib/drupalci/workspace/phpstan-results/$1.$3.rector_out 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.rector_stderr

    # Disabled for now given the PHP based rector config.
    #cd ${4#project_}s/contrib/$2
    #if [ -z "$(git status --porcelain)" ]; then
    #  cd $CHECKOUT_DIR
    #  create_patch=0
    #  php -d sys_temp_dir=$CHECKOUT_DIR -d upload_tmp_dir=$CHECKOUT_DIR ./vendor/bin/test_error $1.$3
    #  test_error_result=$?
    #  if [ $test_error_result -eq 0 ]; then
    #    # Run rector again but without tests, since that failed.
    #    php -d memory_limit=2G -d sys_temp_dir=$CHECKOUT_DIR -d upload_tmp_dir=$CHECKOUT_DIR ./vendor/bin/rector process --config rector-no-tests.yml --verbose ${4#project_}s/contrib/$2 &>  /var/lib/drupalci/workspace/phpstan-results/$1.$3.rector-no-tests_out 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.rector-no-tests_stderr
    #  fi
    #fi

    # Check if rector made any changes.
    cd ${4#project_}s/contrib/$2
    if [ -z "$(git status --porcelain)" ]; then
      cd $CHECKOUT_DIR
    else
      # Found uncommitted changes, so we will create a patch!
      cd $CHECKOUT_DIR
      create_patch=1
      # Run Upgrade Status again to see what remained after running rector.
      php -d sys_temp_dir=$CHECKOUT_DIR -d upload_tmp_dir=$CHECKOUT_DIR ./vendor/bin/drush --root=$CHECKOUT_DIR upgrade_status:checkstyle  $module_name > /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.post_rector.xml 2>> /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status_stderr2
      # Check if the info file is updateable (only the info file error is left).
      php -d sys_temp_dir=$CHECKOUT_DIR -d upload_tmp_dir=$CHECKOUT_DIR ./vendor/bin/info_updatable /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.post_rector.xml
      info_updatable_result=$?

      # Check if the composer.json is updateable (only the info file error is left).
      php -d sys_temp_dir=$CHECKOUT_DIR -d upload_tmp_dir=$CHECKOUT_DIR ./vendor/bin/composer_json_updatable /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.post_rector.xml
      composer_json_updatable_result=$?
    fi

  else
    # Rector was not needed, but we may still be able to fix the info file.
    php -d sys_temp_dir=$CHECKOUT_DIR -d upload_tmp_dir=$CHECKOUT_DIR ./vendor/bin/info_updatable /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.pre_rector.xml
    info_updatable_result=$?
    if [ $info_updatable_result -eq 0 ]; then
      # Make sure to have a clean state for diffing later.
      gitCommit ${4#project_}s/contrib/$2
    fi

    # Check if the composer.json is updateable (only the info file error is left).
    php -d sys_temp_dir=$CHECKOUT_DIR -d upload_tmp_dir=$CHECKOUT_DIR ./vendor/bin/composer_json_updatable /var/lib/drupalci/workspace/phpstan-results/$1.$3.upgrade_status.pre_rector.xml
    composer_json_updatable_result=$?

    if [ $composer_json_updatable_result -eq 0 ]; then
      # Make sure to have a clean state for diffing later.
      gitCommit ${4#project_}s/contrib/$2
    fi
  fi

  if [ $info_updatable_result -eq 0 ]; then
      # We decided the info file should be updated, so update it now.
      php -d sys_temp_dir=$CHECKOUT_DIR -d upload_tmp_dir=$CHECKOUT_DIR ./vendor/bin/update_info $CHECKOUT_DIR/${4#project_}s/contrib/$2/$module_name.info.yml $1.$3
      create_patch=1
  fi

  if [ $composer_json_updatable_result -eq 0 ]; then
      # We decided the info file should be updated, so update it now.
      php -d sys_temp_dir=$CHECKOUT_DIR -d upload_tmp_dir=$CHECKOUT_DIR ./vendor/bin/update_composer_json $CHECKOUT_DIR/${4#project_}s/contrib/$2/composer.json $1.$3
      create_patch=1
  fi

  if [ $create_patch -eq 1 ]; then
    cd ${4#project_}s/contrib/$2
    # Undo some unrelated changes that rector used to make. We may not need this anymore.
    # php -d sys_temp_dir=$CHECKOUT_DIR -d upload_tmp_dir=$CHECKOUT_DIR $CHECKOUT_DIR/vendor/bin/restore_nonrector_changes $CHECKOUT_DIR/${4#project_}s/contrib/$2

    git log > /var/lib/drupalci/workspace/phpstan-results/$1.$3.git_log.txt
    git status > /var/lib/drupalci/workspace/phpstan-results/$1.$3.git_status.txt

    # CREATE THE PATCH!
    git diff > /var/lib/drupalci/workspace/phpstan-results/$1.$3.rector.patch

    # Delete the file if it is empty.
    find /var/lib/drupalci/workspace/phpstan-results/$1.$3.rector.patch -size  0 -print -delete

    cd $CHECKOUT_DIR
  fi

fi

# Clean up this workspace for the next project.
git reset --hard HEAD
sudo git clean -ffd
