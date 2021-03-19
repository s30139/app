package LK::Model::Goods::Postgresql;
use Mojo::Base 'LK::Model::DB::Postgresql';

use constant DB_READ  => 'pg_main_read';
use constant DB_WRITE => 'pg_main_write';


sub TABLE { return 'goods' }
=cut
    CREATE TABLE goods (
        id          BIGSERIAL                              ,
        name        character varying(1024)                ,
        amount      numeric(19,2)                default 0 ,
        comment     character varying(1024)
    );
=cut
sub FIELDS { return
    [
        'id',
        'name',
        'price',
        'desc1',
    ]
};


1;
