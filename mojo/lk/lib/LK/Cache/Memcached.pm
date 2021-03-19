package LK::Cache::Memcached;
use Mojo::Base 'LK::Cache';

# https://metacpan.org/pod/Cache::Memcached::Fast
use lib '/usr/share/perl5';
use Cache::Memcached::Fast;

my $SELF = undef;

sub load { return defined $SELF ? $SELF : $_[0]->new(); }

sub new {
    my ($class, $args) = @_;

    $SELF = bless $args||{}, $class;

    my $srv = shift @{$SELF->config->{'dbs'}};
    $SELF->{memcached} = $SELF->_connect({
        server => $srv->{host} .':'. $srv->{port},
    });

    return $SELF;
}

sub _connect {
    my ($self, $p) = @_;

    my $memcached = undef;
    my $error     = undef;
    eval {
        $memcached = Cache::Memcached::Fast->new({
            servers => [
                'memcached:11211',
            ],
        });
#LK::Base->dumper('eval', $memcached);
        1;
    } or do {
        $error = {
            fail  => 1,
            error => $memcached,
        };
    };

    if (defined $error) {
        $self->error("can't connect");
        return undef;
    }

    $self->info('connect to memcached');

    return $memcached;
}

sub get {
    my $self = shift;
    #return undef unless $self->{redis};

    my $key  = shift;

    my $v = $self->{memcached}->get($key);

    return $v;
}

sub set {
    my $self = shift;
    #return undef unless $self->{redis};

    my $key    = shift;
    my $values = shift;
    my $ttl    = shift;

    my %h = map {
            defined $values->{$_}
                ? ( $_ => $values->{$_} )
                : ( $_ => 'undef')
    } keys %{ $values };

    $self->{memcached}->set($key, \%h );
}


1;
