#!/usr/bin/env bash
set -uex
TOKEN=$1

echo "SELECT fdfpmn.field_project_machine_name_value,
       pcnm.package_namespace,
       REGEXP_REPLACE(SUBSTRING_INDEX(vl.name,'8.x-',-1), '.x','.x-dev') as \`Composer\`,
       n.type,
       fdfnmvi.field_next_major_version_info_value,
       (SELECT sum(count) FROM project_usage_week_release puwr INNER JOIN field_data_field_release_project fdf_rp ON fdf_rp.entity_id = puwr.nid INNER JOIN field_data_field_release_category fdf_rc ON fdf_rc.entity_id = fdf_rp.entity_id AND fdf_rc.field_release_category_value = 'current' WHERE fdf_rp.field_release_project_target_id = prsv.nid AND puwr.timestamp = (SELECT max(timestamp) FROM project_usage_week_project)),
       vrl.release_nid,
       coreversions.cvr
FROM project_release_supported_versions prsv
    LEFT JOIN field_data_field_project_machine_name fdfpmn ON fdfpmn.entity_id = prsv.nid
    LEFT JOIN field_data_field_next_major_version_info fdfnmvi ON fdfnmvi.entity_id = prsv.nid
    LEFT JOIN versioncontrol_release_labels vrl ON vrl.release_nid = prsv.latest_release
    LEFT JOIN node n on n.nid = prsv.nid
    INNER JOIN field_data_field_release_category fdf_rc ON fdf_rc.entity_id = prsv.latest_release AND fdf_rc.field_release_category_value = 'current'
    LEFT JOIN project_composer_namespace_map pcnm ON pcnm.project_nid = fdfpmn.entity_id AND pcnm.component_name = fdfpmn.field_project_machine_name_value
    INNER JOIN versioncontrol_labels vl ON vl.label_id = vrl.label_id AND vl.name NOT LIKE '9.x-%'
    LEFT JOIN field_data_taxonomy_vocabulary_44 fdtv44 on prsv.nid = fdtv44.entity_id
    LEFT JOIN (SELECT pcc.release_nid, GROUP_CONCAT(DISTINCT pcc.core_version_requirement) as \`cvr\` FROM project_composer_component pcc GROUP BY pcc.release_nid) AS coreversions ON coreversions.release_nid = vrl.release_nid

WHERE pcnm.category = 'current'
  AND prsv.supported = 1
  AND fdtv44.taxonomy_vocabulary_44_tid != 13032
  AND prsv.nid != 3060
  AND n.type IN ('project_module', 'project_theme')
GROUP BY prsv.nid, prsv.branch
ORDER BY NULL" | drush -r /var/www/drupal.org/htdocs sql-cli --extra='--skip-column-names' | sort > /tmp/projects.tsv
#head /tmp/testfile.tsv > /tmp/projects.tsv

curl https://dispatcher.drupalci.org/job/phpstan/build -F file0=@/tmp/projects.tsv -F json='{"parameter": [{"name":"projects.tsv", "file":"file0"}]}' -F token=${TOKEN}
