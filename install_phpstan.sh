#!/bin/bash

# This script will set up each of the drupal checkout directories to be ready to execute phpstan.
cd /var/lib/drupalci/workspace/drupal-checkouts
mkdir -p /var/lib/drupalci/workspace/phpstan-results
git clone -q -s /var/lib/drupalci/drupal-checkout drupal$1
cd /var/lib/drupalci/workspace/drupal-checkouts/drupal$1
COMPOSER_CACHE_DIR=/tmp/cache$1 composer config prefer-stable false
