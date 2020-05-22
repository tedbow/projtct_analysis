<?php

namespace InfoUpdater;

/**
 * Utility Class to check XML files produced by rector.
 */
class RectorResults {

  /**
   * @param $project_version
   *
   * @return bool
   */
  public static function errorInTest($project_version) {
    $err_file = "/var/lib/drupalci/workspace/phpstan-results/$project_version.rector_stderr";
    if (!file_exists($err_file)) {
      return FALSE;
    }
    $err_contents = file_get_contents($err_file);
    if (empty(trim($err_contents))) {
      return FALSE;
    }

    $lines = file("/var/lib/drupalci/workspace/phpstan-results/$project_version.rector_out");
    $line = $lines[count($lines)-1];
    return stripos($line, '/tests/') !== FALSE;
  }
}
