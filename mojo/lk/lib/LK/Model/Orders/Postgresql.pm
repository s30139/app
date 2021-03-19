package LK::Model::Orders::Postgresql;
use Mojo::Base 'LK::Model::DB::Postgresql';


use constant DB_READ  => 'pg_main_read';
use constant DB_WRITE => 'pg_main_write';

sub TABLE { return 'orders' }
=cut
    CREATE TABLE orders (
        id          BIGSERIAL                   ,
        user_id     BIGSERIAL                   ,
        goods_id    BIGSERIAL                   ,
        count       INTEGER                     CHECK (count > 0),
        FOREIGN KEY (user_id)  REFERENCES users (id),
        FOREIGN KEY (goods_id) REFERENCES goods (id)
    );
=cut
sub FIELDS { return
    [
        'id',
        'user_id',
        'goods_id',
        'count',
        'visible',
    ]
};

# accessors
has 'id'      => sub { return $_[0]->{id}    };
has 'count'   => sub { return $_[0]->{count} };


sub get_orders {
    my ($self, $p) = @_;

    my $sql =
    '
        SELECT
            g.name,
            g.price,
            g.desc1,
            o.id,
            o.count,
            o.visible
        FROM orders     o
        JOIN goods      g  ON o.goods_id = g.id
        WHERE
                o.user_id = ?
    '
    . ( $p->{active} ? ' AND o.visible = ?' : '' )
    .'        ORDER BY o.id DESC '
    ;
    $p->{sql} = $sql;
    $p->{bind} = [ $p->{user_id} ];
    push @{ $p->{bind} }, 1 if $p->{active};

    return $self->select($p);
}


sub find {
    my ($self, $p) = @_;

    my $row = $self->select($p);

    my $h = { map { $_ => $row->{$_} } @{ $self->FIELDS } };
    
    return __PACKAGE__->new($h);
}

sub increment {
    my ($self) = @_;

    $self->update({
        fields => {
            count => $self->count + 1,
            notf  => 111,
        },
        where => {
            id => $self->id,
        },
        debug => 1,
    });
}


1;
