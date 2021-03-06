#!/usr/bin/perl
package IkiWiki::Plugin::concon;
use warnings;
use strict;
=head1 NAME

IkiWiki::Plugin::concon - define field values by context

=head1 VERSION

This describes version B<1.20120105> of IkiWiki::Plugin::concon

=cut

our $VERSION = '1.20120105';

=head1 DESCRIPTION

Rather than having just global field-values or per-page field-values,
this allows one to define field-values for sets of pages that
match a given pattern.

See doc/plugin/contrib/concon.mdwn for documentation.

=head1 PREREQUISITES

    IkiWiki
    Config::Context

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    http://github.com/rubykat

=head1 COPYRIGHT

Copyright (c) 2009-2011 Kathryn Andersen

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use IkiWiki 3.00;
use Config::Context;

my $ConfObj;
my %Cache = ();

sub import {
	hook(type => "getopt", id => "concon",  call => \&getopt);
	hook(type => "getsetup", id => "concon",  call => \&getsetup);
	hook(type => "checkconfig", id => "concon", call => \&checkconfig);

	IkiWiki::loadplugin('field');
	IkiWiki::Plugin::field::field_register(id=>'concon',
					       get_value=>\&concon_get_value,
					       first=>1);
}

sub getopt () {
	eval {use Getopt::Long};
        error($@) if $@;
        Getopt::Long::Configure('pass_through');
        GetOptions("concon_file=s" => \$config{concon_file});
}

sub getsetup () {
	return
		plugin => {
			description => "Use Config::Context configuration file to set context-sensitive options",
			safe => 1,
			rebuild => undef,
		},
		concon_file => {
			type => "string",
			example => "/home/user/ikiwiki/site.cfg",
			description => "file where the configuration options are set",
			safe => 0,
			rebuild => 0,
		},
		concon_str => {
			type => "string",
			example => "<Page foo>local_css = foo.css</Page>",
			description => "set the configuration options directly here",
			safe => 0,
			rebuild => 0,
		},
}

sub checkconfig () {
    if (!$config{concon_file}
	    and !$config{concon_str})
    {
	error("concon: must define either concon_file or concon_str");
	return 0;
    }
    if ($config{concon_file}
	and !-f $config{concon_file})
    {
	error("$config{concon_file} not found");
	return 0;
    }
    my %cc_opts = (
	driver => 'ConfigGeneral',
	match_sections => [
	    {
		name          => 'Page',
		section_type  => 'page',
		match_type    => 'path',
	    },
	    {
		name          => 'PageMatch',
		section_type  => 'page',
		match_type    => 'regex',
	    },
	    {
		name          => 'File',
		section_type  => 'file',
		match_type    => 'path',
	    },
	    {
		name          => 'FileMatch',
		section_type  => 'file',
		match_type    => 'regex',
	    },
	],

    );
    if ($config{concon_file})
    {
	$ConfObj = Config::Context->new
	(
	    file => $config{concon_file},
	    %cc_opts
	);
    }
    else
    {
	$ConfObj = Config::Context->new
	(
	    string => $config{concon_str},
	    %cc_opts
	);
    }

    return 1;
}

sub concon_get_value {
    my $field_name = shift;
    my $page = shift;
    my %params=@_;

    if (!exists $Cache{$page})
    {
	my $page_file=$pagesources{$page} || return;

	my %config = $ConfObj->context(page=>"/${page}", file=>$page_file);
	$Cache{$page} = \%config;
    }

    if (exists $Cache{$page}->{$field_name})
    {
	return $Cache{$page}->{$field_name};
    }
    return undef;
} # concon_get_value

1;
