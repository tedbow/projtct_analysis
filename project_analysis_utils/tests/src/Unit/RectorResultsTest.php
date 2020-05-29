<?php

namespace InfoUpdater\Tests;

use InfoUpdater\RectorResults;
use PHPUnit\Framework\TestCase;

/**
 * @coversDefaultClass \InfoUpdater\RectorResults
 */
class RectorResultsTest extends TestCase {

  /**
   * @covers ::errorInTest
   */
  public function testErrorInTest() {
    putenv("PHPSTAN_RESULT_DIR=" . __DIR__ . '/../../fixtures');
    $this->assertTrue(RectorResults::errorInTest('node_revision_delete.1.x-dev'));
    $this->assertTrue(RectorResults::errorInTest('abbrfilter.1.x-dev'));
    // Test file that ends with '/tests/' but has not error output.
    $this->assertFalse(RectorResults::errorInTest('abbrfilter.2.x-dev'));
    // Test file that has not error output but does not with '/tests/' but .
    $this->assertFalse(RectorResults::errorInTest('abbrfilter.3.x-dev'));
  }

  /**
   * @covers ::errorInTest
   */
  public function testErrorInTestNoEnv() {
    $this->expectExceptionMessage('PHPSTAN_RESULT_DIR not set');
    // have to set to empty string because other method may have run first.
    putenv('PHPSTAN_RESULT_DIR=');
    RectorResults::errorInTest('node_revision_delete.1.x-dev');
  }
}