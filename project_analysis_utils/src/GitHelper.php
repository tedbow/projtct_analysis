<?php

namespace InfoUpdater;

/**
 * Class GitHelper
 *
 * @package InfoUpdater
 */
class GitHelper {

  private function shellExecSplit($string) {
    $output = shell_exec($string);
    $output = preg_split('/\n+/', trim($output));
    $output = array_map(function ($line) {
      return trim($line);
    }, $output);

    return array_filter($output);

  }

  /**
   * Restores any file that only has change not made by rector.
   *
   * Rector has a bug where it changes some lines that aren't related to any
   * rules. https://github.com/rectorphp/rector/issues/3375
   *
   * @param string $dir
   *   The working directory to use.
   *
   * @throws \Exception
   */
  public function restoreNonRectorChanges($dir) {
    if (!chdir($dir)) {
      return;
    }
    $files = $this->shellExecSplit('git diff --name-only');
    foreach ($files as $file) {
      $diff = $this->shellExecSplit("git diff $file");
      $diff = array_splice($diff, 5);
      // Match any line that starts with + or - and has no other characters
      // except space, * , / or {
      $p = '/^[\+\-].*[^\/* {].*/';
      $rector_change = FALSE;
      foreach ($diff as $diff_line) {
        if (preg_match($p, $diff_line)) {
          $rector_change = TRUE;
          break;
        }
      }
      if (!$rector_change) {
        system("git checkout -- $file", $ret);
        if ($ret !== 0) {
          throw new \Exception("Cannot checkout: $file");
        }
      }
    }
  }
}
