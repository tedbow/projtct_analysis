<?php

namespace InfoUpdater;

use Symfony\Component\Yaml\Exception\ParseException;
use Symfony\Component\Yaml\Yaml;

class InfoUpdater extends UpdaterBase {

  private const KEY = 'core_version_requirement';

  /**
   * @param $file
   * @param string $project_version
   *
   * @return bool
   * @throws \Exception
   */
  public static function updateInfo($file, string $project_version) {
    $minimum_core_minor = 0;
    if (file_exists(self::getUpgradeStatusXML($project_version, 'post'))) {
      $minimum_core_minor = static::getMinimumCore9Minor($project_version);
    }

    $contents = file_get_contents($file);
    $info = Yaml::parse($contents);
    unset($info['core']);

    $has_core_version_requirement = FALSE;
    $new_core_version_requirement = NULL;
    if (!isset($info[static::KEY])) {
      // This should not happen, Drupal 9 compatible projects should have this key.
      $new_core_version_requirement = '^9.' . $minimum_core_minor . ' || ^10';
    }
    else {
      $has_core_version_requirement = TRUE;
      $new_core_version_requirement = self::getVersionRequirement($minimum_core_minor, $info[static::KEY]);
    }
    if (!empty($new_core_version_requirement)) {
      // First try to update by string to avoid unrelated changes
      $new_lines = [];
      $info[static::KEY] = $new_core_version_requirement;
      $added_line = FALSE;
      foreach(preg_split("/((\r?\n)|(\r\n?))/", $contents) as $line) {
        $key = explode(':', $line)[0];
        $trimmed_key = trim($key);
        if ($trimmed_key !== static::KEY) {
          if ($trimmed_key !== 'core') {
            // Keep any line that is not 'core' or 'core_version_requirement'.
            $new_lines[] = $line;
          }
        }
        else {
          // Update the existing line.
          $new_lines[] = static::KEY . ': ' . $info[static::KEY];
        }
      }
      // Add as a new line at the end of the file.
      if (!$has_core_version_requirement) {
        $new_lines[] = static::KEY . ': ' . $info[static::KEY];
      }
      $new_file_contents = implode("\n", $new_lines);
      try {
        Yaml::parse($new_file_contents);
        return file_put_contents($file, $new_file_contents) !== FALSE;
      }
      catch (ParseException $exception) {
        // If the new file contents didn't parse then dump the info.
        // This may result in a bigger diff.
        $yml = Yaml::dump($info);
        return file_put_contents($file, $yml) !== FALSE;
      }
    }
    return FALSE;

  }

}
