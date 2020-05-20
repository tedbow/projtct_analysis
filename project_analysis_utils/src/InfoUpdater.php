<?php

namespace InfoUpdater;

use Composer\Semver\Semver;
use Symfony\Component\Yaml\Exception\ParseException;
use Symfony\Component\Yaml\Yaml;

class InfoUpdater {

  private const DEFAULT_VALUE = '^8 || ^9';
  private const KEY = 'core_version_requirement';
  public static function updateInfo($file) {
    $contents = file_get_contents($file);
    $info = Yaml::parse($contents);
    $has_core_version_requirement = FALSE;
    $update_info = FALSE;
    if (!isset($info[static::KEY])) {
      $info[static::KEY] = static::DEFAULT_VALUE;
      $update_info = TRUE;
    }
    else {
      if (!Semver::satisfies('9.0.0', $info[static::KEY])) {
        $info[static::KEY] .= ' || ^9';
        $update_info = TRUE;
        $has_core_version_requirement = TRUE;
      }
    }
    if ($update_info) {
      // First try to update by string to avoid unrelated changes
      $new_lines = [];
      $added_line = FALSE;
      foreach(preg_split("/((\r?\n)|(\r\n?))/", $contents) as $line){
        $key = explode(':', $line)[0];
        $trimmed_key = trim($key);
        if ($trimmed_key !== static::KEY) {
          $new_lines[] = $line;
        }
        elseif ($has_core_version_requirement) {
          // Update the existing line.
          $new_lines[] = static::KEY . ': ' . $info[static::KEY];
        }
        if ($trimmed_key === 'core' && !$has_core_version_requirement) {
          $added_line = TRUE;
          $new_lines[] = static::KEY . ': ' . $info[static::KEY];
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
}
