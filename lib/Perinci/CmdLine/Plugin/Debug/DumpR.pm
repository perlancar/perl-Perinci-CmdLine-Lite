package Perinci::CmdLine::Plugin::Debug::DumpR;

# put pragmas + Log::ger here
use strict;
use warnings;
use Log::ger;
use parent 'Perinci::CmdLine::PluginBase';

# put other modules alphabetically here

# put global variables alphabetically here
# AUTHORITY
# DATE
# DIST
# VERSION

sub meta {
    return {
        summary => 'Dump request stash ($r), by default after action',
        conf => {
            dumper => {
                schema => ['str*', in=>['Data::Dump::Color', 'Data::Dmp']],
                default => 'Data::Dump::Color',
            },
        },
        tags => ['category:debugging'],
    };
}

sub after_action {
    my ($self, $r) = @_;

    my $dumper = $self->{dumper} || 'Data::Dump::Color';
    if ($dumper eq 'Data::Dmp') {
        require Data::Dmp;
        local $Data::Dmp::OPT_DEPARSE = 1;
        Data::Dmp::dd($r);
    } else {
        require Data::Dump::Color;
        Data::Dump::Color::dd($r);
    }

    [200, "OK"];
}

1;
# ABSTRACT:

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

To use, either specify in environment variable:

 PERINCI_CMDLINE_PLUGINS=-Debug::DumpR

or in code instantiating L<Perinci::CmdLine>:

 my $app = Perinci::CmdLine::Any->new(
     ...
     plugins => ["Debug::DumpR"],
 );

By default this plugin acts after the C<action> event. If you want to dump at
a different event:

 my $app = Perinci::CmdLine::Any->new(
     ...
     plugins => [
         'Debug::DumpR@before_end',
     ],
 );

For list of plugin events available, see L<Perinci::CmdLine::Base/"Plugin
events">.


=head1 DESCRIPTION
