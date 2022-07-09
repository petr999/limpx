#!/usr/bin/env perl
#
####### APP::LIMPX::COLLATE - RENDERS TOPIC to HUMAN/MACHINE-FILE ######
#
# ABSTRACT: Write down topic so human/machine can read it
#
# Copyright (C) 2016 No One
# All rights reserved.
#
package App::Limpx::Collate;

# Helps you to behave
use strict;
use warnings;

### MODULES ###
#
# Dies on I/O errors
use autodie;

# Creates directories recursively
require File::Path;

# Writes strings to files
require File::Slurp;

# Renders arbitrary text from templates based on variables
require Text::Template;

# Keeps values for project's directories' and files' paths
require App::Limpx::Util;

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# Templates directory name relative to project's directory
const my $TMPL_DNAME => App::Limpx::Util::get_tmpl_dname();

# Template file name relative to templates' directory
my $TMPL_FNAME = 'collate.tmpl';
const $TMPL_FNAME => "$TMPL_DNAME/$TMPL_FNAME";

# Question template file name relative to templates' directory
my $QUESTION_TMPL_FNAME = 'collate/question.tmpl';
const $QUESTION_TMPL_FNAME => "$TMPL_DNAME/$QUESTION_TMPL_FNAME";

### PACKAGE LEXICAL VARIABLES ###
#
# Collate template object
my $TEMPLATE = _get_collate();

# Question template object
my $QUESTION_TEMPLATE = _get_question_tmpl();

### SUBS ###
#
# Function
# Gets template object to render topic with
# Takes     :   n/a
# Depends   :   On $TMPL_FNAME constant
# Requires  :   Text::Template module
# Throws    :   On template compile failures
# Returns   :   Text::Template object of collate template
sub _get_collate {

    # Template object
    my $tmpl = Text::Template->new( qw{TYPE FILE SOURCE},
        $TMPL_FNAME, 'BROKEN' => \&App::Limpx::Util::croak_on_tmpl, );
    return $tmpl;
}

# Function
# Gets template object to render every question with
# Takes     :   n/a
# Depends   :   On $QUESTION_TMPL_FNAME constant
# Requires  :   Text::Template module
# Throws    :   On template compile failures
# Returns   :   Text::Template object of questions template
sub _get_question_tmpl {

    # Template object
    my $tmpl = Text::Template->new( qw{TYPE FILE SOURCE},
        $QUESTION_TMPL_FNAME,
        'BROKEN' => \&App::Limpx::Util::croak_on_tmpl, );
    return $tmpl;
}

# Function
# Outputs rendered topic to 'collate' file
#   Takes   :   Str   directory    name    to    output    file    into;
#               Str file name to output topic into;
#               Str topic content to be written
# Requires  :   File::Path, autodie, File::Slurp modules
# Changes   :   file system contents
# Throws    :   On I/O errors
# Outputs   :   collate to file specified
# Returns   :   n/a
sub _collate_output {
    my ( $dname, $fname, $collate, ) = @_;

    # Write a thing
    -d $dname or File::Path::mkpath($dname);    # use autodie;
    File::Slurp::write_file( $fname, { binmode => ':utf8' }, $collate )
        ;                                       # use autodie;
}

# Function
# Method
# Static method
# Takes     :   ArrayRef[HashRef] array of questions where every HashRef
#               corresponds to single question as follows:
#                   - 'qtext'       :   Str text of the question;
#                   - 'variants'    :   ArrayRef[Str] variants of
#                                       answers;
#                   - 'checked'     :   ArrayRef[Bool] checked variants;
#                   - 'multiplicity':   Bool if input is multiple (e.g.,
#                                       checkbox not a radio);
# Depends   :   On $QUESTIONS_TEMPLATE package lexical variable
# Requires  :   Module::Name module
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   ArrayRef[Str] rendered questions
sub _render_questions {
    my $questions     = shift;
    my $questions_new = [];

    for ( my $i = 0; $i < @$questions; $i++ ) {
        my $question = $questions->[$i];

        # Render '# of #' should be possible, too
        $question->{'num'}              = $i + 1;
        $question->{'questions_amount'} = @$questions;

        # Render every question of array from HashRef to Str
        my $question_new = $QUESTION_TEMPLATE->fill_in( HASH => $question );
        push @$questions_new, $question_new;
    }

    return $questions_new;
}

# Function
# writes the particular topic based on hash
# Takes     :   HashRef[Str] information about topic, where the keys
#               are:
#                   - 'course' is the name of the course, including both
#                       code of course and name of course;
#                   - 'topic' is the name of the topic, including
#                       topic's 'code' and name itself;
#                   - 'dname' is the fully qualified name of directory
#                       of output file to be put, the course's output
#                       directory;
#                   - 'fname' is the fully qualified topic's output file
#                       name;
#                   - 'questions' is ArrayRef[HashRef] array of
#                       questions where every HashRef corresponds to
#                       single question as follows:
#                       - 'qtext'       :   Str text of the question;
#                       - 'variants'    :   ArrayRef[Str] variants of
#                                           answers;
#                       - 'checked'     :   ArrayRef[Bool] checked
#                                           variants;
#                       - 'multiplicity':   Bool if input is multiple
#                                           (e.g., checkbox not a
#                                           radio);
# Depends   :   On $TEMPLATE, $TIDY package lexical variables
# Returns   :   n/a
sub collate_topic {
    my $topic_hash = shift;

    # Copy topic hash to render collate with scalar questions text
    my $collate_hash = {%$topic_hash};

    # Render questions into ArrayRef[Str]
    my $questions          = $topic_hash->{'questions'};
    my $questions_rendered = _render_questions($questions);
    $collate_hash->{'questions'} = $questions_rendered;

    # Render, tidy  and output
    my ( $dname => $fname )
        = ( $topic_hash->{'dname'} => $topic_hash->{'fname'} );
    my $collate = $TEMPLATE->fill_in( 'HASH' => $collate_hash );
    $collate = App::Limpx::Util::tidy_clean($collate);
    _collate_output( $dname, $fname, $collate );
}

# Returns true to require()
1;

__END__

=pod

=head1 NAME

App::Limpx::Collate – collate topic and write to file

=head1 VERSION

This documentation refers to App::Limpx::Collate version 0.0.1.

=head1 SYNOPSIS

    # Writes topic to human/machine-readable form
    require App::Limpx::Collate;

    # Collate every topic  info  known  in  topic's  hash  variable  yet
    App::Limpx::Collate::collate_topic($topic_hash);

=head1 DESCRIPTION

L<App::Limpx> is application to work with 'limpx' courses.  Every course
consists of topics. This module collates topics.

Every topic is read into its hash to be written down.  This module puts
it onto template(s), tidies them and outputs  the  rendered  stuff  into
file named according to topic's hash.

=head1 SUBROUTINES/METHODS

=head2 collate_topic( HashRef $topic_hash )

Outputs rendered topic to human/machine-readable file

    # Collate every topic  info  known  in  topic's  hash  variable  yet
    App::Limpx::Collate::collate_topic($topic_hash);

This subroutine takes every possible information about particular topic,
renders it into html, and puts it into 'collated' file.  Name of file is
fully qualified with function's argument.

The information taken should be is formed as a hash and includes:

=over

=item * course

Str is the name of the course, including both code of course and name of
course;

=item * topic

Str is the name of the topic, including topic's 'code' and name  itself;

=item * dname

Str is the fully qualified name of directory of output file to be put, the
course's output directory;

=item * fname

Str is the fully qualified topic's output file name;

=item * questions

ArrayRef[HashRef] is array of questions for topic given.

=back

The 'questions' elements are HashRefs with keys as follows:

=over

=item * qtext

Str text of the question;

=item * variants

ArrayRef[Str] variants of answers;

=item * checked

ArrayRef[Bool] checked variants;

=item * multiplicity

Bool if input is multiple (e.g., checkbox not a radio);

=back

This function returns nothing meaningful.

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
