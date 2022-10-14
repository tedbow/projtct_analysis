<?php

namespace InfoUpdater\bot;

use Symfony\Component\Yaml\Yaml;

/**
 * Common functions for getting settings from yml files.
 */
abstract class SettingsBase {

  /**
   * The settings file.
   *
   * @var string
   */
  const FILE = '';

  /**
   * Get all settings.
   *
   * @return array
   */
  public static function getSettings() {
    static $settings = [];
    if (!isset($settings[static::FILE])) {
      $settings[static::FILE] = Yaml::parseFile(static::FILE);
    }
    return $settings[static::FILE];

  }

  /**
   * Gets an individual setting.
   *
   * @param string $key
   * @param null $default
   *   The default setting value.
   *
   * @return mixed|null
   *   The value of the setting or the default setting.
   */
  public static function getSetting(string $key, $default = NULL) {
    $settings = static::getSettings();
    return isset($settings[$key]) ? $settings[$key] : $default;
  }

    

}
