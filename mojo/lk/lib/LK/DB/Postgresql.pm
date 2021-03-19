package LK::DB::Postgresql;
use Mojo::Base 'LK::DB';

use DBI;
use POSIX qw(:signal_h);

my @CONNECT_FIELDS = qw( db_user db_pass dbname host port );


my $SELF = undef;
sub load { return defined $SELF ? $SELF : shift->init(@_); }
sub init {
    my ($class, $args) = @_;
    $SELF = bless $args, $class;
    return $SELF;
}


sub get_config { return $_[0]->{'config'} }

sub _connect {
    my %p = @_;

    my $p_err = 0;
    my $db_user = $p{db_user} or $p_err++;
    my $db_pass = $p{db_pass} or $p_err++;
    
    my $db   = $p{dbname} or $p_err++;
    my $host = $p{host}   or $p_err++;
    my $port = $p{port}   or $p_err++;
    return { error => 'wrong params' } if $p_err;
    
    my $PG_OPTIONS = { AutoCommit=>1, RaiseError=>1, PrintError=>1, 'pg_utf8_strings' => 1 };
    #my $PG_OPTIONS = { AutoCommit=>1, RaiseError=>1, PrintError=>1, 'pg_utf8_strings' => 1, Callbacks => $cb };
    my $utf8_flag = -1;
    my $en_utf8 = 0; # выключим установку флага pg_enable_utf8. в мане -1 это дефолтный и рекомендуемый

    my $error;
    my $dbh;
    my $mask = POSIX::SigSet->new( SIGALRM ); # signals to mask in the handler
    my $action = POSIX::SigAction->new(
        sub { die "connect timeout\n" },        # the handler code ref
        $mask,
        # not using (perl 5.8.2 and later) 'safe' switch or sa_flags
    );
    my $oldaction = POSIX::SigAction->new();
    sigaction( SIGALRM, $action, $oldaction );
    my $failed;
    eval {

        eval {
            alarm(1);
            $dbh = DBI->connect(
                "dbi:Pg:"
                    ."dbname=". $db     .";"
                    ."host=".   $host   .";"
                    ."port=".   $port   .";"
                    ."sslmode=require;"
                ,
                $db_user, $db_pass,
                $PG_OPTIONS
            );
         1;
        } or $failed = 1;

        alarm(0); # cancel alarm (if connect worked fast)
        $error = $@;
        die "$@\n" if $failed; # connect died
        1;
    } or $failed = 1;
    sigaction( SIGALRM, $oldaction );  # restore original signal handler

    if ( $failed ) {
      if ( defined $@ and $@ eq "connect timeout\n" ) { $failed = 2; }
      #else { # connect died }
    }

    $dbh->{pg_enable_utf8} = $utf8_flag if $en_utf8;


    return $failed
        ? { dbh => undef, error => $failed, desc => $error }
        : { dbh => $dbh,  error => undef   };
}

sub _try_connect {
    my $self = shift;
    my %params = @_;

    my $cb = {
        'connect_cached.connected' => sub {
        #connected => sub {
            #shift->do('SET timezone = UTC');
        }
    };


    my %p = map { $_ => $params{$_} } grep { defined $params{$_} } @CONNECT_FIELDS;

    if ( keys %p != int @CONNECT_FIELDS ) {
        $self->error('wrong params', {
            require_fields => (join ' ', @CONNECT_FIELDS),
            %params,
        });
        return undef;
    }

    my $dbh = _connect( %p );

    if ( not defined $dbh or $dbh->{error} ) {
        return undef unless defined $dbh;

        if ( 1 == $dbh->{error} ) {
            my $desc = $dbh->{desc}->message;
            $desc =~ s/\s{2,}/ /g;
            chomp($desc);
            $self->error("failed connect to db", {
                desc   => $desc,
                %params,
            });
            return undef;
        }
        if ( 2 == $dbh->{error} ) {
            $self->error("failed connect to db (TIMEOUT)", {
                %params,
            });
            return undef;
        }
        $self->error($dbh->{error},
            \%params,
        );
        return undef;
    }

    $self->info('success connect to db', {
        %params,
    });


    return $dbh->{dbh};
}

sub _connect_to_db {
    my $self   = shift;

    my $p      = shift;
    my $db     = $p->{db};
    my $config = $p->{config};
    my $params = $p->{params};
    my $dbtype = $p->{dbtype};


    my $key = (caller(1))[3] .'/'. $db .'/'. $dbtype;
    # check that db is avail
    my $cache = $self->_connected( $self->{__config}->{$key} ) if $self->{__config}->{$key};
    return $cache->{dbh} if defined $cache->{dbh};

    # if connect broken ( db not availble or wrong login-password )
    #    skip connect 
    if ( defined $self->{__config}->{$key}->{fail}
        and (($self->{__config}->{$key}->{fail} + $self->{__config}->{$key}->{timeout}) > time) )
    {
        $self->error('skip connect because wait until timeout', $self->{__config}->{$key} );
        return undef;
    }


    # try connect to db
    my %c = (
        db_user   => $params->{db_user} // $config->{$db}->{creds}->{db_user},
        db_pass   => $params->{db_pass} // $config->{$db}->{creds}->{db_pass},
        host      => $params->{host},
        port      => $params->{port},
        dbname    => $db,
        conn_name => $params->{name},
    );
    my $dbh = $self->_try_connect( %c );

    if ($dbh) {
        $self->{__config}->{$key}->{fail} = undef;
        $self->{__config}->{$key}->{dbh}  = $dbh;
        return $dbh;
    }

    $self->error('fail connect', \%c );

    # save time when connect fail
    my $timeout = $params->{reconnect} // $config->{$db}->{reconnect};
    $self->{__config}->{$key}->{timeout} = $timeout;
    $self->{__config}->{$key}->{fail} = time;
    $self->{__config}->{$key}->{dbh}  = undef;

    return undef;
}

# if return undef we will do new connect
sub _connected {
    my $self = shift;
    my $h = shift;

    if ( !$h
        or !$h->{dbh}
        or !$h->{dbh}->ping()
    ) {
        $self->error('dbh ping failed', $h );
        return undef;
    }

    # last check->ping() .
    $self->error('dbh avaiable', $h );
    return { dbh => $h->{dbh} };
}


# USER WRITE DB
sub pg_main_write {
    my $self = shift;
    
    my $db     = 'users';
    my $dbtype = 'rw';
    my $config = $self->get_config;
    my $dbs = $config->{ $db }->{ $dbtype } ;

    foreach my $params ( @{ $dbs } ) {
        my $dbh = $self->_connect_to_db({
            db     => $db,
            config => $config,
            dbtype => $dbtype,
            params => $params,
        });
        return $dbh if $dbh;
    }

    $self->error("all 'write' dbh failed");
    return undef;
}

# USER READ DB
sub pg_main_read {
    my $self = shift;

    my $db     = 'users';
    my $dbtype = 'ro';
    my $config = $self->get_config;
    my $dbs = $config->{$db}->{$dbtype};

    foreach my $params ( @{ $dbs } ) {
        my $dbh = $self->_connect_to_db({
            db     => $db,
            config => $config,
            dbtype => $dbtype,
            params => $params,
        });
        return $dbh if $dbh;
    }

    $self->warn("conect to all 'read' db <". $db ."> failed, try connect to 'write' db");

    warn "FAIL ALL READ dbs";

    #
    my $dbh = $self->pg_main_write;

    unless ($dbh) {
        $self->error("ERROR 'user_write'");
        return undef;
    }

    return $dbh;
}


1;
