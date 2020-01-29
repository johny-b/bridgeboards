package BB::Board;
use Moose;

#   Generic board.
#   Stores some data (supplied in inheriting classes),
#   provides convinient accessors.
#
#   my $board = BB::Board->new(
#       nr          => 7,
#       ns          => 'FOO - BAR',
#       ew          => 'BAZ - BAZ',
#       c_height    => 3,
#       c_suit      => 'H',      # 'NT'/'S'/'H'/'D'/'C'/''
#       x           => '',     # ''/'x'/'xx'
#       declarer    => 'W',
#       l_height    => 'A',
#       l_suit      => 'D',
#       result      => '-1',
#       score       => -100,
#       ns_points   => '36%',
#       ew_points   => '64%',
#   );

for my $name (qw/nr ns ew c_height c_suit x declarer l_height l_suit result score ns_points ew_points/) { 
    has $name => ( is => 'rw', required => 1);
}

sub caption_score 
{
    my $self    = shift;
	my $score   = $self->_with_sign($self->ns_points);
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
    return $self->c_height . $suit . $self->x;
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
    return $self->c_height . $self->c_suit . $self->x;
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

sub signed_ns_points
{
    my $self = shift;
    return $self->_with_sign($self->ns_points);
}

sub signed_ew_points
{
    my $self = shift;
    return $self->_with_sign($self->ew_points);
}

sub _with_sign
{
    my $self    = shift;
    my $val     = shift;
    if ($val > 0) {
        return '+' . $val;
    }
    elsif ($val < 0) {
        return "$val";
    }
    else {
        return $val;
    }
}

1;
