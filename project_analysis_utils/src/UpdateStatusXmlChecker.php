<?php

namespace InfoUpdater;

use Symfony\Component\Yaml\Yaml;

/**
 * Utility Class to check XML files produced by Upgrade Status.
 */
class UpdateStatusXmlChecker {

  protected const DEPRECATIONS_FILE = '/var/lib/drupalci/workspace/infrastructure/stats/project_analysis/deprecation-index.yml';

  /**
   * @var string
   */
  protected $file;

  /**
   * @var \SimpleXMLElement
   */
  protected $xml;

  /**
   * @var \SimpleXMLElement
   */
  protected $files;


  /**
   * UpdateStatusXmlChecker constructor.
   */
  public function __construct($file) {
    $this->file = $file;
    $contents = file_get_contents($this->file);
    if (strpos($contents, '<checkstyle>') === FALSE) {
      return;
    }
    try {
      $this->xml = new \SimpleXMLElement($contents);
    }
    catch (\Exception $exception) {
      return;
    }
  }

  /**
   * Determines if rector should be run no the projects.
   *
   * @return bool
   */
  public function runRector() {
    $messages = [];
    if (!isset($this->xml)) {
      // If we couldn't get XML from upgrade_status still run rector.
      // phpstan may have failed but rector still might suceed.
      return TRUE;
    }
    foreach ($this->xml->file as $file) {
      if ($this->isPhpfile($file)) {
        return TRUE;
      }
    }
    return FALSE;
  }

  /**
   * Determines if the info.yml file can be updated.
   *
   * @return bool
   */
  public function isInfoUpdatable() {
    $error_messages = $this->getMessages();
    // If there are more than one errors we can't update the info.yml file.
    if (count($error_messages) > 1) {
      return FALSE;
    }
    $error_message = array_pop($error_messages);
    // If the only message if is for the info.yml file we can update it.
    return strpos($error_message, '.info.yml to designate that the module is compatible with Drupal 9. See https://drupal.org/node/3070687') !== FALSE;
  }

  private function isPhpfile(\SimpleXMLElement $file) {
    $parts = explode('.', (string) $file->attributes()->name);
    $ext = array_pop($parts);
    // Assume all non-yml or twig files are php.
    return !in_array($ext, ['yml', 'twig']);
  }

  /**
   * Attempts to get the rector covered messages
   *
   * Currently this will not work.
   *
   * @return array
   */
  private function getRectorCoveredMessages() {
    static $phpstan_messages = [];
    if (empty($phpstan_messages)) {
      $deprecations_file = static::DEPRECATIONS_FILE;
      $deps = Yaml::parseFile($deprecations_file);
      foreach ($deps as $dep) {
        if (!empty($dep['PHPStan'])) {
          $phpstan_messages[] = $dep['PHPStan'];
        }
      }
    }
    return $phpstan_messages;
  }

  /**
   * Gets all the error messages or by level.
   *
   * @param string $severity_level
   *
   * @return string[]
   */
  public function getMessages($severity_level = NULL) {
    $messages = [];
    if (!isset($this->xml)) {
      return $messages;
    }
    foreach ($this->xml->file as $file) {
      foreach ($file->error as $error) {
        $severity = (string) $error->attributes()['severity'];
        if ($severity_level && $severity_level !== $severity) {
          continue;
        }
        $message = (string) $error->attributes()['message'];
        if (!empty($message)) {
          $messages[] = $message;
        }
      }
    }
    return $messages;
  }
}
