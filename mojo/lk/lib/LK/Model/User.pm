package LK::Model::User;
use Mojo::Base 'LK::Model';

use LK::Model::Orders;

has 'id'      => sub { return $_[0]->{user_id}     };
has 'mail'    => sub { return $_[0]->{user_mail}   };
has 'balans'  => sub { return $_[0]->{user_balans} };


sub orders {
    return LK::Model::Orders->new({ user => shift });
}


1;
