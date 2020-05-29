<?php

namespace InfoUpdater\Tests\Unit;

use InfoUpdater\InfoUpdater;
use InfoUpdater\Tests\TestBase;
use PHPUnit\Framework\TestCase;
use Symfony\Component\Yaml\Yaml;

/**
 * @coversDefaultClass \InfoUpdater\InfoUpdater
 */
class InfoUpdaterTest extends TestBase {

  /**
   * @covers ::updateInfo
   */
  public function testNoCoreVersionRequirement() {
    $temp_file = $this->createTempFixtureFile("no_core_version_requirement.info.yml");
    $pre_yml = Yaml::parseFile($temp_file);
    $this->assertFalse(isset($pre_yml['core_version_requirement']));
    InfoUpdater::updateInfo($temp_file);
    $post_yml = Yaml::parseFile($temp_file);
    $this->assertSame('^8 || ^9', $post_yml['core_version_requirement']);
    unlink($temp_file);
  }

  /**
   * @covers ::updateInfo
   */
  public function testCoreVersionRequirement() {
    $temp_file = $this->createTempFixtureFile("core_version_requirement.info.yml");
    $pre_yml = Yaml::parseFile($temp_file);
    $this->assertSame('^8.8', $pre_yml['core_version_requirement']);
    InfoUpdater::updateInfo($temp_file);
    $post_yml = Yaml::parseFile($temp_file);
    $this->assertSame('^8.8 || ^9', $post_yml['core_version_requirement']);
    unlink($temp_file);
  }

  /**
   * @param $file
   *
   * @return string
   */
  protected function createTempFixtureFile($file): string {
    $fixture_file = static::FIXTURE_DIR . "/$file";
    $temp_file = sys_get_temp_dir() . "/$file";
    if (file_exists($temp_file)) {
      unlink($temp_file);
    }
    copy($fixture_file, $temp_file);
    return $temp_file;
  }

}
