#!/bin/bash
set -eux

export PHPSTAN_RESULT_DIR="/var/lib/drupalci/workspace/phpstan-results"
#This file is intended to be executed on the testbot docker container.

composer --working-dir=/var/lib/drupalci/drupal-checkout remove drupalorg_infrastructure/project_analysis_utils
composer --working-dir=/var/lib/drupalci/drupal-checkout require drupalorg_infrastructure/project_analysis_utils
git -C /var/lib/drupalci/drupal-checkout add .
git -C /var/lib/drupalci/drupal-checkout commit -q -m "Updates internal lib"
PROC_COUNT=`grep processor /proc/cpuinfo |wc -l`

parallel /var/lib/drupalci/workspace/infrastructure/stats/project_analysis/install_phpstan.sh {} ::: $(seq -s' ' 1 ${PROC_COUNT})
# Run the analyzers.
# 1/2/3/4/8 correspond to the columns in the project listing file which should take the
# following form:
# Project name, Composer Namespace, Branch, Project type, d9 readyness text, project usage count, concat core_version_requirement
# ctools,ctools,3.x-dev,project_module, text, 100
time parallel --colsep '\t' --timeout 900 /var/lib/drupalci/workspace/infrastructure/stats/project_analysis/analyzer.sh "{1}" "{2}" "{3}" "{4}" "{%}" "{8}" :::: /var/lib/drupalci/workspace/projects.tsv 2>&1 > /var/lib/drupalci/workspace/phpstan_output.txt
