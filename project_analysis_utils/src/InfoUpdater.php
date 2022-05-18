<?php

namespace InfoUpdater;

use Composer\Semver\Semver;
use Symfony\Component\Yaml\Exception\ParseException;
use Symfony\Component\Yaml\Yaml;

class InfoUpdater extends ResultProcessorBase {

  private const KEY = 'core_version_requirement';

  /**
   * @param $file
   * @param string $project_version
   *
   * @return bool
   * @throws \Exception
   */
  public static function updateInfo($file, string $project_version) {
    $minimum_core_minor = NULL;
    if (file_exists(self::getUpgradeStatusXML($project_version, 'post'))) {
      $minimum_core_minor = static::getMinimumCore9Minor($project_version);
    }

    $contents = file_get_contents($file);
    $info = Yaml::parse($contents);
    $has_core_version_requirement = FALSE;
    $new_core_version_requirement = NULL;
    if (!isset($info[static::KEY])) {
      if ($minimum_core_minor === 5) {
        $new_core_version_requirement = '^9.5 || ^10';
        unset($info['core']);
      }
      elseif ($minimum_core_minor === 4) {
        $new_core_version_requirement = '^9.4 || ^10';
        unset($info['core']);
      }
      else {
        $new_core_version_requirement = '^9 || ^10';
      }
    }
    else {
      $has_core_version_requirement = TRUE;

      if ($minimum_core_minor === 5) {
        if (strpos($info[static::KEY], '9.5') === FALSE) {
          // If 9.5 is not in core_version_requirement it is likely specifying
          // lower compatibility
          $new_core_version_requirement = '^9.5 || ^10';
          unset($info['core']);
        }
      }
      elseif ($minimum_core_minor === 4) {
        if (strpos($info[static::KEY], '9.5') === FALSE && strpos($info[static::KEY], '9.4') === FALSE) {
          // If no version 9.5 or 9.4 then we need to set a version
          $new_core_version_requirement = '^9.4 || ^10';
          unset($info['core']);
        }
      }
      // Only update if we it doesn't already satisfy 10.0.0
      if (empty($new_core_version_requirement) && !Semver::satisfies('10.0.0', $info[static::KEY])) {
        $new_core_version_requirement = $info[static::KEY] . ' || ^10';
      }
    }
    if (!empty($new_core_version_requirement)) {
      // First try to update by string to avoid unrelated changes
      $new_lines = [];
      $info[static::KEY] = $new_core_version_requirement;
      $added_line = FALSE;
      foreach(preg_split("/((\r?\n)|(\r\n?))/", $contents) as $line){
        $key = explode(':', $line)[0];
        $trimmed_key = trim($key);
        if ($trimmed_key !== static::KEY && $trimmed_key !== 'core') {
          $new_lines[] = $line;
        }
        elseif ($has_core_version_requirement) {
          // Update the existing line.
          $new_lines[] = static::KEY . ': ' . $info[static::KEY];
        }
        if ($trimmed_key === 'core') {
          if (isset($info['core'])) {
            $new_lines[] = $line;
          }
          if (!$has_core_version_requirement) {
            $added_line = TRUE;
            $new_lines[] = static::KEY . ': ' . $info[static::KEY];
          }
        }
      }
      if (!$added_line && !$has_core_version_requirement) {
        $new_lines[] = static::KEY . ': ' . $info[static::KEY];
      }
      $new_file_contents = implode("\n", $new_lines);
      try {
        Yaml::parse($new_file_contents);
        return file_put_contents($file, $new_file_contents) !== FALSE;
      }
      catch (ParseException $exception) {
        // IF the new file contents didn't parse then dump the info.
        // This is will mean more lines will change.
        $yml = Yaml::dump($info);
        return file_put_contents($file, $yml) !== FALSE;
      }
    }
    return FALSE;

  }

  /**
   * Gets the minimum core minor for project version.
   *
   * Only checks 9.4 and 9.5 otherwise returns 0. Currently updater will only
   * support these updates.
   *
   * @param string $project_version
   *
   * @return int
   *   The minor version either 5,4,or 0.
   * @throws \Exception
   */
  private static function getMinimumCore9Minor(string $project_version) {
    $pre_messages = self::getMessages($project_version, 'pre');
    $post_messages = self::getMessages($project_version, 'post');

    foreach ([5, 4] as $minor) {
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
}
