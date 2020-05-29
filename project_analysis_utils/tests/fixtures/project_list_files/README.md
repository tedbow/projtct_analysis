These projects.*.tsv files are not associated with a test class but can be used to test:
`stats/project_analysis/d9readiness.sh`

Rename a file `projects.tsv` move it to:
`/var/lib/drupalci/workspace/projects.tsv`

Then run `stats/project_analysis/d9readiness.sh`

File list:
* `projects_machine_name.tsv`: Used to projects where the project name the module machine name are not the same or the main info.yml file is not in base directory.