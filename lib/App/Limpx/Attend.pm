#!/usr/bin/env perl
#
####### APP::LIMPX::ATTEND - SEARCHABLE COURSES FOR ATTENDEES ##########
#
# ABSTRACT: Concatenate collated topics into a single file per course
#
# Copyright (C) 2016 No One
# All rights reserved.
#
package App::Limpx::Attend;

# Helps you to behave
use strict;
use warnings;

# Dies on I/O errors
use autodie;

### MODULES ###
#
# Lists files in directory; keeps configuration values
require App::Limpx::Util;

# Finds files by rules
require File::Find::Rule;

# Reads/writes strings from/to files
require File::Slurp;

# Dies more nicely
require Carp;

# Gets base name of file
require File::Basename;

# Creates directories recursively
require File::Path;

# Renders arbitrary text from templates based on variables
require Text::Template;

# Blends the attend cutting wrong variants
require App::Limpx::Attend::Blend;

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# Directory that keeps data to work with
const my $LIMBXXX => App::Limpx::Util::get_limbxxx();

# Directory that keeps collate stuff
const my $COLLATE_DNAME => App::Limpx::Util::get_collate_dname();

# Directory that keeps collate stuff
# Requires  : lib::abs module
# Throws    : If downloaded stuff directory is not found
my $ATTEND_DNAME = 'courses-attend';
$ATTEND_DNAME = "$LIMBXXX/$ATTEND_DNAME";
const $ATTEND_DNAME => $ATTEND_DNAME;

# Templates directory name relative to project's directory
const my $TMPL_DNAME => App::Limpx::Util::get_tmpl_dname();

# Template file name relative to templates' directory
my $TMPL_FNAME = 'attend.tmpl';
const $TMPL_FNAME => "$TMPL_DNAME/$TMPL_FNAME";

### PACKAGE LEXICAL VARIABLES ###
#
# Collate template object
my $TEMPLATE = _get_attend();

### SUBS ###
#
# Function
# Gets collated courses' directory names
# Takes     :   n/a
# Depends   :   On $COLLATE_DNAME constant
# Requires  :   File::Find::Rule, autodie modules
# Throws    :   On I/O errors
# Outputs   :   I/O errors to STDOUT
# Returns   :   collated courses' directory names
sub _get_collate {

    # Prepare rule: list regular files in directory
    my $rule = File::Find::Rule->directory();
    $rule->mindepth(1);
    $rule->maxdepth(1);

    # List directories in  'collate' directory with predefined rule
    my @dlist = $rule->in($COLLATE_DNAME);    # use autodie;

    return \@dlist;
}

# Function
# Gets name of course file to output attend stuff to
# Takes     :   Str name of collate course directory input
# Depends   :   On $ATTEND_DNAME constant
# Requires  :   File::Basename module
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   Str name of attend file to output the course contents
sub _get_course_fname {
    my $dname = shift;

    # Get base name from collate directory name and concatenate it with attend
    # directory name and 'html' extension
    my $bname        = File::Basename::basename($dname);
    my $course_dname = "$ATTEND_DNAME/$bname";
    my $course_fname = "$course_dname/$bname.html";

    return $course_fname;
}

# Function
# Gets name of course for attend file's html title
# Takes     :   Str name of input course's topic file
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   Module::Name module
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   Str name of course
sub _get_course {
    my $fname = shift;

    # Read file and parse 'h1' header
    my $str = File::Slurp::read_file($fname);    # use autodie;
    Carp::croak("No course in-body header found for file: '$fname'")
        unless my ($course) = $str =~ m{<h1>([^<]+)</h1>}is;

    return $course;
}

# Function
# Composes html head for attend course output file
# Takes     :   Str name of course for html title section
# Depends   :   On $TEMPLATE package lexical variable
# Throws    :   On rendering runtime errors
# Outputs   :   Rendering runtime errors errors to STDOUT
# Returns   :   Str html head to output
sub _get_html_head {
    my $course = shift;

    # Render html head
    my $head_hash = { 'course' => $course };
    my $head = $TEMPLATE->fill_in( 'HASH' => $head_hash );

    return $head;
}

# Function
# Reads html body from collate file to be concatenated into attend
# output file, cutting 'h1' element at the least
# Takes     :   Str fully qualified file name to read html body from
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   File::Slurp module
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   Str html body as it is in input file
sub _get_html_body {
    my $fname = shift;

    # Get file contents and body from there
    my $body = File::Slurp::read_file($fname);
    $body =~ s{^.*</h1>(.*)</body>.*$}{$1}isg;

    return $body;
}

# Function
# Gets html code based on course name and topic file names
# Takes     :   Int count of the ...
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   Module::Name module
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   Str html code cleaned with HTML::Tidy
sub _get_html {
    my ( $course => $fnames ) = @_;

    # Put course title to head of output html code
    my $html = _get_html_head($course);
    foreach my $fname (@$fnames) {

        # Read every file to string to be concatenated
        my $html_body = _get_html_body($fname);
        $html .= $html_body;
    }
    $html .= "</body></html>";

    # Tidy and return
    $html = App::Limpx::Util::tidy_clean($html);
    return $html;
}


# Function
# Outputs course to file(s)
# Takes     :   Str name of file to output;
#               Str html to output to per-course attend file
# Requires  :   File::Slurp, autodie, Carp, File::Basename, File::Path
#               modules
# Changes   :   File system contents
# Throws    :   On I/O errors
# Outputs   :   I/O errors to STDOUT
# Returns   :   n/a
sub _output_course {
    my ( $course_fname => $html ) = @_;

    # Create attend directory if it does not exist yet
    my $course_dname = File::Basename::dirname( $course_fname );
    Carp::croak(
        "Does not exist and can not be created directory: '$course_dname'")
        unless -d $course_dname
        or File::Path::mkpath($course_dname);    # use autodie;
    File::Slurp::write_file( $course_fname, { binmode => ':utf8' }, $html )
        ;    # use autodie;

    # Put blend course to course' directory
    App::Limpx::Attend::Blend::blend_course( $course_fname => $html );
}

# Function
# Attends course given by 'collate' directory name
# Takes     :   Str name of directory the collated course is located in
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   Carp module
# Returns   :   n/a
sub _attend_course {
    my $dname = shift;

    # List files from 'collate' directory, find output file name and
    # title of course
    Carp::croak("No file names found in directory: '$dname'")
        unless my $fnames = [ App::Limpx::Util::list_fnames($dname) ];
    my $course_fname = _get_course_fname($dname);
    my $course       = _get_course( $fnames->[0] );

    # Get html code and put to file
    my $html = _get_html( $course => $fnames );
    _output_course( $course_fname => $html );
}

# Function
# Concatenates per-topic html collated files into per-course attended
# files
# Takes     :   n/a
# Depends   :   On $ATTEND_DNAME constant
# Requires  :   File::Path, Carp modules
# Changes   :   File system contents
# Throws    :   On I/O errors
# Outputs   :   I/O errors to STDOUT
# Returns   :   n/a
sub attend {

    # get list of directories and attend them one by one
    my $dnames = _get_collate();
    foreach my $dname (@$dnames) {
        _attend_course($dname);
    }
}

# Function
# Generates 'attend' template
# Takes     :   n/a
# Depends   :   On $TMPL_FNAME constant
# Requires  :   Text::Template module
# Throws    :   On I/O errors
# Outputs   :   I/O errors to STDOUT
# Returns   :   Text::Template object to render attend html with
sub _get_attend {

    # Template object
    my $tmpl = Text::Template->new( qw{TYPE FILE SOURCE},
        $TMPL_FNAME, 'BROKEN' => \&App::Limpx::Util::croak_on_tmpl, );
    return $tmpl;
}

# Returns true to require()
1;

__END__

=pod

=head1 NAME

App::Limpx::Attend – concatenate topics into searchable courses files

=head1 VERSION

This documentation refers to App::Limpx::Attend version 0.0.1.

=head1 SYNOPSIS

    # Attends topics to courses
    require App::Limpx::Attend;

    # Concatenate topics into per-course files for attendees
    App::Limpx::Attend::attend();

=head1 DESCRIPTION

L<App::Limpx> is application to work with 'limpx' courses. Every course
consists of topics. This module processes collated topics.

Every topic is collated to C<html> file contained in course's directory.
This module concatenates per-topic files into per-course files making
them easy to be searched for the text wanted  and formulates new
per-course files within another 'attend' directory.

=head1 SUBROUTINES/METHODS

=head2 attend

Concatenates per-topic 'collate' directories into course 'attend' files.

    # Concatenate topics into per-course files for attendees
    App::Limpx::Attend::attend();

This takes list of 'collate' per-course directories and concatenates the
per-topic files from there into per-course 'attend' files.

Returns nothing meaningful.

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
