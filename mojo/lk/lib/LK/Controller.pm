package LK::Controller;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use JSON::XS;

sub dumper { shift; LK::Base->dumper((caller(1))[3], @_); }
sub template { LK::Template->load(@_); }



sub check_post_data {
    my ($self, $post, $validate) = @_;

    foreach my $k ( keys %{$validate} ) {
        return undef unless exists $post->{$k};
    }

    return 1;
}

# redifine this in controller
sub Post {
    my $self = shift;
    $self->warn( 'post action not set in controller', {
        type => 'controller',
        controller => ref $self,
        %{ $self->req->params->to_hash },
    });
    $self->render( status => 404, json => { error => 404 } );
}

sub action {
    my $self = shift;

    my $post = $self->req->params->to_hash;
    
    if ( my $action = $post->{'action'} ) {
        return $action;        
    }

    my $data;
    eval{
        $data = decode_json($self->req->body);
        1;
    };
    if ($@) {
        my $err = $@->message;
        $err =~ s/\n|\s{2,}/ /g;
        $self->error('post body json parse error ', {
            body  => $self->req->body,
            error => $err,
        });
        return undef;
    }
    if ( my $action = $data->{'action'} ) {
        return $action;        
    }

    #
    return undef;
}

sub post_data_controller {
    my $self = shift;
    my %dispach = @_;


    my $action = $self->action;
    my $post = $self->req->params->to_hash;
    unless ( defined $action ) {
        $self->info( "undefined 'action'", {
            controller => ref $self,
            post => $post,
        });
        $self->render( json => { error => 1 } );
        return;
    }

    my $validate = $dispach{ $action }->{params};

    unless ( $self->check_post_data($post, $validate) ) {
        $self->warn( "post data params failed", {
            controller => ref $self,
            %{ $post },
            check_post_data => $validate,
        });
        return $self->render( json => { error => 1 } );
    }

    my $handler  = $dispach{ $action }->{func};
    if ( $handler ) {
        $self->info( "route to POST handler", {
            handler => $handler,
            controller => ref $self,
            %{ $post },
        });
        $self->$handler( $post );
        return 1;
    }

    $self->warn( 'POST action not found', {
        controller => ref $self,
        %{ $self->req->params->to_hash },
    });

    $self->render( status => 200, json => { error => 'Ahtung! Do nothing! WTF?', error => 1, } );
}

# logger
sub warn {
    my ($self, $msg, $p) = @_;
    delete $p->{db_pass} if defined $p and $p->{db_pass};

    $self->logger->warn({
        type => 'controller',
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
        defined $p ? %{$p} : (),
        msg       => $msg,
        type      => 'controller',
        func      => (caller(1))[3],
        'caller'  => (caller(2))[3],
        'package' => ref $self,
    });
    return 1;
}

sub info {
    my ($self, $msg, $p) = @_;
    delete $p->{db_pass} if defined $p and $p->{db_pass};

    $self->logger->info({
        type => 'controller',
        func => (caller(1))[3],
        msg => $msg,
        'caller' => (caller(2))[3],
        defined $p ? %{$p} : (),
    });
    return 1;
}


1;