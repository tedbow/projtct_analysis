#!/bin/bash
set -eu

echo "Updating container libs and repositories"
# @todo remove this when the container is built again
sudo apt-get -qq update
sudo apt-get -qq install -y unzip time
sudo composer self-update

# This file is intended to be executed on the testbot docker container.
export PHPSTAN_RESULT_DIR="/var/lib/drupalci/workspace/phpstan-results"

# This rector.php is needed so autoloading doesnt break
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cp $SCRIPT_DIR/rector.php /var/lib/drupalci/drupal-checkout
git -C /var/lib/drupalci/drupal-checkout add .
git -C /var/lib/drupalci/drupal-checkout commit -q -m "Add new rector.php configuration"

# Prepare debug patch
composer --working-dir=/var/lib/drupalci/drupal-checkout config --no-plugins allow-plugins.cweagans/composer-patches true
composer --working-dir=/var/lib/drupalci/drupal-checkout require cweagans/composer-patches --no-interaction --no-progress
cp $SCRIPT_DIR/patches.json /var/lib/drupalci/drupal-checkout
cp $SCRIPT_DIR/upgrade_status_debug.patch /var/lib/drupalci/drupal-checkout
composer --working-dir=/var/lib/drupalci/drupal-checkout config extra.patches-file "./patches.json"
git -C /var/lib/drupalci/drupal-checkout add .
git -C /var/lib/drupalci/drupal-checkout commit -q -m "More debug information"

# Require both libraries so composer figures out what the max version it can support. There is overlap in dependencies which makes this a puzzle.
composer --working-dir=/var/lib/drupalci/drupal-checkout remove palantirnet/drupal-rector --dev --no-update
composer --working-dir=/var/lib/drupalci/drupal-checkout require drupal/upgrade_status palantirnet/drupal-rector -w --no-interaction
git -C /var/lib/drupalci/drupal-checkout add .
git -C /var/lib/drupalci/drupal-checkout commit -q -m "Update drupal-rector and upgrade_status library"

# Update the drupal-composer.lock.json
cp /var/lib/drupalci/drupal-checkout/composer.lock /var/lib/drupalci/workspace/phpstan-results/drupal-composer.lock.json

composer --working-dir=/var/lib/drupalci/drupal-checkout remove drupalorg_infrastructure/project_analysis_utils
composer --working-dir=/var/lib/drupalci/drupal-checkout require drupalorg_infrastructure/project_analysis_utils
git -C /var/lib/drupalci/drupal-checkout add .
git -C /var/lib/drupalci/drupal-checkout commit -q -m "Update project analysis internal library"

composer --working-dir=/var/lib/drupalci/drupal-checkout config prefer-stable false
git -C /var/lib/drupalci/drupal-checkout add .
git -C /var/lib/drupalci/drupal-checkout commit -q -m "Don't prefer stable here"

# Set up as many workspaces for running phpstan as many processor cores we have.
PROC_COUNT=2
echo "Preparing ${PROC_COUNT} workspaces"
parallel /var/lib/drupalci/workspace/infrastructure/stats/project_analysis/prepare_workspace.sh {} ::: $(seq -s' ' 1 ${PROC_COUNT})

# Run the analyzers in parallel in each workspace we created.
# 1/2/3/4/8 correspond to the columns in the project listing file which should take the
# following form:
# Project name<tab>Composer Namespace<tab>Branch<tab>Project type<tab>Drupal 10 readiness text<tab>project usage count<tab>release node id<tab>concat core_version_requirement
# blazy	blazy	1.x-dev	project_module	NULL	55069	2663392	blazy_ui:subcomponent:"",blazy:primary:"^8 || ^9"
echo "Starting analysis with  ${PROC_COUNT} threads"
/usr/bin/time -v parallel -j${PROC_COUNT} --colsep '\t' --timeout 900 /var/lib/drupalci/workspace/infrastructure/stats/project_analysis/analyzer.sh "{1}" "{2}" "{3}" "{4}" "{%}" "{8}" :::: /var/lib/drupalci/workspace/projects.tsv 2>&1 > /var/lib/drupalci/workspace/analyzer_output.log
