<?php

namespace InfoUpdater;

/**
 * Utility class for finding a project machine name.
 */
class MachineNameFinder {

  /**
   * Gets the machine name of a project.
   *
   * The machine name of the project that is required by composer sometimes is
   * not the same as the machine name of the module.
   *
   * @param string $composer_components
   *   As appears in projects.tsv, eg. blazy_ui:subcomponent:"",blazy:primary:"^8 || ^9"
   *
   * @return string
   */
  public static function findMachineName(string $composer_components) {
    $module_infos  = explode(',', $composer_components);
    $shortest_len = 9999;
    $shortest_module_name = NULL;
    foreach ($module_infos as $module_info) {

      [$module_name, $module_role, $core_version_requirement] = explode(':', $module_info);
      if ($module_role === 'primary') {
        return $module_name;
      }
      // There should always be a module flagged as primary, but we'll leave this
      // logic in here just in case something is awry in the db for some reason.
      $len = strlen($module_name);
      if ($len < $shortest_len) {
        $shortest_len = $len;
        $shortest_module_name = $module_name;
      }
    }
    return $shortest_module_name;
  }

}
