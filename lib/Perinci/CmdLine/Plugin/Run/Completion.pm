package Perinci::CmdLine::Plugin::Run::Completion;

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
        summary => 'Shell completion mode',
        description => <<'_',

This plugin is included by default at a high priority and activated if the
environment indicates shell completion is requested.

_
        conf => {
        },
        prio => 10, # high
        tags => ['category:run-handler', 'category:completion'],
    };
}

sub on_run {
    my ($self, $r) = @_;

    # completion is special case, we delegate to do_completion()
    return [100] unless $self->cmdline->_detect_completion($r);

    local $r->{in_completion} = 1;

    my ($words, $cword);
    if ($r->{shell} eq 'bash') {
        require Complete::Bash;
        require Encode;
        ($words, $cword) = @{ Complete::Bash::parse_cmdline(undef, undef, {truncate_current_word=>1}) };
        ($words, $cword) = @{ Complete::Bash::join_wordbreak_words($words, $cword) };
        $words = [map {Encode::decode('UTF-8', $_)} @$words];
    } elsif ($r->{shell} eq 'fish') {
        require Complete::Bash;
        ($words, $cword) = @{ Complete::Bash::parse_cmdline() };
    } elsif ($r->{shell} eq 'tcsh') {
        require Complete::Tcsh;
        ($words, $cword) = @{ Complete::Tcsh::parse_cmdline() };
    } elsif ($r->{shell} eq 'zsh') {
        require Complete::Bash;
        ($words, $cword) = @{ Complete::Bash::parse_cmdline() };
    } else {
        die "Unsupported shell '$r->{shell}'";
    }

    shift @$words; $cword--; # strip program name

    # @ARGV given by bash is messed up / different. during completion, we
    # get ARGV from parsing COMP_LINE/COMP_POINT.
    @ARGV = @$words;

    # check whether subcommand is defined. try to search from --cmd, first
    # command-line argument, or default_subcommand.
    $self->cmdline->hook_before_parse_argv($r);
    $self->cmdline->_parse_argv1($r);

    if ($r->{read_env}) {
        my $env_words = $self->cmdline->_read_env($r);
        unshift @ARGV, @$env_words;
        $cword += @$env_words;
    }

    #log_trace("ARGV=%s", \@ARGV);
    #log_trace("words=%s", $words);

    # force format to text for completion, because user might type 'cmd --format
    # blah -^'.
    $r->{format} = 'text';

    my $scd = $r->{subcommand_data};
    my $meta = $self->cmdline->get_meta($r, $scd->{url} // $self->cmdline->{url});

    my $subcommand_name_from = $r->{subcommand_name_from} // '';

    require Perinci::Sub::Complete;
    my $compres = Perinci::Sub::Complete::complete_cli_arg(
        meta            => $meta, # must be normalized
        words           => $words,
        cword           => $cword,
        common_opts     => $self->cmdline->common_opts,
        riap_server_url => $scd->{url},
        riap_uri        => undef,
        riap_client     => $self->cmdline->riap_client,
        extras          => {r=>$r, cmdline=>$self->cmdline},
        func_arg_starts_at => ($subcommand_name_from eq 'arg' ? 1:0),
        completion      => sub {
            my %args = @_;
            my $type = $args{type};

            # user specifies custom completion routine, so use that first
            if ($self->cmdline->completion) {
                my $res = $self->cmdline->completion(%args);
                return $res if $res;
            }
            # if subcommand name has not been supplied and we're at arg#0,
            # complete subcommand name
            if ($self->cmdline->subcommands &&
                    $subcommand_name_from ne '--cmd' &&
                         $type eq 'arg' && $args{argpos}==0) {
                require Complete::Util;
                my $subcommands    = $self->cmdline->list_subcommands;
                my @subc_names     = keys %$subcommands;
                my @subc_summaries = map { $subcommands->{$_}{summary} }
                    @subc_names;
                return Complete::Util::complete_array_elem(
                    array     => \@subc_names,
                    summaries => \@subc_summaries,
                    word      => $words->[$cword]);
            }

            # otherwise let periscomp do its thing
            return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
        },
    );

    my $formatted;
    if ($r->{shell} eq 'bash') {
        require Complete::Bash;
        $formatted = Complete::Bash::format_completion(
            $compres, {word=>$words->[$cword]});
    } elsif ($r->{shell} eq 'fish') {
        require Complete::Fish;
        $formatted = Complete::Fish::format_completion($compres);
    } elsif ($r->{shell} eq 'tcsh') {
        require Complete::Tcsh;
        $formatted = Complete::Tcsh::format_completion($compres);
    } elsif ($r->{shell} eq 'zsh') {
        require Complete::Zsh;
        $formatted = Complete::Zsh::format_completion($compres);
    }

    # to properly display unicode filenames
    $self->cmdline->use_utf8(1);

    $r->{res} = [
        200, "OK", $formatted,
        # these extra result are for debugging
        {
            "func.words" => $words,
            "func.cword" => $cword,
            "cmdline.skip_format" => 1,
        },
    ];

    $self->cmdline->_format($r);

    [201, "OK"]; # skip the rest of the event handlers
}

1;
# ABSTRACT:

=for Pod::Coverage ^(.+)$

=head1 DESCRIPTION

A C<Run::> plugin is the main plugin that runs at the C<run> event, which is
fired by Perinci::CmdLine's C<run()> method.

Multiple C<Run::*> plugins can be registered at the C<run> event, but only one
will actually run because they return C<201> code which instruct
Perinci::CmdLine to end the event early.

The C<Run::Completion> plugin handles the tab completion. It only runs if one of
the environment variables (like C<COMP_LINE> in bash) signals that shell
completion is requested. Otherwise the handler declines.


=head1 ENVIRONMENT
