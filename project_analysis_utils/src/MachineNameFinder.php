<?php

namespace InfoUpdater;

/**
 * Utility class for finding a project machine name.
 */
class MachineNameFinder {

  /**
   * Gets the machine of a module.
   *
   * The machine name of the project that is required by composer sometimes is
   * not the same as the machine name of the module.
   *
   * @param string $modules_csv
   *   As created in project.tsv
   * @param $project_name
   *   The project name that is used for composer.
   *
   * @return string
   */
  public static function findMachineName(string $modules_csv, $project_name) {
    $module_infos  = explode(',', $modules_csv);
    $shortest_len = 9999;
    $shortest_module_name = NULL;
    foreach ($module_infos as $module_info) {

      [$module_name, $info] = explode(':', $module_info);
      if ($module_name === $project_name) {
        return $module_name;
      }
      $len = strlen($module_name);
      if ($len < $shortest_len) {
        $shortest_len = $len;
        $shortest_module_name = $module_name;
      }
    }
    return $shortest_module_name;
  }

}
