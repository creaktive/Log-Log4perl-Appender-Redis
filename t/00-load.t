#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    use_ok(q(Log::Log4perl::Appender::Redis));
};

diag(qq(Log::Log4perl::Appender::Redis v$Log::Log4perl::Appender::Redis::VERSION, Perl $], $^X));
