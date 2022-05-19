<?php

namespace InfoUpdater;

use PHPUnit\Framework\TestCase;

/**
 * @coversDefaultClass \InfoUpdater\MachineNameFinder
 */
class MachineNameFinderTest extends TestCase {

  /**
   * @covers ::findMachineName
   */
  public function testFindMachineName() {
    $csv = 'blazy_ui:subcomponent:"",blazy:primary:"^8 || ^9"';
    $this->assertSame("blazy", MachineNameFinder::findMachineName($csv));

  }
}
