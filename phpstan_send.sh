#!/usr/bin/env bash
set -uex
TOKEN=$1

echo "SELECT fdfpmn.field_project_machine_name_value,
       pcnm.package_namespace,
       REGEXP_REPLACE(SUBSTRING_INDEX(vl.name,'8.x-',-1), '.x','.x-dev') as \`Composer\`,
       n.type,
       fdfnmvi.field_next_major_version_info_value,
       puwr.count
FROM project_release_supported_versions prsv
         LEFT JOIN field_data_field_project_machine_name fdfpmn ON fdfpmn.entity_id = prsv.nid
         LEFT JOIN field_data_field_next_major_version_info fdfnmvi ON fdfnmvi.entity_id = prsv.nid
         LEFT JOIN versioncontrol_release_labels vrl ON vrl.release_nid = prsv.latest_release
         LEFT JOIN node n on n.nid = prsv.nid
         LEFT JOIN project_usage_week_release puwr ON puwr.nid = prsv.latest_release AND puwr.timestamp = (SELECT max(timestamp) FROM project_usage_week_release)
         LEFT JOIN project_composer_namespace_map pcnm ON pcnm.project_nid = prsv.nid AND pcnm.component_name = fdfpmn.field_project_machine_name_value
LEFT JOIN versioncontrol_labels vl ON vl.label_id = vrl.label_id
WHERE prsv.tid = 7234
  AND pcnm.api_tid = 7234
  AND prsv.supported = 1;" | drush -r /var/www/drupal.org/htdocs sql-cli --extra='--skip-column-names' | sort > /tmp/projects.tsv
head /tmp/projects.tsv > /tmp/testfile.tsv

curl https://dispatcher.drupalci.org/job/phpstan/build -F file0=@/tmp/testfile.tsv -F json='{"parameter": [{"name":"projects.tsv", "file":"file0"}]}' -F token=${TOKEN}
