<?php


namespace InfoUpdater\Tests;


use PHPUnit\Framework\TestCase;

class TestBase extends TestCase {

  protected const FIXTURE_DIR = __DIR__ . '/../fixtures';

  protected function setUp() {
    parent::setUp();
    putenv("PHPSTAN_RESULT_DIR=" . __DIR__ . '/../fixtures');
  }

  protected function tearDown() {
    parent::tearDown();
    putenv('PHPSTAN_RESULT_DIR');
  }

}