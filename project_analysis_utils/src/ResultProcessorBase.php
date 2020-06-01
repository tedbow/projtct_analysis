<?php


namespace InfoUpdater;


abstract class ResultProcessorBase {
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
}