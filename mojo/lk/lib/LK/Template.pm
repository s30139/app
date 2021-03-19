package LK::Template;
use Mojo::Base 'LK::Controller';

use lib '/usr/share/perl5';
use HTML::Template;
use utf8;

use HTML::Packer;
use JavaScript::Packer;
use CSS::Packer;

my $PATH = '/mojo/lk/templates/';
my $DO_NOT_CACHE = 1;

sub ctrl {
    my $self = shift;
    if(@_) {
        $self->{ctrl} = $_[0];
    }
    return $self->{ctrl};
}

my $SELF;
sub new {
    my ($class, %args) = @_;
    $SELF = bless \%args, $class;
    return $SELF;
}

sub load {
    if ($SELF) {
        $SELF->ctrl( $_[1] );
        return $SELF;
    }
    return $_[0]->new( ctrl => $_[1], @_);
}

sub build {
    my ($self, $p) = @_;
    my $out = '';

    foreach ( @{ $p } ) {
        next unless $_->{filename};
        my $tmpl = $self->build_template( $_->{filename} );
        if ( $_->{params} ) {
            while ( my($k,$v) = each %{ $_->{params} } ) { # $vmenu->param( email => $user->mail );
                $tmpl->param( $k => $v );
            }
        }
        # end prepare template
        $out .= $tmpl->output;
    }

    # all templates done
    return $out
}

sub build_template {
    my $self = shift;
    my $tmpl = shift;

    return $self->not_cache($tmpl) if $self->dont_cached;

    return $self->{__cached}->{$tmpl} if $self->{__cached}->{$tmpl};

    $self->{__cached}->{$tmpl} = $self->cached( $tmpl );

    return $self->{__cached}->{$tmpl};
}

sub dont_cached {
    return 1 if $DO_NOT_CACHE;

    my $c = $_[0]->ctrl->tx->req->cookie('minify');
    return ($c and $c->value eq 'dont') ? 1 : 0;
}

sub not_cache {
    my $self = shift;
    my $tmpl = shift;
    my $content = $self->_content($tmpl);
    return HTML::Template->new( scalarref => \$content, utf8 => 1 );
}
# return object Html::Template
sub cached {
    my $self = shift;
    my $tmpl = shift;

    $self->ctrl->logger->info( msg => 'make_cached_template', file => $PATH.$tmpl );
    my $content = $self->minify( $tmpl );
    return HTML::Template->new( scalarref => \$content, utf8 => 1 );
}

# minify
sub _content {
    my $self = shift;
    my $tmpl = shift;

    my $file = $PATH.$tmpl;
    open(my $fh, "<:encoding(UTF-8)", $file) or die "cannot open file $file";
    my $c;
    {
        local $/;
        $c = <$fh>;
    }
    close($fh);

    return $c;
}

sub minify {
    my $self = shift;
    my $tmpl = shift;

    return $self->minify_js($tmpl)   if $tmpl =~ m/\.js$/         ;
    return $self->minify_js($tmpl)   if $tmpl =~ m/\.jstemplate$/ ;
    return $self->minify_css($tmpl)  if $tmpl =~ m/\.css$/        ;
    return $self->minify_html($tmpl) if $tmpl =~ m/\.html$/       ;
}

sub minify_js {
    my $self = shift;
    my $tmpl = shift;

    my $content = $self->_content($tmpl);

    JavaScript::Packer->minify(
        \$content,
        {
            compress => 'clean',
        },
    );

    return $content;
}

sub minify_css {
    my $self = shift;
    my $tmpl = shift;

    my $content = $self->_content($tmpl);

    CSS::Packer->minify(
        \$content,
        {
            remove_comments =>1,
            remove_newlines =>1,
        },
    );

    return $content;
}
sub minify_html {
    my $self = shift;
    my $tmpl = shift;

    my $content = $self->_content($tmpl);

    HTML::Packer->minify(
        \$content,
        {
            remove_comments => 1,
            remove_newlines => 1,
            do_stylesheet   => 'minify', # 'pretty' 'minify'
            do_javascript   => 'clean',
        }
    );

    return $content;
}


1;
