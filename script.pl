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

if ( env_is( 'TRAVIS_BRANCH', 'master' ) ) {
  $ENV{HARNESS_OPTIONS} = 'j100:c';

  # $ENV{PERL5OPT}        = '-MDevel::Confess';
  if ( env_true('COVERAGE_TESTING') ) {
    open my $script, '>', '/tmp/runtest.sh' or die "Cant open test script for write";
    print {$script} 'libdir="${PWD}/lib"' . qq[\n];
    print {$script} 'execcmd="perl -I${libdir} -MDevel::Cover=-coverage,statement,branch,condition,path,subroutine"' . qq[\n];
    print {$script} 'prove --exec="$execcmd" --shuffle --color --recurse --timer --jobs 1 "./t" "./xt" || exit $?' . qq[\n];
    print {$script} 'cover +ignore_re=^x?t/ -report coveralls || exit $?' . qq[\n];
    close $script;
    ## TODO: Figure out how to do coverage with blib/ existing
    ## Without it making coverage entirely useless.
    safe_exec( 'dzil', 'run', '--nobuild', 'bash', '/tmp/runtest.sh' );
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
  if ( env_true('COVERAGE_TESTING') ) {
    my $lib     = Cwd::getcwd() . '/lib';
    my $blib    = Cwd::getcwd() . '/blib/lib';
    my $archlib = Cwd::getcwd() . '/blib/arch';

    my $exit;
    {
      local $ENV{DEVEL_COVER_OPTIONS} = '-coverage,statement,branch,condition,path,subroutine,-blib,0';
      local $ENV{PERL5LIB} = ( join q[:], $lib, $blib, $archlib, ( split /:/, $ENV{PERL5LIB} || '' ) );
      $exit = safe_exec_nonfatal( 'prove', '--exec perl -MDevel::Cover',
        '--shuffle', '--color', '--recurse', '--timer', '--jobs', 1, @paths );
    }
    safe_exec( 'cover', '+ignore_re=^t/', '-report', 'coveralls' );
    exit $exit if $exit;
  }
  else {
    safe_exec( 'prove', '--blib', '--shuffle', '--color', '--recurse', '--timer', '--jobs', 30, @paths );
  }
}
