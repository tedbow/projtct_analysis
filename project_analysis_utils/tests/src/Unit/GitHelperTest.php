<?php

namespace InfoUpdater\Tests\Unit;

use InfoUpdater\GitHelper;
use InfoUpdater\Tests\TestBase;
use PHPUnit\Framework\TestCase;

/**
 * @coversDefaultClass \InfoUpdater\GitHelper
 */
class GitHelperTest extends TestBase {

  /**
   * @covers ::restoreNonRectorChanges
   */
  public function testRestoreNonRectorChanges() {
    $repo = static::FIXTURE_DIR . '/test_repo';
    $temp_repo = sys_get_temp_dir() . '/project_list_utils_test_repo';
    exec("rm -rf $temp_repo");
    self::assertTrue(mkdir($temp_repo));
    $files = scandir($repo);

    self::assertNotEmpty($files);
    $copied_files = 0;
    foreach ($files as $file) {
      $file_path = "$repo/$file";
      if (!is_file($file_path)) {
        continue;
      }
      $this->assertTrue(copy($file_path, $temp_repo . "/$file"));
      $copied_files++;
    }
    self::assertSame(6, $copied_files);
    chdir($temp_repo);
    $helper = new GitHelper();
    $init = $helper->shellExecSplit('git init');
    $this->assertStringStartsWith('Initialized empty Git repository in', $init[0]);
    $helper->shellExecSplit('git add .');
    $helper->shellExecSplit('git commit -am "init"');
    $status = $helper->shellExecSplit('git status');
    $this->assertSame('nothing to commit, working tree clean', $status[1]);
    $helper->shellExecSplit('patch < changes.patch');
    $diff_files = $helper->shellExecSplit('git diff --name-only');
    $this->assertSame(
      [
        'JustUseChangesClass.php',
        'UseChangesAndOthers.php',
        'both_change.unknown',
        'whitespace_only_change.unknown',
      ],
      $diff_files
    );
    $helper->restoreNonRectorChanges($temp_repo);
    $diff_files = $helper->shellExecSplit('git diff --name-only');
    $this->assertSame(
      [
        'UseChangesAndOthers.php',
        'both_change.unknown',
      ],
      $diff_files
    );
  }

  /**
   * @param string $dir
   *
   * @return array
   */
  private function getFiles(string $dir) {
    $files = scandir($dir);
    $return_files = [];
    foreach ($files as $file) {
      $file_path = "$dir/$file";
      if (!is_file($file_path)) {
        continue;
      }
      $return_files[] = $file_path;
    }
    return $return_files;
  }
}
