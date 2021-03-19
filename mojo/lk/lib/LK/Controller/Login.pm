package LK::Controller::Login;
use Mojo::Base 'LK::Controller';


sub Post {
    my $self = shift;

    return $self->post_data_controller(
        do_login => {
            func => 'action_login',
            params => {
                email    => 1,
                password => 1,
            },
        },


    );
}

sub action_login {
    my $self = shift;
    my $post = shift;
    my $base_url = $self->config('base_url');
    my $status = LK::Session->check_credentials( email => $post->{email}, password => $post->{password} );
    if ($status) {
        #LK::Base->dumper($self);
        my $uid = LK::Session->save( email => $post->{email} );

        $self->cookie(
            cid => $uid,
            { secure => 1, httponly => 1, expires => time + (60 * 60 * 24 ) }
        );
        $self->info('login success', {
            email => $post->{email},
            uid => $uid,
        });
        return $self->render( json => { status => 0, url => $base_url . '/', cid => $uid });;
    }

    $self->warn('login failed', { email => $post->{email} });
    $self->render( json => { status => 1 });
}


sub Get {
    my $self = shift;

    $self->info('login page');
    my $static = $self->template->build( [ { filename => 'login/login.js' }, ] );

    my $page = $self->template->build(
        [
            {
                filename => 'header.html',
            },
            {
                filename => 'login/main.html',
                params => {
                    js_main        => $static,
                    captcha_pubkey => 'erFDgfdsg6LfpUDcUOtvsdgsrJGHDfFDHsdgC9',
                },
            },
        ]
    );

    $self->render( text => $page );
}


1;