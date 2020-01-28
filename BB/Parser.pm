package BB::Parser;
use Moose;

has dom => (
	is			=> 'ro',
	required 	=> 1,
);

has ua => (
	is			=> 'ro',
	required	=> 1,
);

has url => (
	is			=> 'ro',
	required	=> 1,
);

has gallery_name => (
	is			=> 'ro',
	required	=> 0,
);

has _url_abs_p => (
	is		=> 'ro',
	lazy	=> 1,
	builder	=> '_build_url_abs_p',
);

sub _build_url_abs_p
{
	my $self	= shift;
	my $url 	= $self->url;
	my @parts	= split('/', $url );
	return join('/', @parts[0..@parts-2]) . '/';
}

sub get_gallery
{
	my $self	= shift;
	my $name	= $self->_get_gallery_name;
	my $pages	= $self->_get_pages;
	return {
		name	=> $name,
		pages	=> $pages,
	};
}

sub _parse_suit
{
	my $self = shift;
	my $suit = shift;
	my $s 	 = uc $suit;
	return 'NT' 		if $s eq 'N' or $s eq 'NT';
	return '&spades;'	if $s eq 'S';
	return '&hearts;'	if $s eq 'H';
	return '&diams;'	if $s eq 'D';
	return '&clubs;'	if $s eq 'C';
	die;
}

sub _no_html_suits
{
	my $self 	= shift;
	my $contr	= shift;
	$contr		=~ s/&spades;/S/;
	$contr		=~ s/&hearts;/H/;
	$contr		=~ s/&diams;/D/;
	$contr		=~ s/&clubs;/C/;
	return $contr;
}

sub _html_suits
{
	my $self 	= shift;
	my $contr	= shift;
	$contr		=~ s/S/&spades;/;
	$contr		=~ s/H/&hearts;/;
	$contr		=~ s/D/&diams;/;
	$contr		=~ s/C/&clubs;/;
	return $contr;
}
sub _src_to_text_suits
{
	my $self 	= shift;
	my $contr	= shift;
	$contr		=~ s/img\/spades.gif/S/;
	$contr		=~ s/img\/hearts.gif/H/;
	$contr		=~ s/img\/diamonds.gif/D/;
	$contr		=~ s/img\/clubs.gif/C/;
	$contr		=~ s/img\/notrump.gif/N/;
	return $contr;
}

sub _unicode_to_html_suits
{
	my $self 	= shift;
	my $contr	= shift;
	$contr		=~ s/\x{2660}/&spades;/;
	$contr		=~ s/\x{2665}/&hearts;/;
	$contr		=~ s/\x{2666}/&diams;/;
	$contr		=~ s/\x{2663}/&clubs;/;
	return $contr;
}

sub _unicode_to_text_suits
{
	my $self 	= shift;
	my $contr	= shift;
	$contr		=~ s/\x{2660}/S/;
	$contr		=~ s/\x{2665}/H/;
	$contr		=~ s/\x{2666}/D/;
	$contr		=~ s/\x{2663}/C/;
	return $contr;
}
	

1;
