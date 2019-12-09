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
git checkout 8.9.x
git pull
rm -rf vendor

cat <<EOF > phpstan.neon
parameters:
  customRulesetUsed: true
  reportUnmatchedIgnoredErrors: false
  # Ignore phpstan-drupal extension's rules.
  ignoreErrors:
    - '#\Drupal calls should be avoided in classes, use dependency injection instead#'
    - '#Plugin definitions cannot be altered.#'
    - '#Missing cache backend declaration for performance.#'
    - '#Plugin manager has cache backend specified but does not declare cache tags.#'
  # Migrate test fixtures kill phpstan, too much PHP.
  excludes_analyse:
    - */tests/fixtures/*.php
includes:
  - ./vendor/mglaman/phpstan-drupal/extension.neon
  - ./vendor/phpstan/phpstan-deprecation-rules/rules.neon
EOF
composer require mglaman/phpstan-drupal phpstan/phpstan-deprecation-rules:0.11.2 phpstan/phpstan:0.11.19 --dev
#composer config repositories.patch vcs https://github.com/greg-1-anderson/drupal-finder
#composer require "webflo/drupal-finder:dev-find-drupal-drupal-root as 1.1"
#composer config --unset repositories.patch
find vendor -name .git -exec rm -rf {} \; || true
git add .;git commit -q -m "adds phpstan"

#Setup the drupal dirs
rm -rf /var/lib/drupalci/workspace/drupal-checkouts
mkdir -p /var/lib/drupalci/workspace/drupal-checkouts
parallel /var/lib/drupalci/workspace/infrastructure/stats/project_analysis/install_phpstan.sh {} ::: $(seq -s' ' 1 ${PROC_COUNT})
# Run the analyzers.
# 1/2/3/4 correspond to the columns in the project listing file which should take the
# following form:
# Project name, Composer Namespace, Branch, Project type, d9 readyness text, project usage count
# ctools,ctools,3.x-dev,project_module, text, 100
time parallel --colsep '\t' /var/lib/drupalci/workspace/infrastructure/stats/project_analysis/analyzer.sh "{1}" "{2}" "{3}" "{4}" "{%}" :::: /var/lib/drupalci/workspace/projects.tsv 2>&1 > /var/lib/drupalci/workspace/phpstan_output.txt
