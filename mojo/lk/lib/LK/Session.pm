package LK::Session;
use Mojo::Base 'LK::Base';

use LK::Model::Session;

use Digest::SHA qw(hmac_sha256_hex);

use constant SESS_TTL => 5; # seconds

has 'app';
has 'auth_cookie' => sub { return $_[0]->app->cookie('cid') // 'empty'; };

#my $EXPIRE = 7776000; # 7776000  (60 * 60 * 24 * 90)
my $EXPIRE = 60 * 400; # 20 minute


sub new {
    my $class = shift;
    my $args  = ref $_[0] ? $_[0] : {@_};
    my $self = bless $args, $class;
    return $self;
}

sub update {
    my $self = shift;
    my $row   = shift;
return ;
    my $now = time;
    # while expire-now > 30 days (expire(90 days) / 3), don't touch database
    return if ($row->{sess_expire} - $now) > ($EXPIRE / 3);

    my $sql = qq{
        UPDATE sessions
        SET
            expire = ?
        WHERE
            userid = ?
    };

    my $sth = $self->db->user_write->prepare($sql);
    my @bind = ( $now, $row->{sess_userid} );
    $sth->execute(@bind);

}

sub check {
    my $self = shift;

    #my $cid = $self->app->cookie('cid');
    my $cid = $self->auth_cookie;
    #return undef unless $cid;


    #my $c = $self->cache->del( 'sess'. $cid );

    # check from cache
    my $cache = $self->get_cache();
    return $cache if $cache;
    # sql
    my $sql = $self->check_in_sql();

    # save in cache    
    $self->set_cache($sql);


    return $sql;
}

sub set_cache {
    my $self = shift;
    my $sql  = shift;
    return unless $sql;

    my $cid = $self->auth_cookie;

    my $c = $self->cache->set('sess'. $cid, $sql, SESS_TTL );

    #my $cache = $self->cache->set('sess'. $cid, $sql );
    #my $cache = $self->redis->set('sess'. $cid, $sql, SESS_TTL );

}

sub get_cache {
    my $self = shift;

    #my $cid = $self->app->cookie('cid');
    my $cid = $self->auth_cookie;

    #my $memc = $self->memcache->get('sess'. $cid);

    my $cache = $self->cache->get( 'sess'. $cid );
    #$self->dumper('$cache', $cache);
    return undef unless defined $cache && int(@{ $cache });

    my %h = @{ $cache };

    return \%h;
}

sub check_in_sql {
    my $self = shift;

    my $cid = $self->auth_cookie;
    $self->logger->info({ msg => ' check session', userid => $cid });

    my $sess = LK::Model::Session->find_session({
        userid => $cid,
        expire => int(time - $EXPIRE)
    });

    if ($sess->{user_mail}) {
        $self->update($sess);
        return $sess;
    }

    $self->logger->info({ msg => 'session check failed (not found)', userid => $cid });
    return undef;

}

sub save {
    my ($self, %p) = @_;
    
    my $uid = $p{email} . rand(time);
    $uid = $self->_gen_userid($uid);

    my $row = LK::Model::Session->save({
        mail   => $p{email},
        userid => $uid,
        expire => time,
    });

    return $uid;
}

sub _gen_userid { # 3d10b303cc c3cb9760fd 931892250d aca09acbbb 61b44de765 ffd59cde62 0ca9
    my $self = shift;
    my $uid = shift;
    return hmac_sha256_hex( $uid );
}

sub check_credentials {
    my ($self, %p) = @_;
    my $email    = $p{email};
    my $password = $p{password};


    my $check = LK::Model::Session->compare_password({
        email    => $email,
        password => $password,
    });

    return $check ? 1 : 0;
}


1;