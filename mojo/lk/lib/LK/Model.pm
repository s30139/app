package LK::Model;
use Mojo::Base 'LK::Base';


# log
sub error {
    my ($self, $msg, $p) = @_;

    $self->logger->error({
        type  => 'model',
        func => (caller(1))[3],
        msg  => $msg,
        'caller' => (caller(2))[3],
        defined $p ? %{$p} : (),
    });

    return 1;
}


1;
