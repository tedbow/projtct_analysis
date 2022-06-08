<?php

namespace InfoUpdater;

use Symfony\Component\Yaml\Yaml;

/**
 * Utility Class to check XML files produced by Upgrade Status.
 */
class UpdateStatusXmlChecker {

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
   * Determines if rector should be run on the project.
   *
   * @return bool
   */
  public function runRector() {
    $messages = [];
    if (!isset($this->xml)) {
      // If we couldn't get XML from upgrade_status, still run rector.
      // phpstan may have failed, but rector still might succeed.
      return TRUE;
    }
    foreach ($this->xml->file as $file) {
      if ($this->isPhpfile($file)) {
        // If there was at least one PHP file that had errors, it is worth
        // running rector.
        return TRUE;
      }
    }

    // If there was no error in PHP files, not worth to run rector.
    return FALSE;
  }

  /**
   * Determines if the info.yml file can be updated.
   *
   * @return bool
   */
  public function isInfoUpdatable(): bool {
    if (empty($this->xml)) {
      // If we don't have the upgrade_status xml we can't determine if we
      // should update.
      return FALSE;
    }
    if (count($this->xml->file) > 2) {
      // If there is problem with more than 2 files we can't update.
      return FALSE;
    }

    if (count($this->xml->file) === 1) {
      return $this->errorsContainInfoYml();
    }

    return $this->errorsContainInfoYml() && $this->errorsContainComposerJson();
  }

  /**
   * Determines if the composer.json file can be updated.
   *
   * @return bool
   */
  public function isComposerUpdatable(): bool {
    if (empty($this->xml)) {
      // If we don't have the upgrade_status xml we can't determine if we
      // should update.
      return FALSE;
    }
    if (count($this->xml->file) > 2) {
      // If there is problem with more than 2 files we can't update.
      return FALSE;
    }

    if (count($this->xml->file) === 1) {
      return $this->errorsContainComposerJson();
    }

    return $this->errorsContainComposerJson() && $this->errorsContainInfoYml();
  }

  private function isPhpfile(\SimpleXMLElement $file) {
    $parts = explode('.', (string) $file->attributes()->name);
    $ext = array_pop($parts);
    // Assume all non-yml or twig files are php.
    return !in_array($ext, ['yml', 'twig']);
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

  /**
   * Determines if the info.yml file has one error
   *
   * @return bool
   */
  public function errorsContainInfoYml(): bool {
    foreach ($this->xml->file as $file) {
      $parts = explode('.', (string) $file->attributes()->name);
      $ext = array_pop($parts);
      $info = array_pop($parts);
      // Make sure this is an 'info.yml' file.
      if ($ext === 'yml' && $info === 'info') {
        // Make sure we only have one error in this one file.
        if (count($file->error) === 1) {
          foreach ($file->error as $error) {
            $message = (string) $error->attributes()['message'];
            // Make sure this one single error in this one file is about core version requirements.
            return preg_match('/core_version_requirement/', $message) === 1;
          }
        }
      }
    }
    return FALSE;
  }

  /**
   * Determines if the composer.json file has one error
   *
   * @return bool
   */
  public function errorsContainComposerJson(): bool {
    foreach ($this->xml->file as $file) {
      $basename = basename((string) $file->attributes()->name);
      // Make sure this is an 'composer.json' file.
      if ($basename === 'composer.json') {
        // Make sure we only have one error in this one file.
        if (count($file->error) === 1) {
          foreach ($file->error as $error) {
            $message = (string) $error->attributes()['message'];
            return preg_match('/The drupal\/core requirement is not compatible with the next major version of Drupal/', $message) === 1;
          }
        }
      }
    }
    return FALSE;
  }

}
