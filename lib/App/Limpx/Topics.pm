#!/usr/bin/env perl
#
####### APP::LIMPX::TOPIC - WORK WITH LIMPX TOPICS #######
#
# ABSTRACT: Collate limpx topic(s)
#
# Copyright (C) 2016 No One
# All rights reserved.
#
package App::Limpx::Topics;

# Helps you to behave
use strict;
use warnings;

### MODULES ###
#
# Dies more nicely
require Carp;

# Dies on I/O errors
use autodie;

# Lists files in directory; keeps configuration values
require App::Limpx::Util;

# Gets questions, their variants and checks
require App::Limpx::Questions;

# Renderss (collates) topic to human/machine-readable format
require App::Limpx::Collate;

# Reads strings from files
require File::Slurp;

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# Directory that keeps data to work with
const my $LIMBXXX => App::Limpx::Util::get_limbxxx();

# Directory that keeps collate stuff
const my $COLLATE_DNAME => App::Limpx::Util::get_collate_dname();

### SUBS ###
#
# Function
# Gets code and name of course re3ady for being a directory or file
# names in cyrillic yet
# Takes     :   Str course's name with code in front
# Requires  :   Carp module
# Throws    :   If course can not be separated onto course's code and
#               course's name itself
# Returns   :   Array[Str] code of course and name of course,
#               respectively; both cyrillic and without spaces
sub _get_code_and_name {
    my $course = shift;
    my ( $course_code => $course_name );

    # Separate course code from course name
    Carp::croak("No code can be found for course '$course'")
        unless $course =~ m{^\s*(([^\s]+)[-\s_]+)+(([^\s]+)\.)+\s*(.*)$};
    $course_code = "$1-$3";
    $course_name = $5;

    # Clean up from spaces in the end and in the beginning
    $course_code =~ s{-+}{-}g;
    $course_name =~ s{^[\s\.]+|[\s\.]+$}{}g;

    # Return value
    return ( $course_code => $course_name );
}

# Function
# Composes directory and file name for collated topic file
# Takes     :   Str name of course;
#               Str name of topic
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   Convert::Cyrillic, Carp modules
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   Array[Str]:
#                   - fully qualified directory name for topic file(s);
#                   - fully qualified topic file name;
sub _collate_dname_fname {
    my ( $course => $topic ) = @_;
    my ( $dname => $fname );

    # Find course's code and name
    my ( $course_code => $course_name )
        = _get_code_and_name( $course => $topic );

    # Directory name out of course code
    my $course_code_conv
        = App::Limpx::Util::charset_convert( $course_code => 1 );
    my $course_name_conv = App::Limpx::Util::charset_convert($course_name);
    $dname = $course_code_conv . "_-_$course_name_conv";

    $dname = "$COLLATE_DNAME/$dname";

    # File name out of topic name
    my $topic_conv = App::Limpx::Util::charset_convert($topic);
    $fname = "$dname/$topic_conv.html";

    return $dname => $fname;
}

# Function
# Reads topic from file to hash
# Takes     :   Str name of file to read topic from
# Requires  :   File::Slurp, autodie, Carp modules
# Returns   :   HashRef[Str] information about topic, where the keys
#               are:
#                   - 'course' is the name of the course, including both
#                       code of course and name of course;
#                   - 'topic' is the name of the topic, including
#                      topic's 'code' and name itself;
#                   - 'dname' is the fully qualified name of directory
#                       of output file to be put, the course's output
#                       directory;
#                   - 'fname' is the fully qualified topic's output file
#                       name
sub _read_topic_file {
    my $topic_fname = shift;

    # Read topic file
    my $str = File::Slurp::read_file($topic_fname, { qw{binmode :raw} } );    # autodie
    Carp::croak("No course and topic found in topic file: '$topic_fname'")
        unless $str =~ m{^.*<h5[^>]*>([^<]+)</h5>.*<h5[^>]*>([^<]+)<.*$}msgi;

    # Find course, topic; cut spaces and dots from start and end
    my ( $course => $topic ) = ( $1 => $2 );
    foreach ( $course => $topic ) { s{^[\s\.]+|[\s\.]+$}{}g; }

    # Make collate directory/file name out of course/topic names
    my ( $dname => $fname ) = _collate_dname_fname( $course => $topic );

    # Return value
    my $topic_hash = {
        'course' => $course,
        'topic'  => $topic,
        'dname'  => $dname,
        'fname'  => $fname,
    };
    return $topic_hash;
}

# Function
# Gets name of topic's directory to read from
# Takes     :   Str name of topic file
# Requires  :   Carp module
# Throws    :   If name of topic file supplied as an argument have no
#               'html' extension
# Returns   :   Str name of directory to read questions from
sub _get_topic_dname {
    my $topic_fname = shift;
    my $dname;

    # Find directory
    Carp::croak("File name extension is not 'html' for '$topic_fname'")
        unless $dname = $topic_fname =~ s{\.html$}{}ir;
    Carp::croak("Directory does not exist: '$dname'")
        unless -d $dname;

    return $dname;
}

# Function
# Reads questions from downloaded topic's directory
# Takes     :   Str name of directory to read the downloaded questions
#               from
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   App::Limpx::Questions module
# Returns   :   ArrayRef[HashRef[]] questions with fields of every
#               question's hash reference as follows:
#                   - 'qtext'       :   Str text of the question;
#                   - 'variants'    :   ArrayRef[Str] variants of
#                                       answers;
#                   - 'checked'     :   ArrayRef[Bool] checked
#                                       variants;
#                   - 'multiplicity':   Bool if input is multiple (e.g.,
#                                       checkbox not a radio);
sub _read_topic_dir {
    my $topic_dname = shift;

    # Get questions for given topic
    my $questions = App::Limpx::Questions::get_questions( $topic_dname, );
    return $questions;
}

# Function
# Collates topic from its hash
# Takes     :   HashRef hash of topic, including every data needed to
#               render, like course and topic names, questions, their
#               variants, their checks
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   App::Limpx::Collate module
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   n/a
sub _collate_topic_hash {
    my $topic_hash = shift;

    # Collate every topic info known in topic's hash variable yet
    App::Limpx::Collate::collate_topic($topic_hash);
}

# Function
# Collates topic from file name found
# Takes     :   Str name of topic file
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   File::Slurp, autodie modules
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   n/a
sub _collate_topic {
    my $topic_fname = shift;
    my $topic_hash;

    # Read topic info into structured hash
    $topic_hash = _read_topic_file($topic_fname);
    my $topic_dname = _get_topic_dname($topic_fname);
    my $questions   = _read_topic_dir($topic_dname);
    $topic_hash->{'questions'} = $questions;

    # Render topic into topic file
    _collate_topic_hash($topic_hash);
}

# Function
# Collates topics from course's directory
# Takes     :   Str name of downloaded course directory
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   Carp module
# Throws    :   If no topics' files were found
# Returns   :   n/a
sub collate {
    my $dname = shift;

    # Find topics files' names, croak if none found
    my @topics_fnames = App::Limpx::Util::list_fnames($dname);
    Carp::croak("No topics found for course: '$dname'")
        unless (@topics_fnames);

    foreach my $topic_fname (@topics_fnames) {

        # Collate every topic
        _collate_topic($topic_fname);
    }
}

# Returns true to require()
1;

__END__

=pod

=head1 NAME

App::Limpx::Topics – process limpx topics

=head1 VERSION

This documentation refers to App::Limpx::Topics version 0.0.1.

=head1 SYNOPSIS

    # Collates 'limpx' topics
    require App::Limpx::Topics;

    # Collate 'limpx' topics from course's directory
    my $dname = '/tmp/course';
    App::Limpx::Topics::collate( $dname );

=head1 DESCRIPTION

L<App::Limpx> is application to work with 'limpx' courses. Every course
consists of topics. This module processes topics.

Every topic is downloaded to C<html> file that contains questions' texts
but no variants. This module collates variants to questions and
formulates new files within another 'collated' directory.

=head1 SUBROUTINES/METHODS

=head2 collate( $dname )

Collates topics found in directory.

    # Collate 'limpx' topics from course's directory
    my $dname = '/tmp/course';
    App::Limpx::Topics::collate( $dname );

Finds topics files in course's directory named as supplied with argument
and collates questions into the newer files, one per each topic.

Takes Str name of downloaded course directory.

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
