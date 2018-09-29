#!/usr/bin/perl
#
# Fortigate config parser
#
# This code reads a Fortigate configuration and parses it into a single
# giant multi-dimension hash array.
# It adds the element "cfgtype" into each section to identify if that
# section is created by a "config" or "edit" statement.
#
# Notes: 
#  - some hash keys will have double-quotes in them, these
#     need to be kept and retained on output
#
# ToDo:
#  - write a function to read a whole config file into a new hash
#
#

use warnings;
use Data::Dumper qw(Dumper);

#
# A recursive config/edit section parser
# Parameters:
#  - input file handle
# Returns: a hash of the sub-level config elements
#
sub fgate_parse_section {
    my $input_file = shift;
    
    my %config;
    while( <$input_file> ){
	chomp;
	return \%config if( /^ *end/ );
	return \%config if( /^ *next/ );
	# set command
	if( /^ *set ([a-zA-Z0-9_\-]+) (.*)$/ ){
	    $config{$1} = $2;
	}
	# Recurse into 'edit arg' statements
	if( /^ +edit (.*)$/ ){
	    $config{$1} = fgate_parse_section( $input_file );
	    $config{$1}{cfgtype} = "edit";
	}
	# Recurse into simple 'config arg' statements
	if( /^ +config ([a-zA-Z0-9_\-]+)$/ ){
	    $config{$1} = fgate_parse_section( $input_file );
	    $config{$1}{cfgtype} = "config";
	}
	# Recurse into 'config arg "param"' statements
	if( /^ +config ([a-zA-Z0-9_\-]+) (.*)$/ ){
	    $config{$1}{$2} = fgate_parse_section( $input_file );
	    $config{$1}{$2}{cfgtype} = "config";
	}
    }
    return \%config;
}

# --------------------------------------------------------------------------------

#
# Open a file and parse it's contents as a Fortigate configuration
# Parameters:
#  - file name
# Returns:
#  - a reference to a hash containing the config
#
sub fgate_parse_file {
    my $filename = shift;
    
    # The config hash where all is stored
    my %config;

    # Track number of top-level config statements, mostly for debugging
    my $top_config_count = 0;

    open( my $input_file, $filename )
	or die "Could not open file '$filename' $!";
    
    while( <$input_file> ){
	chomp;
	
	# Parse each top-level config section
	# Top-level config lines have 2-4 args
	if( /^#/ or /^$/ ){
	    # Ignore comments, blank lines
	    next;
	}
	elsif( /^ *config ([a-zA-Z0-9_\-]+) ([a-zA-Z0-9_\-]+)$/ ){
	    $config{$1}{$2} = fgate_parse_section( $input_file );
	    $config{$1}{$2}{cfgtype} = "config";
	    $top_config_count++;
	}
	elsif( /^ *config ([a-zA-Z0-9_\-]+) ([a-zA-Z0-9_\-]+) ([a-zA-Z0-9_\-]+)$/ ){
	    $config{$1}{$2}{$3} = fgate_parse_section( $input_file );
	    $config{$1}{$2}{$3}{cfgtype} = "config";
	    $top_config_count++;
	}
	# Fourth arg may have quotes
	elsif( /^ *config ([a-zA-Z0-9_\-]+) ([a-zA-Z0-9_\-]+) ([a-zA-Z0-9_\-]+) ([a-zA-Z0-9_\-\"]+)$/ ){
	    $config{$1}{$2}{$3}{$4} = fgate_parse_section( $input_file );
	    $config{$1}{$2}{$3}{$4}{cfgtype} = "config";
	    $top_config_count++;
	}
	else {
	    # Everything else is ignored here, maybe flag it as an error,
	    # or warning, or something else like adding it to the hash.
	    print "Ignoring line: $_\n";
	}
    }

    # Save the top_config_count in the hash itself
    $config{top_config_count} = $top_config_count;

    close( $input_file );

    return \%config;
}

# --------------------------------------------------------------------------------

my $config = fgate_parse_file( $ARGV[0] );

# debug
#print "Top level config statement count: $top_config_count\n";

# debug
print Dumper $config;

