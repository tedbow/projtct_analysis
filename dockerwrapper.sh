#!/bin/bash
set -eux
docker pull drupalci/php-7.2-apache:production
docker run -v /var/lib/drupalci:/var/lib/drupalci drupalci/php-7.2-apache:production /var/lib/drupalci/workspace/infrastructure/stats/project_analysis/d9readiness.sh
