package LK::Base;
use Mojo::Base 'Mojolicious', -signatures;

use LK::Logger;
use LK::DB;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;


sub dumper {
    shift;
#                    #  0         1       2      3            4
#             my ($package, $filename, $line, $subroutine, $hasargs,
#
#                #  5          6          7            8       9         10
#                $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash)
#              = caller($i);
#            (caller(0))[0] .'->'. (caller(0))[1] .'->'. (caller(0))[2] .'->'. (caller(0))[3],
#            (caller(1))[0] .'->'. (caller(1))[1] .'->'. (caller(1))[2] .'->'. (caller(1))[3],
#            (caller(2))[0] .'->'. (caller(2))[1] .'->'. (caller(2))[2] .'->'. (caller(2))[3],
#            (caller(3))[0] .'->'. (caller(3))[1] .'->'. (caller(3))[2] .'->'. (caller(3))[3],
    print STDERR Dumper(
        [
            (caller(1))[3],
            @_ ,
        ]
    );
}

sub logger { return LK::Logger->logger; }

sub db     { return LK::DB::Postgresql->load; }
sub pg     { return LK::DB::Postgresql->load; }
#sub mysql { return LK::DB::Mysql->load;      }

sub redis    { return LK::Cache::Redis->load;     }
sub memcache { return LK::Cache::Memcached->load; }


1;
