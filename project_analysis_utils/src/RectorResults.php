<?php

namespace InfoUpdater;

/**
 * Utility Class to check XML files produced by rector.
 */
class RectorResults extends ResultProcessorBase {

  /**
   * Check if there were errors running rector in test files.
   *
   * @param string $project_version
   *   Project name and version as in the first part of the filename.
   *
   * @return bool
   */
  public static function errorInTest($project_version) {
    $err_file = static::getResultsDir() . "/$project_version.rector_stderr";
    if (!file_exists($err_file)) {
      return FALSE;
    }
    $err_contents = file_get_contents($err_file);
    if (empty(trim($err_contents))) {
      return FALSE;
    }

    $lines = file(static::getResultsDir() . "/$project_version.rector_out");
    $line = $lines[count($lines)-1];
    return stripos($line, '/tests/') !== FALSE;
  }
}
