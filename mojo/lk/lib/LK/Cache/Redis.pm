package LK::Cache::Redis;
use Mojo::Base 'LK::Cache';

# https://metacpan.org/pod/Redis
use lib '/usr/share/perl5';
use Redis;


my $SELF = undef;

sub load { return defined $SELF ? $SELF : $_[0]->new(); }

sub new {
    my ($class, $args) = @_;

    $SELF = bless $args||{}, $class;

    my $srv = shift @{$SELF->config->{'dbs'}};
    $SELF->{redis} = $SELF->_connect({
        server => $srv->{host} .':'. $srv->{port},
    });

    return $SELF;
}

sub config { return $SELF->{'config'} }

sub _connect {
    my ($self, $p) = @_;

    my $redis = undef;
    eval {
        $redis = Redis->new(
            #server => $p->{server},
            server => 'redis:6379',
            reconnect => 1,
        );
        1;
    } or do {
        $self->error("can't connect to redis ", { fail  => 1, });
        return undef;
    };

    $self->info('connect to redis');

    return $redis;
}

sub del {
    my $self = shift;
    my $key  = shift;

    my $v = $self->{redis}->del($key);
}

sub get {
    my $self = shift;
    #return undef unless $self->{redis};

    my $key  = shift;

    my $v = $self->{redis}->hgetall($key);

    return $v;
}

sub set {
    my $self = shift;

#    return undef unless $self->{redis};

    my $key    = shift;
    my $values = shift;
    my $ttl    = shift;

    my %h = map {
            defined $values->{$_}
                ? ( $_ => $values->{$_} )
                : ( $_ => 'undef')
    } keys %{ $values };

    $self->{redis}->hmset($key, %h );
    $self->_expire($key, $ttl );
    #$self->{redis}->set(key, value, ['EX',  seconds], ['PX', milliseconds], ['NX'|'XX'])
}

sub _expire {
    my $self = shift;
    my $key  = shift;
    my $ttl  = shift;
    unless ($ttl) {
        $ttl = 5;
        $self->warn({ msg => 'ttl undef, will set to 5 seconds' });
    }
    $self->{redis}->expire($key, $ttl );

}


1;
