package Perinci::CmdLine::Plugin::Debug::DumpArgs;

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
        summary => 'Dump command-line arguments ($r->{args}), by default after argument validation',
        conf => {
            dumper => {
                schema => ['str*', in=>['Data::Dump::Color', 'Data::Dmp']],
                default => 'Data::Dump::Color',
            },
        },
        tags => ['category:debugging'],
    };
}

sub after_validate_args {
    my ($self, $r) = @_;

    my $dumper = $self->{dumper} || 'Data::Dump::Color';
    if ($dumper eq 'Data::Dmp') {
        require Data::Dmp;
        local $Data::Dmp::OPT_DEPARSE = 1;
        Data::Dmp::dd($r->{args});
    } else {
        require Data::Dump::Color;
        Data::Dump::Color::dd($r->{args});
    }

    [200, "OK"];
}

1;
# ABSTRACT:

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

To use, either specify in environment variable:

 PERINCI_CMDLINE_PLUGINS=-Debug::DumpArgs

or in code instantiating L<Perinci::CmdLine>:

 my $app = Perinci::CmdLine::Any->new(
     ...
     plugins => ["Debug::DumpArgs"],
 );

By default this plugin acts after the C<validate_args> event. If you want to
use at different event(s):

 my $app = Perinci::CmdLine::Any->new(
     ...
     plugins => [
         'Debug::DumpArgs@before_validate_args',
         'Debug::DumpArgs@before_output',
     ],
 );

For list of plugin events available, see L<Perinci::CmdLine::Base/"Plugin
events">.


=head1 DESCRIPTION
