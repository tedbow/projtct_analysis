<?php

namespace InfoUpdater;

/**
 * Utility Class to check XML files produced by rector.
 */
class RectorResults {

  protected const RESULT_DIR = '/var/lib/drupalci/workspace/phpstan-results';
  /**
   * @param $project_version
   *
   * @return bool
   */
  public static function errorInTest($project_version) {
    $err_file = static::RESULT_DIR . "/$project_version.rector_stderr";
    if (!file_exists($err_file)) {
      return FALSE;
    }
    $err_contents = file_get_contents($err_file);
    if (empty(trim($err_contents))) {
      return FALSE;
    }

    $lines = file(static::RESULT_DIR . "/$project_version.rector_out");
    $line = $lines[count($lines)-1];
    return stripos($line, '/tests/') !== FALSE;
  }
}
