package LK::Model::DB::Postgresql;
use Mojo::Base 'LK::Model';

use Scalar::Util qw( blessed );
use Carp;

has 'LOG_TYPE' => 'postgresql';

# SELECT
sub make_select {
    my ($self, $p) = @_;

    # if this custom sql all we need is '$sql' and '@$bind' array
    if ( defined $p->{sql} ) {
        return {
            sql    => $p->{sql},
            bind   => $p->{bind},
            params => $p,
        };
    }

    my $fields = join ' , ', @{ $p->{fields} || $self->FIELDS };
    my ($where, $w_bind) = $self->make_where( $p->{where} );

    my $t = $self->TABLE;
    my $sql = qq{
        SELECT $fields
        FROM   $t
        WHERE  $where
    };

    return {
        sql    => $sql,
        bind   => $w_bind,
        params => $p,
    };
}
sub select {
    my ($self, $p) = @_;

    my $s = $self->make_select( $p );

    my $sth = $self->prepare({ sql => $s->{sql}, type => 'DB_READ', params => $s });
    my $status = $self->execute({ sth => $sth, bind => $s->{bind}, params => $s });
    return undef unless defined $status;

    my $arr = $sth->fetchall_arrayref( {} );
    return wantarray
        ? @{ $arr }
        : shift @{$arr};
    
    return $sth->fetchall_arrayref( {} );
}

# INSERT
sub make_insert {
    my ($self, $p) = @_;

    if ( defined $p->{sql} ) {
        return {
            sql    => $p->{sql},
            bind   => $p->{bind},
            params => $p,
        };
    }

    my @fields = ();
    my $bind;
    while ( my ($field, $value) = each %{ $p->{values} } ) {
        push @fields,  $field;
        push @{$bind}, $value;
    }
    my $fields = join ',', @fields;
    my $values = join ',', map {'?'} @{$bind};

    my $t = $self->TABLE;
    my $sql = qq{
        INSERT INTO $t ( $fields  )
                VALUES ( $values  )
    };

    return {
        sql    => $sql,
        bind   => $bind,
        params => $p,
    };
}
sub insert {
    my ($self, $p) = @_;
    my $v = $p->{values};

    my $s = $self->make_insert($p);

    my $sth = $self->prepare({ sql => $s->{sql}, type => 'DB_WRITE', params => $s });
    my $status = $self->execute({ sth => $sth, bind => $s->{bind}, params => $s });

    return defined $status ? 1 : undef;
}

# UPDATE
sub make_update {
    my ($self, $p) = @_;

    $self->dumper('debug', $p) if defined $p->{debug};

    # if this custom sql all we need is '$sql' and '$bind' array
    if ( defined $p->{sql} ) {
        return {
            sql    => $p->{sql},
            bind   => $p->{bind},
            params => $p,
        };
    }

    # default update
    my $ret_fields = grep { exists $p->{fields}->{$_} } @{$self->FIELDS};
    my $fields = { map { $_ => $p->{fields}->{$_} } grep { exists $p->{fields}->{$_} } @{$self->FIELDS} };


    my @fields;
    my @bind;
    while ( my ($field, $value) = each %{$fields} ) {
        push @fields, $field;
        push @bind  , $value;
    }
    $fields = join ',', map { ' '. $_ .' = ? ' } @fields;

    $self->dumper('$fields', $fields) if defined $p->{debug};


    my ($where, $w_bind) = $self->make_where( $p->{where} );
    my $bind = [ @bind, @{$w_bind} ];

    my $ret_fields = join ',', @fields;

    my $t = $self->TABLE;
    my $sql = qq{
        UPDATE $t
        SET   $fields
        WHERE $where
        RETURNING $ret_fields
    };

    return {
        sql        => $sql,
        bind       => $bind,
        params     => $p,
        ret_fields => \@fields,
    };
}
sub update {
    my ($self, $p) = @_;

    my $s = $self->make_update( $p );
    
    $self->dumper('debug', $s) if defined $p->{debug};

    my $sth = $self->prepare({ sql => $s->{sql}, type => 'DB_WRITE', params => $s });
    my $status = $self->execute({ sth => $sth, bind => $s->{bind}, params => $s });

    # update $self
    ( $status and $self->update_self($sth, $s->{ret_fields}) ) or $self->dumper('NOT blessed', $self, );

    return $status;
}
sub update_self {
    my ($self, $sth, $fields) = @_;

    unless ( blessed $self ) {
        return undef;
    }

    my $ret = $sth->fetchrow_hashref();

    map { $self->{$_} = $ret->{$_} } @{ $fields };
    return 1;
}

# MAKE WHERE
sub make_where {
    my ($self, $where) = @_;

    my $fields = { map { $_ => 1 } @{ $self->FIELDS } };

    my @where  = ();
    my @bind   = ();
    while ( my ($k, $value) = each %{$where} ) {
        next unless defined $fields->{ $k };
        if ( my ($op, $opvalue) = $value =~ m{^([><=]+)(.+)$}o ) {
            push @where , ' '. $k .' '. $op .' ? ';
            push @bind  , $opvalue;
        } else {
            push @where , ' '. $k .' = ? ';
            push @bind  , $value;
        }
    }
    $where = ' TRUE '. ( int @where ? ' AND ' : ' ' );
    $where .= join ' AND ', @where;

    return ( $where, \@bind);
}
# PREPARE
sub prepare {
    my ($self, $p) = @_;

    my $type = $p->{type};
    my $db = $self->$type();

    my $sth = $self->pg->$db->prepare($p->{sql});

    return $sth;
}
# EXECUTE
sub execute {
    my ($self, $p) = @_;
    my $sth  = $p->{sth};
    my $bind = $p->{bind};

    eval {
        $bind
            ? $sth->execute( @{ $bind } )
            : $sth->execute()
        ;
        1;
    }
    or do {
        my $e = $@->message;
        $e =~ s/[\n]/ /g;
        $e =~ s/["]/'/g;
        $e =~ s/\s{2,}/ /g;
        $self->error( 'error', {
            'eval' => $e,
            $p->{params},
        });
        $self->dumper($p, $@->message);
        return undef;
    };

    $self->dumper('debug', $p) if defined $p->{params}{debug};

    return 1;
}

### LOG
sub error {
    my ($self, $msg, $p) = @_;

    $self->logger->error({
        type  => 'postgresql',
        func => (caller(1))[3],
        msg  => $msg,
        'caller' => (caller(2))[3],
        defined $p ? %{$p} : (),
    });

    return 1;
}


1;
