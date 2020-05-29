<?php

namespace InfoUpdater;

/**
 * Utility Class to check XML files produced by rector.
 */
class RectorResults {

  /**
   * Gets the results directory.
   *
   * @return string
   * @throws \Exception
   */
  protected static function getResultsDir() {
    $dir = getenv('PHPSTAN_RESULT_DIR');
    if (empty($dir)) {
      throw new \Exception('PHPSTAN_RESULT_DIR not set');
    }
    return $dir;
  }


  /**
   * @param $project_version
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
