<?php

namespace InfoUpdater\Tests\Unit;

use Composer\Json\JsonFile;
use InfoUpdater\ComposerJsonUpdater;
use InfoUpdater\InfoUpdater;
use InfoUpdater\Tests\Core\InfoParserDynamic;
use InfoUpdater\Tests\TestBase;
use Symfony\Component\Yaml\Yaml;

/**
 * @coversDefaultClass \InfoUpdater\ComposerJsonUpdater
 */
class ComposerJsonUpdaterTest extends TestBase {

  /**
   * @covers ::update
   *
   * @dataProvider providerUpdateComposerJson
   */
  public function testUpdateComposerJson($file, $project_version, $expected) {
    $temp_file = $this->createTempFixtureFile($file);
    $pre_json_file = new JsonFile($temp_file);
    $pre_json = $pre_json_file->read();

    ComposerJsonUpdater::update($temp_file, $project_version);

    $post_json_file = new JsonFile($temp_file);
    $post_json = $post_json_file->read();

    $pre_json['require']['drupal/core'] = $expected;

    $this->assertSame($pre_json, $post_json);

    unlink($temp_file);
  }

  public function providerUpdateComposerJson() {
    return [
      '^9 in core version requirement' => [
        'composer_9.json',
        'environment_indicator.3.x-dev',
        '^9 || ^10',
      ],
      '^10 in core version requirement' => [
        'composer_9.json',
        'environment_indicator.3.x-dev',
        '^9 || ^10',
      ],
      '^9 || ^10 in core version requirement' => [
        'composer_9_10.json',
        'environment_indicator.3.x-dev',
        '^9 || ^10',
      ],
      '^8 || ^9 in core version requirements' => [
        'composer_8_9.json',
        'environment_indicator.3.x-dev',
        '^8 || ^9 || ^10',
      ]
    ];
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
