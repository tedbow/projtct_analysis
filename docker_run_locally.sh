#!/bin/bash

########################################
# Running on a locally built container
########################################

# Build the container locally, nice and fresh
# docker build docker/. -t infrastructure/project_analysis:latest

# Remove existing container, usefull if this is a second run
# docker rm "project_analysis_local" -f

# Start the container
# docker run -d --name project_analysis_local infrastructure/project_analysis


########################################
# Running the production container
########################################
# Remove existing container, usefull if this is a second run
docker rm "project_analysis_local" -f

# Run on the same container as on DrupalCI? Use this container
docker run -d --name project_analysis_local drupalci/static_analysis:9.4.x


########################################
# Choosing the set to test
########################################

# Copy the test set into the container
docker cp ./project_analysis_utils/tests/project_list_files/projects_d10.tsv project_analysis_local:/var/lib/drupalci/workspace/projects.tsv

# Want to do a full run? Use this link (or similar)
# wget https://www.drupal.org/files/project_analysis/projects.tsv?125 -O projects.tsv
# docker cp ./projects.tsv project_analysis_local:/var/lib/drupalci/workspace/projects.tsv

# Copy current code into container
docker cp ./. project_analysis_local:/var/lib/drupalci/workspace/infrastructure/stats/project_analysis

# Execute the readiness scripts
docker exec project_analysis_local /var/lib/drupalci/workspace/infrastructure/stats/project_analysis/project_readiness.sh


########################################
# Developement debugging
########################################

# Copy the results to your local machine
docker cp project_analysis_local:/var/lib/drupalci/workspace/phpstan-results .

# Explore this container
 docker exec -it project_analysis_local /bin/bash
