package LK::Controller::Main;
use Mojo::Base 'LK::Controller';

use LK::Model::Goods;

sub Post {
    my $self = shift;

    return $self->post_data_controller(
        goods => {
            func => 'get_goods',
            params => {
            },
        },
        orders => {
            func => 'get_orders',
            params => {
            },
        },
    );
}

sub get_orders {
    my $self = shift;

    my $user = $self->stash->{__user__};
    my $arr = $user->orders->get;

    return $self->render(
        json => {
            status => 0,
            orders  => $arr,
        }
    );
}

sub get_goods {
    my $self = shift;

    my $arr = LK::Model::Goods->new->get();

    return $self->render(
        json => {
            status => 0,
            goods  => $arr,
        }
    );
}

#
sub pay {
    my $self = shift;
    my $user = $self->stash->{__user__};

    my $id = $self->stash("id");
    my $s = $user->orders->pay($id);

    return $self->render(
        json => {
            status => $s ? 1 : 0,
        }
    );
}
sub remove {
    my $self = shift;
    my $user = $self->stash->{__user__};

    my $id = $self->stash("id");
    my $s = $user->orders->remove($id);

    return $self->render(
        json => {
            status => $s ? 1 : 0,
        }
    );
}
sub increment {
    my $self = shift;
    my $user = $self->stash->{__user__};

    my $id = $self->stash("id");
    my $order = $user->orders->increment($id);

    return $self->render(
        status => 200,
        json => {
            status => 11,
            id     => $order->id,
            count  => $order->count,
        }
    );
}

#
sub Get {
    my $self = shift;
    my $user = $self->stash->{__user__};

    my $js  = $self->template->build( [ { filename => 'main/main.js' } ] );
    my $css = $self->template->build( [ { filename => 'main.css'     } ] );

    my $page = $self->template->build(
        [
            {
                filename => 'header.html',
                params => {
                    css_main => $css,
                },
            },
            {
                filename => 'main/main.html',
                params => {
                    email      => $user->mail,
                    userbalans => $user->balans,
                    js_main    => $js
                },
            },
        ]
    );

    $self->render( text => $page );
}


1;

