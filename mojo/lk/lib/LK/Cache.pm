package LK::Cache;
use Mojo::Base 'LK::Base';


use LK::Cache::Redis;
use LK::Cache::Memcached;


sub warn {
    my ($self, $msg, $p) = @_;
    delete $p->{db_pass} if defined $p and $p->{db_pass};

    $self->logger->warn({
        type => 'cache',
        func => (caller(1))[3],
        msg => $msg,
        'caller' => (caller(2))[3],
        defined $p ? %{$p} : (),
    });
    return 1;
}

sub error {
    my ($self, $msg, $p) = @_;
    delete $p->{db_pass} if defined $p and $p->{db_pass};

    $self->logger->error({
        type => 'cache',
        func => (caller(1))[3],
        msg => $msg,
        'caller' => (caller(2))[3],
        defined $p ? %{$p} : (),
    });
    return 1;
}

sub info {
    my ($self, $msg, $p) = @_;
    delete $p->{db_pass} if defined $p and $p->{db_pass};

    $self->logger->info({
        type => 'cache',
        func => (caller(1))[3],
        msg => $msg,
        'caller' => (caller(2))[3],
        defined $p ? %{$p} : (),
    });
    return 1;
}


1;
