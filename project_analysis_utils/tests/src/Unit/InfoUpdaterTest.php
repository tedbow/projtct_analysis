<?php

namespace InfoUpdater\Tests\Unit;

use InfoUpdater\InfoUpdater;
use InfoUpdater\Tests\Core\InfoParserDynamic;
use InfoUpdater\Tests\TestBase;
use Symfony\Component\Yaml\Yaml;

/**
 * @coversDefaultClass \InfoUpdater\InfoUpdater
 */
class InfoUpdaterTest extends TestBase {

  /**
   * @covers ::updateInfo
   *
   * @dataProvider providerUpdateInfoNew
   */
  public function testUpdateInfoNew($file, $project_version, $expected, $expected_remove_core) {
    $temp_file = $this->createTempFixtureFile($file);
    $pre_yml = Yaml::parseFile($temp_file);

    InfoUpdater::updateInfo($temp_file, $project_version);
    $post_yml = Yaml::parseFile($temp_file);
    $this->assertSame($expected, $post_yml['core_version_requirement']);

    // The created info file should be able to be parsed by the core parser.
    $core_parser = new InfoParserDynamic();
    $core_info = $core_parser->parse($temp_file);
    $this->assertSame($post_yml, $core_info);


    if ($expected_remove_core) {
      $this->assertArrayHasKey('core', $pre_yml);
      unset($pre_yml['core']);
      $this->assertArrayNotHasKey('core', $post_yml);
    }
    else {
      $this->assertFalse(!empty($pre_yml['core']) && empty($post_yml['core']));
    }
    $pre_yml['core_version_requirement'] = $expected;
    $pre_yml = asort($pre_yml);
    $post_yml = asort($post_yml);
    $this->assertSame($post_yml, $post_yml);

    unlink($temp_file);
  }

  public function providerUpdateInfoNew() {
    return [
      '^9 in core version requirement' => [
        'core_version_requirement_9.info.yml',
        'environment_indicator.3.x-dev',
        '^9 || ^10',
        FALSE,
      ],
      '^9 || ^10 already in core version requirement' => [
        'core_version_requirement.info.yml',
        'environment_indicator.3.x-dev',
        '^9 || ^10',
        FALSE,
      ],
      '^9.1 in core version requirement' => [
        'core_version_requirement_910.info.yml',
        'environment_indicator.3.x-dev',
        '^9.1.0 || ^10',
        FALSE,
      ],
      '^9 deprecations with ^9.2 in core version requirement ' => [
        'core_version_requirement_920.info.yml',
        'environment_indicator.3.x-dev',
        '^9.2.0 || ^10',
        FALSE,
      ],
      '^9 deprecations with ^9.3 in core version requirement' => [
        'core_version_requirement_930.info.yml',
        'environment_indicator.3.x-dev',
        '^9.3.0 || ^10',
        FALSE,
      ],
      '^9 deprecations with ^9.4 in core version requirement' => [
        'core_version_requirement_940.info.yml',
        'environment_indicator.3.x-dev',
        '^9.4.0 || ^10',
        FALSE,
      ],
      '^9 deprecations with ^9.5.0 in core version requirement' => [
        'core_version_requirement_950.info.yml',
        'environment_indicator.3.x-dev',
        '^9.5.0 || ^10',
        FALSE,
      ],
      '9.1.0 deprecations with ^9 || ^10 in core version requirement' => [
        'core_version_requirement_9.info.yml',
        'texbar.1.x-dev',
        '^9.1 || ^10',
        FALSE,
      ],
      '9.1.0 deprecations with ^9 in core version requirement' => [
        'core_version_requirement.info.yml',
        'texbar.1.x-dev',
        '^9.1 || ^10',
        FALSE,
      ],
      '9.1.0 deprecations with ^9.1.0 in core version requirement' => [
        'core_version_requirement_910.info.yml',
        'texbar.1.x-dev',
        '^9.1.0 || ^10',
        FALSE,
      ],
      '9.1.0 deprecations with ^9.2.0 in core version requirement' => [
        'core_version_requirement_920.info.yml',
        'texbar.1.x-dev',
        '^9.2.0 || ^10',
        FALSE,
      ],
      '9.1.0 deprecations with ^9.3.0 in core version requirement' => [
        'core_version_requirement_930.info.yml',
        'texbar.1.x-dev',
        '^9.3.0 || ^10',
        FALSE,
      ],
      '9.1.0 deprecations with ^9.4.0 in core version requirement' => [
        'core_version_requirement_940.info.yml',
        'texbar.1.x-dev',
        '^9.4.0 || ^10',
        FALSE,
      ],
      '9.1.0 deprecations with ^9.5.0 in core version requirement' => [
        'core_version_requirement_950.info.yml',
        'texbar.1.x-dev',
        '^9.5.0 || ^10',
        FALSE,
      ],
      '^9.1.0 deprecations with ^9 in core version requirement AND core key' => [
        'core_version_requirement_with_core_key.info.yml',
        'texbar.1.x-dev',
        '^9.1 || ^10',
        TRUE
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
