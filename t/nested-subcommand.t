#!perl

use 5.010001;
use strict;
use warnings;

use Test::More 0.98;
use Test::Perinci::CmdLine;

my $gen_args = {
    subcommands => {
        sc1 => {
            url => '/Perinci/Examples/Tiny/foo1',
            subcommands => {
                sc1a => {
                    url => '/Perinci/Examples/Tiny/foo3',
                },
                sc1b => {
                    url => '/Perinci/Examples/Tiny/foo4',
                },
            },
        },
        sc2 => {
            url => '/Perinci/Examples/Tiny/foo2',
            subcommands => {
                sc2a => {
                    url => '/Perinci/Examples/Tiny/foo1',
                },
                sc2b => {
                    url => '/Perinci/Examples/Tiny/foo3',
                },
            },
        },
    },
};
pericmd_run_tests_ok(
    class => 'Perinci::CmdLine::Lite',
    tests => [
        {
            gen_args => $gen_args,
            argv => ['--help'],
            stdout_like => qr/help/i,
        },
    ],
);
done_testing;
