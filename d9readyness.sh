#!/bin/bash

#This file is intended to be executed on the testbots.

#Ensure we've got the latest drupal.
cd /var/lib/drupalci/drupal-checkout
git fetch
git checkout 8.8.x
git pull

#Setup the drupal dirs
rm -rf /var/lib/drupalci/workspace/drupal-checkouts
mkdir -p /var/lib/drupalci/workspace/drupal-checkouts
parallel /var/lib/drupalci/workspace/prepare.sh {} ::: {1..32}
# Run the analyzers.
# parallel --colsep ',' ./analyzer.sh "{1}" "{2}" "{3}" "{%}" :::: smallprojects
