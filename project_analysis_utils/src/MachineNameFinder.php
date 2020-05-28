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
   * @param string $dir
   *   Directory as created by composer for the projects.
   *
   * @return string
   */
  public static function findMachineName(string $dir) {
    $parts = explode('/', $dir);
    $project_name = array_pop($parts);
    if (file_exists("$dir/$project_name.info.yml")) {
      return $project_name;
    }
    $files = glob($dir . '/*.info.yml');
    $machine_name = NULL;
    $shortest = 9999;
    foreach ($files as $file) {
      $name = basename($file, '.info.yml');
      $len = strlen($name);
      if ($len < $shortest) {
        $machine_name = $name;
        $shortest = $len;
      }
    }
    return $machine_name;

  }

}
