package Log::Log4perl::Appender::Redis;
# ABSTRACT: ...

=head1 SYNOPSIS

    ...

=head1 DESCRIPTION

...

=cut

use strict;
use utf8;
use warnings qw(all);

use Carp qw(croak);
use Redis;

## no critic (ProhibitExplicitISA)
our @ISA = qw(Log::Log4perl::Appender);

# VERSION

=method new(%options)

...

=cut

sub new {
    my ($class, %options) = @_;

    my $name = delete $options{name};
    delete @options{qw{l4p_depends_on l4p_post_config_subs min_level}};

    my $self = {
        _buffer         => [],
        _redis_conn     => undef,
    };

    $self->{queue_name} = delete $options{queue_name}   || $name;
    $self->{flush_on}   = delete $options{flush_on}     || '';
    $self->{wrap}       = delete $options{wrap}         || 1000;

    $self->{_redis_opts} = \%options;
    $self->{_redis_opts}{server} ||= 'localhost:6379';

    my $levels = join '|' => values %Log::Log4perl::Level::LEVELS;
    $self->{flush_on} = uc $self->{flush_on};
    if ($self->{flush_on} and $self->{flush_on} !~ /^(?:$levels)$/ix) {
        croak 'Unknown log level: ', $self->{flush_on};
    }

    return bless $self => $class;
}

=method log(%params)

...

=cut

## no critic (ProhibitBuiltinHomonyms)
sub log {
    my ($self, %params) = @_;

    my $redis = $self->{_redis_conn};

    unless ($redis) {
        $redis = Redis->new(%{$self->{_redis_opts}});

        unless ($redis->ping) {
            croak 'Connection to ', $self->{server}, " failed: $!";
        }

        $self->{_redis_conn} = $redis;
    }

    if ($self->{flush_on}) {
        shift @{$self->{_buffer}}
            if $self->{wrap} <= scalar @{$self->{_buffer}};

        push @{$self->{_buffer}} => $params{message};

        if ($params{log4p_level} eq $self->{flush_on}) {
            $redis->lpush($self->{queue_name}, join('', @{$self->{_buffer}}));
            $self->{_buffer} = [];
        }
    } else {
        $redis->lpush($self->{queue_name}, $params{message});
    }

    return;
}

=for Pod::Coverage
DESTROY
=cut

sub DESTROY {
    my ($self) = @_;

    my $redis = $self->{_redis_conn};
    if ($redis) {
        $redis->lpush($self->{queue_name}, join('', @{$self->{_buffer}}))
            if $self->{flush_on} and @{$self->{_buffer}};

        $redis->quit;
    }

    return;
}

=head1 SEE ALSO

=for :list
* L<Log::Log4perl::Appender>
* L<Log::Log4perl::Appender::Stomp> (used as a base for this module)
* L<Redis>

=cut

1;
