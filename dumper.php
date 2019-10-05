<?php

use Symfony\Component\VarDumper\Cloner\VarCloner;
use Symfony\Component\VarDumper\Dumper\ServerDumper;
use Symfony\Component\VarDumper\Dumper\ContextProvider\CliContextProvider;
use Symfony\Component\VarDumper\Dumper\ContextProvider\RequestContextProvider;
use Symfony\Component\VarDumper\Dumper\ContextProvider\SourceContextProvider;
use Symfony\Component\VarDumper\VarDumper;


if (!class_exists('Symfony\Component\VarDumper\Dumper\ServerDumper')) {
  require_once '/opt/var-dumper/vendor/autoload.php';
}

if (!function_exists('dumps')) {
  function dumps($var, ...$moreVars) {
    $cloner = new VarCloner();
    $contextProviders = [
      'cli' => new CliContextProvider(),
      'source' => new SourceContextProvider(),
    ];
    if (PHP != 'cli' && class_exists('\Drupal')) {
      $contextProviders['request'] = new RequestContextProvider(\Drupal::requestStack());
    }
    $dumper = new ServerDumper($_SERVER['VAR_DUMPER_SERVER'] ?? '127.0.0.1:9912');
    $handler = function ($var) use ($cloner, $dumper) {
      $dumper->dump($cloner->cloneVar($var));
    };
    $originalHandler = VarDumper::setHandler($handler);
    VarDumper::dump($var);
    foreach ($moreVars as $var) {
      VarDumper::dump($var);
    }
    // Make sure that any subsequent call go to the previously configured
    // handler rather than to the server.
    VarDumper::setHandler($originalHandler);
    if (1 < func_num_args()) {
      return func_get_args();
    }
    return $var;
  }
}
