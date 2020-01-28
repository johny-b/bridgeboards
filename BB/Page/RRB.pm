package BB::Page::RRB;
use Moose;

use Data::Dumper;

has url => (
	is		=> 'ro',
	required => 1,
);

has nr => (
	is		=> 'ro',
	required => 1,
);

has ua => (
	is		=> 'ro',
	required => 1,
);

has html => (
	is		=> 'ro',
	lazy	=> 1,
	builder	=> '_build_html',
);

sub _build_html
{
	my $self 		= shift;

	my $url			= $self->url;

	my $board_url	= $url . '/d' . $self->nr . '.txt';
	my $prot_url	= $url . '/p' . $self->nr . '.txt';
	my $css_url		= $url . '/' . 'newstyle.css';

	my $board		= $self->ua->get( $board_url )->res->body;
	$board			=~ s/src=\"img/src=\"$url\/img\//g;
	$board			=~ s/^[^<]*</</;

	my $prot		= $self->ua->get( $prot_url )->res->body;
	$prot			=~ s/src=\"img/src=\"$url\/img\//g;
	$prot			=~ s/<a.+;\">/<a>/g;
	$prot			=~ s/^[^<]*</</;

	my $content	= <<QQQ;
<html>
<head>
	<link href="$css_url" rel="stylesheet">
</head>
<body>
	<div id="boards" class="rounded" style="display:flex;flex-direction:column;align-items:center;">
		<div class="row">
			$board
		</div>
		<div class="row">
			$prot
		</div>
	</div>
</body>
</html>
QQQ

	

	return $content;
}


1;
