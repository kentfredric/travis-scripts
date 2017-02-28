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
  diag("\e[31STERILIZE_ENV is not set, skipping, because this is probably Travis's Default ( and unwanted ) target");
  exit 0;
}
if ( env_is( 'TRAVIS_BRANCH', 'master' ) and env_is( 'TRAVIS_PERL_VERSION', '5.8' ) ) {
  diag("\e[31minstalldeps skipped on 5.8 on master, because \@Git, a dependency of \@Author::KENTNL, is unavailble on 5.8\e[0m");
  exit 0;
}
my (@params) = qw[ --quiet --notest --mirror http://cpan.metacpan.org/ --no-man-pages ];
if ( env_true('DEVELOPER_DEPS') ) {
  push @params, '--dev';
}
if ( env_true('CONFESS') ) {
  cpanm( @params, 'Devel::Confess' );
}
if ( env_is( 'TRAVIS_BRANCH', 'master' ) ) {

  # cpanm( @params, 'Devel::Confess' );
  # $ENV{PERL5OPT} = '-MDevel::Confess';
  if ( "$]" lt "5.014000" ) {
    diag("\e[32mMaster + Perl <5.14\e[0m");
    cpanm( @params, 'Dist::Zilla~<6.0', 'Capture::Tiny', 'Pod::Weaver' );
  }
  else {
    cpanm( @params, 'Dist::Zilla', 'Capture::Tiny', 'Pod::Weaver' );
  }
}
else {
  if ( "$]" lt "5.014000" ) {
    diag("\e[32mScanning for Dzil runtime dep due to perl < 5.014\e[0m");
    my $need_dzil;

    if ( -e 'Makefile.PL' and open my $fh, '<', 'Makefile.PL' ) {
      diag("\e[32mReading Makefile.PL\e[0m");
      while ( my $line = <$fh> ) {
        chomp $line;
        next unless $line =~ /["']Dist::Zilla\S+["']\s*=>/;
        diag("\e[33mDist::Zilla found: \e[0m$line");
        $need_dzil = 1;
        last;
      }
    }
    elsif ( -e 'META.json' and open my $xfh, '<', 'META.json' ) {
      diag("\e[32mReading META.json\e[0m");
      while ( my $line = <$xfh> ) {
        chomp $line;
        if ( $line =~ /\A(\s*)["']prereqs["']\s*:\s*\{/ ) {
          my $prereq_padding = "$1";
          last if $line =~ /\A\Q$prereq_padding\E\}\s*\z/;

          # Skip develop prereqs
          if ( $line =~ /\A(\s+)["']develop["']\s*:\s*\{/ ) {
            my $padding = "$1";
            while ( my $line = <$xfh> ) {
              last if $line =~ /\A\Q$padding\E\},?\s*\z/;
            }
            next;
          }
          if ( $line =~ /["']Dist::Zilla\S+["']\s*:\s*/ ) {
            diag("\e[33mDist::Zilla found: \e[0m$line");
            $need_dzil = 1;
            last;
          }
        }
      }
    }
    if ($need_dzil) {
      cpanm( @params, 'Dist::Zilla~<6.0' );
    }
  }
}
exit 0;
