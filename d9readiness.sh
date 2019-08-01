#!/bin/bash
set -eux

#This file is intended to be executed on the testbots.
sudo composer selfupdate

rm -rf /var/lib/drupalci/workspace/phpstan-results || true

PROC_COUNT=`grep processor /proc/cpuinfo |wc -l`
sudo dpkg -i /var/lib/drupalci/workspace/infrastructure/stats/project_analysis/parallel_20190622_all.deb

#Ensure we've got the latest drupal.
cd /var/lib/drupalci/drupal-checkout
git config --global user.email "git@drupal.org"
git config --global user.name "Drupalci Testbot"
git fetch
git checkout 8.8.x
git pull

#Setup the drupal dirs
rm -rf /var/lib/drupalci/workspace/drupal-checkouts
mkdir -p /var/lib/drupalci/workspace/drupal-checkouts
parallel /var/lib/drupalci/workspace/infrastructure/stats/project_analysis/install_phpstan.sh {} ::: $(seq -s' ' 1 ${PROC_COUNT})
# Run the analyzers.
# 1/2/3/4 correspond to the columns in the project listing file which should take the
# following form:
# ctools,ctools,3.x-dev,project_module
time parallel --colsep ',' /var/lib/drupalci/workspace/infrastructure/stats/project_analysis/analyzer.sh "{1}" "{2}" "{3}" "{4}" "{%}" :::: /var/lib/drupalci/workspace/projects.csv 2>&1 > /var/lib/drupalci/workspace/phpstan_output.txt
