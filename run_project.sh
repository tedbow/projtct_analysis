#!/bin/bash

echo $1

git -C /var/lib/drupalci/workspace/infrastructure pull --rebase
wget https://www.drupal.org/files/project_analysis/${1}.tsv -O /var/lib/drupalci/workspace/projects.tsv
/var/lib/drupalci/workspace/infrastructure/stats/project_analysis/d9readiness.sh
