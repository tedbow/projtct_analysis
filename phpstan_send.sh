#!/usr/bin/env bash
set -uex
TOKEN=$1

echo "SET group_concat_max_len = 1000000; SELECT fdfpmn.field_project_machine_name_value,
       pcnm.package_namespace,
       REGEXP_REPLACE(SUBSTRING_INDEX(vl.name,'8.x-',-1), '.x','.x-dev') as \`Composer\`,
       n.type,
       fdfnmvi.field_next_major_version_info_value,
       (SELECT sum(count) FROM project_usage_week_release puwr INNER JOIN field_data_field_release_project fdf_rp ON fdf_rp.entity_id = puwr.nid INNER JOIN field_data_field_release_category fdf_rc ON fdf_rc.entity_id = fdf_rp.entity_id AND fdf_rc.field_release_category_value = 'current' WHERE fdf_rp.field_release_project_target_id = prsv.nid AND puwr.timestamp = (SELECT max(timestamp) FROM project_usage_week_release)),
       vrl.release_nid,
       coreversions.cvr
FROM project_release_supported_versions prsv
    INNER JOIN field_data_field_project_machine_name fdfpmn ON fdfpmn.entity_id = prsv.nid
    LEFT JOIN field_data_field_next_major_version_info fdfnmvi ON fdfnmvi.entity_id = prsv.nid
    LEFT JOIN (SELECT n.nid, fdf_rp.field_release_project_target_id project_nid, fdf_rv.field_release_version_value version FROM node n INNER JOIN field_data_field_release_project fdf_rp ON fdf_rp.entity_id = n.nid INNER JOIN field_data_field_release_version fdf_rv ON fdf_rv.entity_id = fdf_rp.entity_id WHERE n.status = 1) dev_release ON dev_release.project_nid = prsv.nid AND dev_release.version = concat(prsv.branch, 'x-dev')
    INNER JOIN versioncontrol_release_labels vrl ON vrl.release_nid = coalesce(dev_release.nid, prsv.latest_release)
    INNER JOIN node n on n.nid = prsv.nid AND n.status = 1 AND n.type IN ('project_module', 'project_theme')
    INNER JOIN field_data_field_release_category fdf_rc ON fdf_rc.entity_id = prsv.latest_release AND fdf_rc.field_release_category_value = 'current'
    INNER JOIN project_composer_namespace_map pcnm ON pcnm.project_nid = fdfpmn.entity_id AND pcnm.component_name = fdfpmn.field_project_machine_name_value AND pcnm.category = 'current'
    INNER JOIN versioncontrol_labels vl ON vl.label_id = vrl.label_id AND vl.name NOT LIKE '9.x-%'
    INNER JOIN field_data_taxonomy_vocabulary_44 fdtv44 on prsv.nid = fdtv44.entity_id AND fdtv44.taxonomy_vocabulary_44_tid != 13032
    INNER JOIN field_data_taxonomy_vocabulary_46 fdtv46 on prsv.nid = fdtv46.entity_id AND fdtv46.taxonomy_vocabulary_46_tid != 9994
    INNER JOIN field_data_field_security_advisory_coverage fdf_sac ON fdf_sac.entity_id = prsv.nid AND fdf_sac.field_security_advisory_coverage_value = 'revoked'
    LEFT JOIN (SELECT pcc.release_nid, GROUP_CONCAT(CONCAT(pcc.name, ':\"', pcc.core_version_requirement, '\"')) as \`cvr\` FROM project_composer_component pcc GROUP BY pcc.release_nid) AS coreversions ON coreversions.release_nid = vrl.release_nid
WHERE prsv.supported = 1
GROUP BY prsv.nid, prsv.branch
ORDER BY NULL" | drush -r /var/www/drupal.org/htdocs sql-cli --extra='--skip-column-names' | sort > /var/www/drupal.org/htdocs/files/project_analysis/allprojects.tsv
egrep -v 'geotimezone|ip2country|background_process|publisso_gold' /var/www/drupal.org/htdocs/files/project_analysis/allprojects.tsv > /var/www/drupal.org/htdocs/files/project_analysis/projects.tsv

split -n l/2 -d /var/www/drupal.org/htdocs/files/project_analysis/projects.tsv /var/www/drupal.org/htdocs/files/project_analysis/projects

for i in `ls /var/www/drupal.org/htdocs/files/project_analysis/projects??`;
do

mv ${i} ${i}.tsv
done
curl https://dispatcher.drupalci.org/job/project_analysis//build --user "${DISPATCHER_USER}:${DISPATCHER_PASS}" -F token="${TOKEN}"
