#!/bin/bash

# This script will set up each of the drupal checkout directories to be ready to execute phpstan.
cd /var/lib/drupalci/workspace/drupal-checkouts
mkdir -p /var/lib/drupalci/workspace/phpstan-results
git clone -s /var/lib/drupalci/drupal-checkout drupal$1
