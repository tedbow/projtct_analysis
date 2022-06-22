#!/bin/bash
set -eux

# @todo remove this when the container is built again
sudo apt-get -qq update
sudo apt-get -qq install -y unzip
sudo composer self-update

# This file is intended to be executed on the testbot docker container.
export PHPSTAN_RESULT_DIR="/var/lib/drupalci/workspace/phpstan-results"

# Require both libraries so composer figures out what the max version it can support. There is overlap in dependencies which makes this a puzzle.
composer --working-dir=/var/lib/drupalci/drupal-checkout remove palantirnet/drupal-rector --dev --no-update
composer --working-dir=/var/lib/drupalci/drupal-checkout require drupal/upgrade_status palantirnet/drupal-rector -w --no-interaction
git -C /var/lib/drupalci/drupal-checkout add .
git -C /var/lib/drupalci/drupal-checkout commit -q -m "Update drupal-rector and upgrade_status library"

composer --working-dir=/var/lib/drupalci/drupal-checkout remove drupalorg_infrastructure/project_analysis_utils
composer --working-dir=/var/lib/drupalci/drupal-checkout require drupalorg_infrastructure/project_analysis_utils
git -C /var/lib/drupalci/drupal-checkout add .
git -C /var/lib/drupalci/drupal-checkout commit -q -m "Update project analysis internal library"

# Set up as many workspaces for running phpstan as many processor cores we have.
PROC_COUNT=`grep processor /proc/cpuinfo |wc -l`
parallel /var/lib/drupalci/workspace/infrastructure/stats/project_analysis/prepare_workspace.sh {} ::: $(seq -s' ' 1 ${PROC_COUNT})

# Run the analyzers in parallel in each workspace we created.
# 1/2/3/4/8 correspond to the columns in the project listing file which should take the
# following form:
# Project name<tab>Composer Namespace<tab>Branch<tab>Project type<tab>Drupal 10 readiness text<tab>project usage count<tab>release node id<tab>concat core_version_requirement
# blazy	blazy	1.x-dev	project_module	NULL	55069	2663392	blazy_ui:subcomponent:"",blazy:primary:"^8 || ^9"
time parallel --colsep '\t' --timeout 900 /var/lib/drupalci/workspace/infrastructure/stats/project_analysis/analyzer.sh "{1}" "{2}" "{3}" "{4}" "{%}" "{8}" :::: /var/lib/drupalci/workspace/projects.tsv 2>&1 > /var/lib/drupalci/workspace/phpstan_output.txt
