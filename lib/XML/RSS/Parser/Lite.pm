package XML::RSS::Parser::Lite::Item;

use strict;

our $VERSION = '0.20';

sub new {
	my $class = shift;
	my $self = {
		'title', '',
		'url', '',
		'description', '',
		@_,
	};
	
	bless($self, $class);
	return $self;
}


sub set {
	my $self = shift;

	my %defs = (@_);
	foreach my $k (keys %defs) {
		$self->{$k} = $defs{$k};
	}
}

sub get {
	my $self = shift;
	
	my $want = shift;
	return $self->{$want};
}


package XML::RSS::Parser::Lite;

use strict;
use XML::Parser::Lite;

our $VERSION = '0.20';

sub new { 
	my $class = shift;

	my $parser = new XML::Parser::Lite;
	my $self = {
		parser		=> $parser,
		place		=> '',
		title		=> '',
		url		=> '',
		description	=> '',
		items		=> [],
		latest		=> new XML::RSS::Parser::Lite::Item,
	};

	$self->{parser}->setHandlers(
		Final	=> sub { shift; $self->final(@_) },
		Start	=> sub { shift; $self->start(@_) },
		End	=> sub { shift; $self->end(@_) },
		Char	=> sub { shift; $self->char(@_) },
	);

	bless($self, $class);
	return $self;
}

sub parse {
	my $self = shift;
	my $xml = shift;
	$self->{parser}->parse($xml);
}


sub final { 
	my $self = shift; 

	$self->{parser}->setHandlers(Final => undef, Start => undef, End => undef, Char => undef);
}

sub start {
	my $self = shift;
	my $tag = shift;
	
	$self->{place} .= "/$tag";

	if ($self->{place} eq '/feed/entry')
	{
		$self->{latest} = $self->add if ($self->{place} eq '/feed/entry');
	}
	else 
	{
		$self->{latest} = $self->add if ($self->{place} eq '/rss/channel/item');
	}
}

sub char {
	my $self = shift;
	my $text = shift;
	my $rssPath;

	if (substr($self->{place},0,5) eq '/feed')
	{
		$rssPath = '/feed/entry/';
	}
	else
	{
		$rssPath = '/rss/channel/item/';
	}

	$self->{latest}->set('title', $text) if ($self->{place} eq $rssPath.'title');
	$self->{latest}->set('url', $text) if ($self->{place} eq $rssPath.'link');
	$self->{latest}->set('description', $text) if ($self->{place} eq $rssPath.'description');
	$self->{latest}->set('updated', $text) if ($self->{place} eq $rssPath.'updated');	
	$self->{title} = $text if ($self->{place} eq $rssPath.'title');
	$self->{url} = $text if ($self->{place} eq $rssPath.'link');
	$self->{description} = $text if ($self->{place} eq $rssPath.'description');		
}


sub end { 
	my $self = shift; 
	my $tag = shift;
	
	my $place = $self->{place};
	$place = substr($place, 0, length($place)-length($tag)-1); # regex here causes segmentation fault!
	$self->{place} = $place;
}



sub add {
	my ($self) = shift;
	
	my $it = new XML::RSS::Parser::Lite::Item(@_);
	push(@{$self->{items}}, $it);

	return $it;
}


sub count {
	my $self = shift;
	return scalar @{$self->{items}};
}


sub get {
	my $self = shift;
	
	my $what = shift;
	if ($what =~ /^\d*$/) {
		return @{$self->{items}}[$what];
	}
	
	return $self->{$what};
}


__END__


=head1 NAME

XML::RSS::Parser::Lite - A simple pure perl RSS/Atom parser.


=head1 SYNOPSIS

	use XML::RSS::Parser::Lite;
	use LWP::Simple;
	
	my $xml = get("http://url.to.rss");
	my $rp = new XML::RSS::Parser::Lite;
	$rp->parse($xml);
	
	print $rp->get('title') . " " . $rp->get('url') . " " . $rp->get('description') . "\n";

	for (my $i = 0; $i < $rp->count(); $i++) {
		my $it = $rp->get($i);
		print $it->get('title') . " " . $it->get('url') . " " . $it->get('description') . "\n";
	}


=head1 DESCRIPTION

XML::RSS::Parser::Lite is a simple pure perl RSS/Atom parser. It uses XML::Parser::Lite for its parsing.


=head1 METHODS

=over 4

=item $rp = new XML::RSS::Parser::Lite;

Creates a new RSS/Atom parser.


=item $rp->parse($xml);

Parses the supplied xml.


=item $items = $rp->count();

Returns the number of items in the RSS/Atom file.


=item $value = $rp->get($what);

Integers sent to get returns and XML::RSS::Parser::Lite::Item while the strings title, url, and description returns these
values from the Atom information.


=item $value = $item->get($what);

On an XML::RSS::Parser::Lite::Item this can return the strings title, url, or description.

=back


=head1 AUTHOR

Copyright (c) 2009 Squall Fanjan. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Original Author: Erik Bosrup, erik@bosrup.com

Revision: Squall Fanjan, squall.f@gmail.com

1;
