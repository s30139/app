package LK::Model::Goods;
use Mojo::Base 'LK::Model';

use LK::Model::Goods::Postgresql;


has 'user';



sub get {
    my $self = shift;

    my @goods = LK::Model::Goods::Postgresql->select();

    return \@goods;
}


1;
