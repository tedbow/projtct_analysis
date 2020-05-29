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
    $this->assertTrue(TestRectorResults::errorInTest('node_revision_delete.1.x-dev'));
    $this->assertTrue(TestRectorResults::errorInTest('abbrfilter.1.x-dev'));
    // Test file that ends with '/tests/' but has not error output.
    $this->assertFalse(TestRectorResults::errorInTest('abbrfilter.2.x-dev'));
    // Test file that has not error output but does not with '/tests/' but .
    $this->assertFalse(TestRectorResults::errorInTest('abbrfilter.3.x-dev'));
  }
}

/**
 * Test class to change resuls directory.
 */
class TestRectorResults extends RectorResults{
  protected const RESULT_DIR = __DIR__ . '/../../fixtures';
}
