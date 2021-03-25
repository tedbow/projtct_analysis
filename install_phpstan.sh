#!/bin/bash
set -eux

# This script will set up each of the drupal checkout directories to be ready to execute phpstan.
git -C /var/lib/drupalci/drupal-checkout pull --rebase
git -C /var/lib/drupalci/drupal-checkout checkout $2
git clone --quiet --shared /var/lib/drupalci/drupal-checkout /var/lib/drupalci/workspace/drupal-checkouts/drupal$1
COMPOSER_CACHE_DIR=/var/lib/drupalci/workspace/drupal-checkouts/cache$1 composer --working-dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$1 config prefer-stable false
