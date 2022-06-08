<?php

namespace InfoUpdater;

use Composer\Json\JsonFile;
use Composer\Json\JsonManipulator;
use Composer\Semver\Semver;
use Symfony\Component\Yaml\Exception\ParseException;
use Symfony\Component\Yaml\Yaml;

class ComposerJsonUpdater extends ResultProcessorBase {

  private const KEY = 'core_version_requirement';

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

  /**
   * Gets the minimum core minor for project version based on detected API changes.
   *
   * @param string $project_version
   *
   * @return int
   *   The minor version either 5, 4, 3, 2, 1 or 0.
   * @throws \Exception
   */
  private static function getMinimumCore9Minor(string $project_version) {
    $pre_messages = self::getMessages($project_version, 'pre');
    $post_messages = self::getMessages($project_version, 'post');

    foreach ([5, 4, 3, 2, 1] as $minor) {
      $deprecation_version = "drupal:9.$minor.0";
      if (strpos($pre_messages, $deprecation_version) !== FALSE && strpos($post_messages, $deprecation_version) === FALSE) {
        return $minor;
      }
    }
    return 0;
  }

  /**
   * Gets the error and warning messages for a upgrade_status xml file.
   *
   * @param string $project_version
   *
   * @param $pre_or_post
   *
   * @return string
   *
   * @throws \Exception
   */
  private static function getMessages(string $project_version, $pre_or_post): string {
    $pre = new UpdateStatusXmlChecker(self::getUpgradeStatusXML($project_version, $pre_or_post));
    return implode(' -- ', $pre->getMessages('error'))
      . ' -- '
      . implode(' -- ', $pre->getMessages('warning'));
  }

  /**
   * Get the file location of an upgrade_status xml file.
   * @param string $project_version
   * @param $pre_or_post
   *
   * @return string
   * @throws \Exception
   */
  private static function getUpgradeStatusXML(string $project_version, $pre_or_post): string {
    return static::getResultsDir() . "/$project_version.upgrade_status.{$pre_or_post}_rector.xml";
  }

  /**
   * @param int $minimum_core_minor
   * @param $current_requirement
   *
   * @return string|null
   */
  public static function getVersionRequirement(int $minimum_core_minor, $current_requirement): ?string {
    $new_core_version_requirement = NULL;
    if ($minimum_core_minor === 5) {
      if (strpos($current_requirement, '9.5') === FALSE) {
        // If 9.5 is not in core_version_requirement it is likely specifying
        // lower compatibility.
        $new_core_version_requirement = '^9.5 || ^10';
      }
    }
    elseif ($minimum_core_minor === 4) {
      if (strpos($current_requirement, '9.5') === FALSE && strpos($current_requirement, '9.4') === FALSE) {
        // If no version 9.5 or 9.4 then we need to set a version.
        $new_core_version_requirement = '^9.4 || ^10';
      }
    }
    elseif ($minimum_core_minor === 3) {
      if (strpos($current_requirement, '9.5') === FALSE && strpos($current_requirement, '9.4') === FALSE && strpos($current_requirement, '9.3') === FALSE) {
        // If no version 9.5, 9.4 or 9.3 then we need to set a version.
        $new_core_version_requirement = '^9.3 || ^10';
      }
    }
    elseif ($minimum_core_minor === 2) {
      if (strpos($current_requirement, '9.5') === FALSE && strpos($current_requirement, '9.4') === FALSE && strpos($current_requirement, '9.3') === FALSE && strpos($current_requirement, '9.2') === FALSE) {
        // If no version 9.5, 9.4, 9.3 or 9.2 then we need to set a version.
        $new_core_version_requirement = '^9.2 || ^10';
      }
    }
    elseif ($minimum_core_minor === 1) {
      if (strpos($current_requirement, '9.5') === FALSE && strpos($current_requirement, '9.4') === FALSE && strpos($current_requirement, '9.3') === FALSE && strpos($current_requirement, '9.2') === FALSE && strpos($current_requirement, '9.1') === FALSE) {
        // If no version 9.5, 9.4, 9.3, 9.2 or 9.1 then we need to set a version.
        $new_core_version_requirement = '^9.1 || ^10';
      }
    }

    // Only update if doesn't already satisfy 10.0.0, will only happen if $minimum_core_minor was 0.
    if (empty($new_core_version_requirement) && !Semver::satisfies('10.0.0', $current_requirement)) {
      if (!Semver::satisfies('9.5', $current_requirement)) {
        $current_requirement = $current_requirement . ' || ^9';
      }

      $new_core_version_requirement = $current_requirement . ' || ^10';
    }
    return $new_core_version_requirement;
  }
}
