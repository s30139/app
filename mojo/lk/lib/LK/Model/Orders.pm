package LK::Model::Orders;
use Mojo::Base 'LK::Model';

use LK::Model::Orders::Postgresql;


has 'user';

sub increment {
    my ($self, $id) = @_;

    my $order = LK::Model::Orders::Postgresql->find({
        where => {
            id => $id,
        },
    });
    #$self->dumper($order);

    $order->increment;
    return $order;
}

sub remove {
    my ($self, $id) = @_;

    LK::Model::Orders::Postgresql->update({
        fields => {
            visible => 0,
        },
        where => {
            id => $id,
        },
        debug => 1,
    });

}

sub pay {
    my ($self, $id) = @_;

    LK::Model::Orders::Postgresql->insert({
        values => {
            user_id  => $self->user->id,
            goods_id => $id,
        }
    });

}

sub get {
    my ($self, $id) = @_;

    my @g = LK::Model::Orders::Postgresql->get_orders({
        user_id  => $self->user->id,
        active => 1,
        debug => 1,
    });

    #$self->dumper(\@g);
    return \@g;
}


1;
