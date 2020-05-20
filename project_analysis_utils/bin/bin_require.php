<?php
$possibleAutoloadPaths = [
  // local dev repository
  __DIR__ . '/../vendor/autoload.php',
  // dependency
  __DIR__ . '/../../../autoload.php',
];
$autoLoad = NULL;
foreach ($possibleAutoloadPaths as $possibleAutoloadPath) {
  if (file_exists($possibleAutoloadPath)) {
    $autoLoad = $possibleAutoloadPath;
    break;
  }
}
if (empty($autoLoad)) {
  throw new Exception("No autoload patch");
}
require_once $autoLoad;
