package LK::Model::Session;
use Mojo::Base 'LK::Model';

use LK::Model::Session::Postgresql;


has 'user';

sub find_session {
    my ($self, $p) = @_;

    my $sess = LK::Model::Session::Postgresql->find_session($p);

    return $sess;
}

sub compare_password {
    my ($self, $p) = @_;

    my $row = LK::Model::Session::Postgresql->compare_password({
        email    => $p->{email},
        password => $p->{password},
    });

    return $row->{pswmatch} ? 1 : 0;
}

sub save {
    my ($self, $p) = @_;

    my $row = LK::Model::Session::Postgresql->insert({
        values => {
            id     => 'pg',
            mail   => $p->{mail},
            userid => $p->{userid},
            expire => $p->{expire},
        },
    });
$self->dumper($row);
    return 1;
}

1;
