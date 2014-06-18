#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use tools;

if ( not env_exists('STERILIZE_ENV') ) {
  diag("\e[31mSTERILIZE_ENV \e[32munset\e[0m, skipping");
  exit 0;
}
if ( env_is( 'TRAVIS_BRANCH', 'master' ) ) {
  diag("before_script skipped, TRAVIS_BRANCH=master");
  exit 0;
}
else {
  if ( env_is('COVERAGE_TESTING') ) {
    diag("\e[31mCOVERAGE_TESTING. Skipping blib creation");
    exit 0;
  }
  if ( -e './Build.PL' ) {
    safe_exec( $^X, './Build.PL' );
    safe_exec("./Build");
    exit 0;
  }
  if ( -e './Makefile.PL' ) {
    safe_exec( $^X, './Makefile.PL' );
    safe_exec("make");
    exit 0;
  }

}

