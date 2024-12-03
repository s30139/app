package LK;
use Mojo::Base 'Mojolicious', -signatures;
use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use LK::Base;
use LK::Logger;
use LK::DB;
use LK::Session;
use LK::Cache;
use LK::Template;

use LK::Model::User;


sub startup {
    my $self = shift;

    $SIG{__WARN__} = sub {
        chomp(my $msg = shift);
        LK::Logger::logger->warn({ msg => $msg } );
    };

    my $l;
    $self->hook(before_server_start => sub {
        my $self = shift;
        # init logger first, b DB and Cache use logger
        LK::Logger->new( self => $self );

        LK::DB::Postgresql->init({  config => $self->app->config('db')        });
        #LK::Cache::Redis->new({     config => $self->app->config('redis')     });
        #LK::Cache::Memcached->new({ config => $self->app->config('memcached') });

    });

    $self->hook(before_dispatch => sub {
        my $self = shift;
        $l = LK::Logger->new( self => $self );
    });
    $self->helper( logger => sub { $l } );

    $self->hook(after_dispatch => sub {
        my $self = shift;

        $self->tx->res->content->headers->server('Mojo');
        
        if ($self->res->code == 404) {
            $self->logger->warn({msg => 'error 404'});
            $self->render( text => 'Error 404');   
        }
        if ($self->res->code == 500) {
            $self->logger->error({msg => 'error 500'});
            $self->render( text => 'Error 500');   
        }
    });



    # Load configuration from config file
    my $config = $self->plugin('NotYAMLConfig');

    # Configure the application
    #$self->secrets($config->{secrets});


    # without auth
    my $r = $self->routes;
    $r->get('/login')->to('Login#Get');
    $r->post('/login')->to('Login#Post');


    # with auth
    my $auth = $r->under('/' => sub {
        my $self = shift;
        my $sess = LK::Session->new( app => $self );
        my $user = $sess->check;
        if (defined $user) {
            $self->stash( '__user__' => LK::Model::User->new($user) );
            $self->stash( '__sess__' => $sess );
            return 1;
        }

        my $base_url = $self->{app}->config('base_url');
        $self->redirect_to($base_url . '/login');
        return undef;
    });

    #
    $auth->get('/')->to('Main#Get');
    $auth->post('/')->to('Main#Post');

    $auth->post('/api/pay/:id')->to('Main#pay');
    $auth->post('/api/remove/:id')->to('Main#remove');
    $auth->post('/api/increment/:id')->to('Main#increment');
}


1;
