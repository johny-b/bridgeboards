package BB::Board;
use Moose;

#   Generic board.
#   Stores some data (supplied in inheriting classes),
#   provides convinient accessors.
#
#   my $board = BB::Board->new(
#       nr => 7,
#       ns => 'FOO - BAR',
#       ew => 'BAZ - BAZ',
#       c_height => 3,
#       c_suit => 'H',      # NT/S/H/D/C/''
#       declarer => 'W',
#       l_height => 'A',
#       l_suit => 'D',
#       result => '-1',
#       score => -100,
#   );

for my $name (qw/nr ns ew c_height c_suit declarer l_height l_suit result score/) { 
    has $name => ( is => 'ro', required => 1);
}

sub caption_score 
{
    my $self    = shift;
	my $score   = $self->score;
	$score      =~ s/^-$/&mdash;/;
    return $score;
}

sub caption
{
    my $self    = shift;
	my $caption	= 'Board ' . $self->nr . ('&nbsp;' x 3) . $self->caption_score;
    return $caption;
}

sub html_summary
{
    my $self = shift;
    my @parts = (
        $self->html_contract,
        $self->declarer,
        $self->html_lead,
        $self->result,
        $self->score,
    );
    return join ( '', ( map { "<td>$_&nbsp;&nbsp;</td>" } @parts) );
}

sub html_contract
{
    my $self = shift;
    my $suit = $self->_as_html($self->c_suit);
    return $self->c_height . $suit;
}

sub html_lead
{
    my $self = shift;
    my $suit = $self->_as_html($self->l_suit);
    return $self->l_height . $suit;
}

sub contract
{
    my $self = shift;
    return $self->c_height . $self->c_suit;
}

sub lead
{
    my $self = shift;
    return $self->l_height . $self->l_suit;
}

sub _as_html
{
	my $self = shift;
	my $suit = shift;
	my $s 	 = uc $suit;
	return 'NT' 		if $s eq 'NT';
	return '&spades;'	if $s eq 'S';
	return '&hearts;'	if $s eq 'H';
	return '&diams;'	if $s eq 'D';
	return '&clubs;'	if $s eq 'C';
	return $suit;
}


1;
