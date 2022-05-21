#!/bin/bash
set -eux

# Set up this workspace to be ready to execute Upgrade Status and Drupal Rector.

git clone --quiet --shared /var/lib/drupalci/drupal-checkout /var/lib/drupalci/workspace/drupal-checkouts/drupal$1
COMPOSER_CACHE_DIR=/var/lib/drupalci/workspace/drupal-checkouts/cache$1 composer --working-dir=/var/lib/drupalci/workspace/drupal-checkouts/drupal$1 config prefer-stable false

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cp $SCRIPT_DIR/rector.php /var/lib/drupalci/workspace/drupal-checkouts/drupal$1/
