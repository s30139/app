package LK::Model::Session::Postgresql;
use Mojo::Base 'LK::Model::DB::Postgresql';


use constant DB_READ  => 'pg_main_read';
use constant DB_WRITE => 'pg_main_write';

sub TABLE { return 'sessions' }

sub FIELDS { return
    [
        'id',
        'mail',
        'balans',
    ]
};


sub find_session {
    my ($self, $p) = @_;

    my $sql = qq{
        SELECT
            u.id                 AS user_id,
            u.mail               AS user_mail,
            u.balans             AS user_balans,
            s.mail               AS sess_mail,
            s.expire             AS sess_expire,
            s.data               AS sess_data,
            s.userid             AS sess_userid
        FROM sessions     s
        JOIN users        u  ON s.mail = u.mail
        WHERE
                s.userid = ?
            AND s.expire > ?
        LIMIT 1
    };
    $p->{sql}   = $sql;
    $p->{bind} = [ $p->{userid}, $p->{expire} ];

    my $row = $self->select($p);
    return $row;
}


sub compare_password {
    my ($self, $p) = @_;

    my $sql = qq {    
        SELECT  ( password = crypt( ?, password ) ) AS pswmatch
        FROM users WHERE mail = ?
    };

    $p->{sql}   = $sql;
    $p->{bind} = [ $p->{password}, $p->{email} ];

    my $row = $self->select($p);
    return $row;

}


1;
