#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/lib";
use tools;

if ( not env_exists('TRAVIS') ) {
  diag('Is not running under travis!');
  exit 1;
}
if ( not env_exists('STERILIZE_ENV') ) {
  diag("\e[31mSTERILIZE_ENV is not set, skipping, because this is probably Travis's Default ( and unwanted ) target");
  exit 0;
}
if ( env_is( 'TRAVIS_BRANCH', 'master' ) and env_is( 'TRAVIS_PERL_VERSION', '5.8' ) ) {
  diag("\e[31mscript skipped on 5.8 on master\e[32m, because \@Git, a dependency of \@Author::KENTNL, is unavailble on 5.8\e[0m");
  exit 0;
}

if ( env_true('CONFESS') ) {
  $ENV{PERL5OPT} = ( $ENV{PERL5OPT} || '' ) . ' -MDevel::Confess';
}
if ( env_is( 'TRAVIS_BRANCH', 'master' ) ) {
  $ENV{HARNESS_OPTIONS} = 'j100:c';

  # $ENV{PERL5OPT}        = '-MDevel::Confess';
  if ( env_true('COVERAGE_TESTING') ) {
    $ENV{HARNESS_PERL_SWITCHES} = '-MDevel::Cover';
    $ENV{DEVEL_COVER_OPTIONS}   = '-coverage,statement,branch,condition,path,subroutine,-blib,0';
    my $verbose = '';
    if ( env_true('VERBOSE_TESTING') ) {
      $verbose = ' --verbose';
    }
    open my $script, '>', '/tmp/runtest.sh' or die "Cant open test script for write";
    print {$script} 'prove -bl --shuffle --color --recurse --timer ' . $verbose . ' "./t" "./xt" || exit $?' . qq[\n];
    print {$script} 'cover +ignore_re=^x?t/ -report coveralls || exit $?' . qq[\n];
    close $script;
    safe_exec( 'dzil', 'run', 'bash -v /tmp/runtest.sh' );
  }
  else {
    safe_exec( 'dzil', 'test', '--release' );
  }
}
else {
  my @paths = './t';

  if ( env_true('AUTHOR_TESTING') or env_true('RELEASE_TESTING') ) {
    push @paths, './xt';
  }
  my @prove_extra;
  my @prove_base = ( '--shuffle', '--color', '--recurse', '--timer' );
  if ( env_true('VERBOSE_TESTING') ) {
    push @prove_extra, '--verbose';
  }
  elsif ( env_true('COVERAGE_TESTING') ) {

    # noop
  }
  else {
    push @prove_extra, '--jobs', '30';
  }

  if ( env_true('COVERAGE_TESTING') ) {
    my $exit;
    {
      local $ENV{DEVEL_COVER_OPTIONS}   = '-coverage,statement,branch,condition,path,subroutine,-blib,0';
      local $ENV{HARNESS_PERL_SWITCHES} = '-MDevel::Cover';

      #      local $ENV{PERL5LIB} = ( join q[:], $lib, $blib, $archlib, ( split /:/, $ENV{PERL5LIB} || '' ) );
      $exit = safe_exec_nonfatal( 'prove', '-bl', @prove_base, @prove_extra, @paths );
    }
    safe_exec( 'cover', '+ignore_re=^t/', '-report', 'coveralls' );
    exit $exit if $exit;
  }
  else {
    safe_exec( 'prove', '--blib', @prove_base, @prove_extra, @paths );
  }
}
