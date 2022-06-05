These projects.*.tsv files are not associated with a test class but can be used to test:
`stats/project_analysis/project_readiness.sh`

These files may stop to work as test as the projects include make commits fixing problems.environment_indicator

Rename a file `projects.tsv` move it to:
`/var/lib/drupalci/workspace/projects.tsv`

Then run `stats/project_analysis/project_readiness.sh`

File list:
* `projects_machine_name.tsv`: Used to test where the project name the module machine name are not the same or the main info.yml file is not in base directory.
* `projects.info_updates.tsv`: Used to test updates to info.yml. @see \InfoUpdater\Tests\Unit\InfoUpdaterTest::providerUpdateInfoNew for expected updates

