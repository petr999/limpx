#!/usr/bin/env perl
#
####### APP::LIMPX::UTIL - COMMON STUFF FOR APP::LIMPX MODULES #########
#
# ABSTRACT: Keep common variables and common subroutines for app
#
# Copyright (C) 2016 No One
# All rights reserved.
#
package App::Limpx::Util;

# Helps you to behave
use strict;
use warnings;

### MODULES ###
#
# Finds files by rules
require File::Find::Rule;

# Dies on I/O errors
use autodie;

# Dies more nicely
require Carp;

# Able to load application's own modules and concatenate paths making
# them absolute, too
require lib::abs;

# Converts between charsets
require Convert::Cyrillic;

# Cleans and normalizes html code
require HTML::Tidy;

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# Directory that keeps data to work with
# Requires  : lib::abs module
# Throws    : If data directory is not found
my $LIMBXXX = 'html/limbxxx';
$LIMBXXX = lib::abs::path("../../../../../$LIMBXXX");
const $LIMBXXX => $LIMBXXX;

# Base URL to fetch images from
const my $BASE_URL => 'http://85.113.35.70:85';

# Directory that keeps templates to render
# Requires  : lib::abs module
# Throws    : If data directory is not found
my $TMPL_DNAME = 'share/tmpl';
$TMPL_DNAME = lib::abs::path("../../../$TMPL_DNAME");
const $TMPL_DNAME => $TMPL_DNAME;

# Directory that keeps settings and configuration
# Requires  : lib::abs module
# Throws    : If data directory is not found
my $ETC_DNAME = 'etc';
$ETC_DNAME = lib::abs::path("../../../$ETC_DNAME");
const $ETC_DNAME => $ETC_DNAME;

# File that keeps settings for HTML::Tidy
# Depends   :   On $ETC_DNAME constant
my $TIDYRC_FNAME = 'tidyrc';
const $TIDYRC_FNAME => "$ETC_DNAME/$TIDYRC_FNAME";

# Directory that keeps collate stuff
# Requires  : lib::abs module
# Throws    : If downloaded stuff directory is not found
my $COLLATE_DNAME = 'courses-collate';
$COLLATE_DNAME = "$LIMBXXX/$COLLATE_DNAME";
const $COLLATE_DNAME => $COLLATE_DNAME;

### PACKAGE LEXICAL VARIABLES
#
# Tidyfier of html; assigned (cached) on demand with subroutine
my $TIDY;

### SUBS ###
#
# Function
# Lists regular files in given directory
# Takes     :   Str name of directory to l;ist files in
# Requires  :   File::Find::Rule module; autodie module?
# Throws    :   On I/O errors?
# Returns   :   Array[Str] names of files
sub list_fnames {
    my $dname = shift;

    # Prepare rule: list regular files in directory
    my $rule = File::Find::Rule->file();
    $rule->mindepth(1);
    $rule->maxdepth(1);

    # List topics' files in directory with predefined rule
    my @flist = $rule->in($dname);

    return @flist;
}

# Function
# Returns directory of 'html' files
# Takes     :   n/a
# Depends   :   On $LIMBXXX constant
# Returns   :   Str LIMBXXX constant
sub get_limbxxx {
    return $LIMBXXX;
}

# Function
# Gets base url
# Takes     :   n/a
# Depends   :   On $BASE_URL constant
# Returns   :   Str base url
sub get_base_url {
    return $BASE_URL;
}

# Function
# Gets templates directory name
# Takes     :   n/a
# Depends   :   On $TMPL_DNAME constant
# Returns   :   Str templates directory name
sub get_tmpl_dname {
    return $TMPL_DNAME;
}

# Function
# Converts string from cyrillic to encoding suitable for directory or
# file name [-a-z0-9]
# Takes     :   Str string to convert
# Requires  :   Convert::Cyrillic module
# Returns   :   Str converted line
sub charset_convert {
    my ( $str => $dots_allowed ) = @_;
    $dots_allowed = '' unless defined $dots_allowed;

    # Convert charset
    $str = Convert::Cyrillic::cstocs( 'utf8' => 'vol', $str, );

    # Unify with lowercase
    $str = lc $str;

    # Delete unwanted characters
    if ($dots_allowed) {
        $str =~ s{[^-\w\d\s\.]}{}g;
    }
    else {
        $str =~ s{[^-\w\d\s]}{}g;
    }
    $str =~ s{^[\s\.]+|[\s\.]+$}{}g;

    # Clean up from spaces in the end and in the beginning
    $str =~ s{\s}{-}g;
    return $str;
}

# Function
# Dies on errors processing template
# Takes     :   HashRef[Str] with keys as follows:
#                   - "text"    :   The source code of the program
#                                   fragment that failed;
#                   - "error"   :   The text of the error message ($@)
#                                   generated by eval.  The text has
#                                   been modified to omit the trailing
#                                   newline and to include the name of
#                                   the template file (if there was
#                                   one). The line number counts from
#                                   the beginning of the template, not
#                                   from the beginning of the failed
#                                   program fragment.
#                   - "lineno"  :   The line number of the template at
#                                   which the program fragment
# Requires  :   Carp module
# Throws    :   Always
# Outputs   :   Rendering error to STDERR
# Returns   :   n/a
sub croak_on_tmpl {
    my $err_hash = shift;

    # Get scalar valuyes for message
    my $text   = $err_hash->{'text'};
    my $error  = $err_hash->{'error'};
    my $lineno = $err_hash->{'lineno'};

    # Concatenate message and output
    my $msg = "$lineno: '$error'!\nfor '$text'";
    Carp::croak($msg);
}

# Function
# Gets directory name of 'collate' stuff, the human/machine-readable
# courses' contents
# Takes     :   n/a
# Depends   :   On $COLLATE_DNAME constant
# Returns   :   Str name of directory of 'collate' stuff
sub get_collate_dname {
    return $COLLATE_DNAME;
}

# Function
# Gets html tidifier object
# Takes     :   n/a
# Depends   :   On $TIDY package lexical, $TIDYRC_FNAME constant
# Requires  :   HTML::Tidy module
# Throws    :   On object initialisation failure
# Returns   :   HTML::Tidy object according to configuration given
sub _get_tidy {

    # Construct object
    $TIDY = HTML::Tidy->new( { 'config_file' => $TIDYRC_FNAME } )
        unless defined $TIDY;
    return $TIDY;
}

# Function
# Static method
# Takes     :   Str html code to clean up
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   Module::Name module
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   Str html code cleaned up
sub tidy_clean {
    my $html = shift;

    # Get HTML::Tidy object and clean html with it
    my $tidy = _get_tidy();
    $html = $tidy->clean($html);

    return $html;
}

# Returns true to require()
1;

__END__

=pod

=head1 NAME

App::Limpx::Util – subroutines used from multiple modules of App::Limpx

=head1 VERSION

This documentation refers to App::Limpx::Util version 0.0.1.

=head1 SYNOPSIS

    # Converts between charsets
    require App::Limpx::Util;

    # Convert into file name 'imja'
    my $fname = App::Limpx::Util::_charset_convert( 'Имя' );

=head1 DESCRIPTION

Application uses App::Limpx::Util in two ways:

=over

=item * Configuration storage

Some of configuration variables should be used from multiple modules.
This includes obvious stuff like directories' locations.

=item * Common subroutines

Some of subroutines should be used from multiple modules. This includes
obvious stuff like getting configuration options.

=back

=head1 SUBROUTINES/METHODS

=head2 list_fnames( $dname )

lists (regular) files in given directory

    App::Limpx::Util::list_fnames( '/tmp' );

Lists regular files only in the directory given as its only argument and
croaks in I/O errors.

Returns Array[Str] list of fully qualified file names found

=head2 get_limbxxx()

Refers to location of 'html' data files.

    # Makes constants possible
    use Const::Fast;

    # Directory that keeps data to work with
    const my $LIMBXXX => App::Limpx::Util::get_limbxxx();

All the data for 'limpx' app to work with is located in a directory
known as a C<$LIMBXXX> constant in App::Limpx::Util. For any other
module to get this configuration variable this subroutine is needed.

Returns C<Str> value of configuration variable.

=head2 get_base_url

This returns configured and kept here value of base C<URL>.

    # Base URL to fetch images from
    const my $BASE_URL => App::Limpx::Util::get_base_url;

All the data to download are based on their C<url> and other stuff.
C<URL>s have common part that can be considered to be a 'base C<URL>'.
This configuration value is kept in this module and returned by this
subroutine.

Returns C<Str> base URL to download from.

=head2 get_tmpl_dname

Gets templates' directory name.

    # Templates directory name relative to project's directory
    const my $TMPL_DNAME => App::Limpx::Util::get_tmpl_dname();

All the data to render with template are based on their template.
Every template is located in directory common for all templates.
This configuration value is kept in this module and returned by this
subroutine.

Returns C<Str> fully qualified directory name of templates directory.

=head2 charset_convert( Str $cyr_str, [ Bool $dots_allowed ] )

Convert cyrillic string to C<ASCII>.

    # Convert into file name 'imja'
    my $fname = App::Limpx::Util::_charset_convert( 'Имя' );

All the directories and files written shpuld have C<ascii> names. Based
on cyrillic name of their title, the name can be made C<ascii> from
cyrillic automatically.

Optional C<$dots_allowed> argument is to allow dots '.' in the returned string.

Returns C<Str> the C<ASCII> representation of cyrillic string supplied as
argument.

=head2 croak_on_tmpl( HashRef $err_hash )

Stops process with non-zero exit code on template processing errors.

    # Stop process template on compile or runtime errors
    my $tmpl = Text::Template->new( qw{TYPE FILE SOURCE}, $TMPL_FNAME,
        'BROKEN' => \&App::Limpx::Util::croak_on_tmpl,
    );

L<Text::Template> does not stop processing template without such a
subroutine stated explicitly as a callback. This subroutine stops
process with non-zero exit code.

Returns nothing meaningful.

=head2 get_collate_dname

Returns directory name of 'collate' stuff.

    # Directory that keeps collate stuff
    const my $COLLATE_DNAME => App::Limpx::Util::get_collate_dname();

Name of directory to read/write the 'collate' stuff from/to.

Returns Str directory name.

=head2 tidy_clean

Cleans html supplied as an argument with L<HTML::Tidy>.

    # Tidy up html
    my $html_tidied = App::Limpx::Util::html_clean( '<html></html>' );

C<HTML> code should be unified and cleaned up before output. This
subroutine achieves that with C<HTML::Tidy> module and a configuration
file saved in C<etc> directory.

Returns Str cleaned up html.

=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate
(even the ones that will "never happen"), with a full explanation of each
problem, one or more likely causes, and any suggested remedies.
(See also “Documenting Errors” in Chapter 13.)

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module,
including the names and locations of any configuration files, and the
meaning of any environment variables or properties that can be set. These
descriptions must also include details of any configuration language used.
(See also “Configuration Files” in Chapter 19.)

=head1 DEPENDENCIES

A list of all the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules are
part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for
system or program resources, or due to internal limitations of Perl
(for example, many modules that use source code filters are mutually
incompatible).

=head1 BUGS AND LIMITATIONS

A list of known problems with the module, together with some indication of
whether they are likely to be fixed in an upcoming release.
Also a list of restrictions on the features the module does provide:
data types that cannot be handled, performance issues and the circumstances
in which they may arise, practical limitations on the size of data sets,
special cases that are not (yet) handled, etc.
The initial template usually just has:
There are no known bugs in this module.
Please report problems to <Maintainer name(s)>
Patches are welcome.
(<contact address>)

=head1 AUTHOR

<Author name(s)>
(<contact address>)

=head1 LICENCE AND COPYRIGHT

Copyright (c) <year> <copyright holder> (<contact address>). All rights reserved.
followed by whatever licence you wish to release it under.
For Perl code that is often just:
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
