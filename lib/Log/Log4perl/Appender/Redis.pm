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

# =method new(%options)
#
# ...
#
# =cut

sub new {
    my ($class, %options) = @_;

    my $self = {
        queue_name  => $options{name}   || 'log4perl',
        server      => $options{server} || 'localhost:6379',
        _redis_conn => undef,
        %options
    };

    return bless $self => $class;
}

# =method log(%params)
#
# ...
#
# =cut

## no critic (ProhibitBuiltinHomonyms)
sub log {
    my ($self, %params) = @_;

    my $redis = $self->{_redis_conn};

    unless ($redis) {
        $redis = Redis->new(
            server      => $self->{server},
            encoding    => undef,
        );

        unless ($redis->ping) {
            croak 'Connection to ', $self->{server}, " failed: $!";
        }

        $self->{_redis_conn} = $redis;
    }

    return $redis->lpush($self->{queue_name}, $params{message});
}

=for Pod::Coverage
DESTROY
log
=cut

sub DESTROY {
    my ($self) = @_;

    if ($self->{_redis_conn}) {
        $self->{_redis_conn}->quit;
    }

    return;
}

=head1 SEE ALSO

=for :list
* L<Log::Log4perl::Appender>
* L<Redis>

=cut

1;
