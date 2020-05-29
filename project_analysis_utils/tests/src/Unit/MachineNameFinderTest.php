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
    $csv = 'my_module_helper:"8",my_module:"8"';
    $this->assertSame("my_module", MachineNameFinder::findMachineName($csv, 'mymodule'));
    $this->assertSame("my_module", MachineNameFinder::findMachineName($csv, 'my_module'));
    $this->assertSame("my_module_helper", MachineNameFinder::findMachineName($csv, 'my_module_helper'));

  }
}
