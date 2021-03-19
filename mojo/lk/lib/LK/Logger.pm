package LK::Logger;
use Mojo::Base 'LK::Base';

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
#$Data::Dumper::Varname = '';
#$Data::Dumper::Indent = 0;

BEGIN {
    
}


my $SELF = undef;

sub new {
    my ($class, %p) = @_;
    my $args = { self => $p{self} };
    $SELF = bless $args, $class;
    return $SELF;
}

sub logger { return $SELF }

sub l {

    #print STDERR Dumper( \@_ );


    my $cnt = int(@_);

    my $self  = shift;
    my $level = shift;
    my $m     = shift or return;
 
#print STDERR Dumper( \@_ );

    my @m;
    push @m, '"level":"'. $level .'"';
    push @m, '"cnt":"'.   $cnt   .'"';

    if ( defined $self->{self}->{tx} ) {
        push @m, '"req_url":"'. $self->{self}->tx->req->url->path->{path} .'"';
        push @m, '"req_id":"'.  $self->{self}->tx->req->request_id        .'"';

        my $fsessid = $self->{self}->tx->req->cookie('fsessid');
        push @m, '"fsessid":"'. $fsessid->value .'"' if defined $fsessid;
    }

    while ( my ($k,$v) = each %{$m} ) {
        $v = defined $v ? $v : 'not_defined';
        if (ref $v) {
            {
                local $Data::Dumper::Indent   = 0;
                local $Data::Dumper::Sortkeys = 1;
                local $Data::Dumper::Varname;
                $v = Dumper($v);
                $k = $k .'_dump';
            }
        }
        push @m, '"'. $k .'":"'. $v .'"' ;
    }
    my $msg = join ',', @m;
    print STDERR '{'. $msg .'}'."\n" ;
};



sub warn  { l(shift, 'warn',  @_ ); }

sub error { l(shift, 'error', @_ ); }

sub info  { l(shift, 'info',  @_ ); }

sub debug { l(shift, 'debug', @_ ); }



1;
