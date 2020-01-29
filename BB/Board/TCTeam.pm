package BB::Board::TCTeam;
use Moose;

#   Base class for TCTeam NS/EW boards

extends 'BB::Board';

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $data  = shift;
    
    (my $c_height, my $c_suit, my $l_height, my $l_suit, my $declarer, my $result, my $x, my $score) = ('', '', '', '', '', '', '', '');

    my $board_result_1 = $data->{$class->res_name()};
    my $board_result_2 = $board_result_1->{NsScore};

    if ($board_result_2->{WithContract}) {
        $c_height   = $board_result_2->{Height};
        $c_suit     = parse_suit($board_result_2->{Denomination});
        $l_height   = parse_lead_height($board_result_2->{Lead}->{CardHeight});
        $l_suit     = parse_suit($board_result_2->{Lead}->{CardColor});
        $declarer   = parse_declarer($board_result_2->{Declarer});
        $x          = parse_x($board_result_2->{Xx});
        $result     = parse_result($board_result_2->{Overtricks});
    }
    
    if ($data->{ScorePresent}) {
        my $score     = $board_result_2->{Score};
    }
    my $ns_points = $board_result_1->{NsResult};
    my $ew_points = $board_result_1->{EwResult};

    my $parsed = {
        nr          => $data->{'Board'},
        ns          => '??? - ???',
        ew          => '??? - ???',
        c_height    => $c_height,
        c_suit      => $c_suit,
        declarer    => $declarer,
        l_height    => $l_height,
        l_suit      => $l_suit,
        x           => $x,
        result      => $result,
        score       => $score,
        ns_points   => $ns_points,
        ew_points   => $ew_points,
    };
    
    return $class->$orig($parsed);
};

sub parse_suit 
{
    return qw/C D H S NT/[$_[0]];
}

sub parse_lead_height
{
    return qw/2 3 4 5 6 7 8 9 10 J Q K A/[$_[0]];
}

sub parse_declarer
{
    return qw/N S W E/[$_[0]];
}

sub parse_x
{
    return ('', 'x', 'xx')[$_[0]];
}

sub parse_result
{
    my $overtricks = shift;
    if ($overtricks > 0) {
        return '+' . $overtricks;
    }
    elsif ($overtricks == 0) {
        return '=';
    }
    else {
        return "$overtricks";
    }
}

1;
