#!/bin/bash
set -eux

# This script will set up each of the drupal checkout directories to be ready to execute phpstan.
git clone --quiet --shared /var/lib/drupalci/drupal-checkout /var/lib/drupalci/workspace/drupal-checkouts/drupal$1
COMPOSER_CACHE_DIR=/tmp/cache$1 composer --working-dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$1 config prefer-stable false
