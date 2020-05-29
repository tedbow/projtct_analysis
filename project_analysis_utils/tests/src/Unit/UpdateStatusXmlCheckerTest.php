<?php

namespace InfoUpdater\Tests\Unit;

use InfoUpdater\Tests\TestBase;
use InfoUpdater\UpdateStatusXmlChecker;
use PHPUnit\Framework\TestCase;

/**
 * @coversDefaultClass \InfoUpdater\UpdateStatusXmlChecker
 */
class UpdateStatusXmlCheckerTest extends TestBase {


  /**
   * @covers ::isInfoUpdatable
   */
  public function testIsInfoUpdatable() {

    $checker = new UpdateStatusXmlChecker(static::FIXTURE_DIR . '/yoast_seo.2.x-dev.upgrade_status.pre_rector.xml');
    $this->assertFalse($checker->isInfoUpdatable());

    $checker = new UpdateStatusXmlChecker(static::FIXTURE_DIR . '/viewfield.3.x-dev.upgrade_status.pre_rector.xml');
    $this->assertTrue($checker->isInfoUpdatable());
  }

  /**
   * @covers ::runRector
   */
  public function testRunRector() {
    $checker = new UpdateStatusXmlChecker(static::FIXTURE_DIR . '/yoast_seo.2.x-dev.upgrade_status.pre_rector.xml');
    $this->assertTrue($checker->runRector());

    $checker = new UpdateStatusXmlChecker(static::FIXTURE_DIR . '/viewfield.3.x-dev.upgrade_status.pre_rector.xml');
    $this->assertFalse($checker->runRector());
  }
}
