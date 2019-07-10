#!/bin/bash

# This script will set up each of the drupal checkout directories to be ready to execute phpstan.
cd /var/lib/drupalci/workspace/drupal-checkouts
mkdir -p /var/lib/drupalci/workspace/phpstan-results
git clone -s /var/lib/drupalci/drupal-checkout drupal$1

cat <<EOF > /var/lib/drupalci/workspace/drupal-checkouts/drupal$1/phpstan.neon
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
cd /var/lib/drupalci/workspace/drupal-checkouts/drupal$1
composer require mglaman/phpstan-drupal phpstan/phpstan-deprecation-rules --dev
composer config prefer-stable false
