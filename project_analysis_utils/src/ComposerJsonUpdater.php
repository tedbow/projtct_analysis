<?php

namespace InfoUpdater;

use Composer\Json\JsonFile;
use Composer\Json\JsonManipulator;

class ComposerJsonUpdater extends UpdaterBase {

  /**
   * @param $file
   * @param string $project_version
   *
   * @return bool
   * @throws \Exception
   */
  public static function update($file, string $project_version) {
    $minimum_core_minor = 0;
    if (file_exists(self::getUpgradeStatusXML($project_version, 'post'))) {
      $minimum_core_minor = static::getMinimumCore9Minor($project_version);
    }

    $json = new JsonFile($file);
    $composerJsonData = $json->read();

    // If for some reason there is no core requirement, just stop.
    if (!isset($composerJsonData['require']['drupal/core'])) {
      return FALSE;
    }

    $current_requirement = $composerJsonData['require']['drupal/core'];
    $new_core_version_requirement = self::getVersionRequirement($minimum_core_minor, $current_requirement);

    if (!empty($new_core_version_requirement)) {
      $manipulator = new JsonManipulator(file_get_contents($json->getPath()));
      $manipulator->removeSubNode('require', 'drupal/core');
      $manipulator->addSubNode('require', 'drupal/core', $new_core_version_requirement);
      return file_put_contents($json->getPath(), $manipulator->getContents()) !== FALSE;
    }
    return FALSE;

  }

}
