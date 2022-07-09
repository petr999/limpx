#!/usr/bin/env perl
#
####### APP::LIMPX::QUESTIONS - SUIBROUTINES TO GET QUESTIONS ##########
#
# ABSTRACT: Get questions from topic's directory
#
# Copyright (C) 2016 No One
# All rights reserved.
#
package App::Limpx::Questions;

# Helps you to behave
use strict;
use warnings;

### MODULES ###
#
# Dies more nicely
require Carp;

# Dies on I/O errors
use autodie;

# Finds files by rules
require File::Find::Rule;

# Process inline images
require App::Limpx::Img;

### CONSTANTS ###
#
# Makes constants possible
# use Const::Fast;

# (Enter constant description here)
# const my $SOME_CONST => 1;

### SUBS ###
#
# Function
# Gets files of questions from topic's directory
# Takes     :   Str name of topic's directory
# Requires  :   File::Find::Rule module
# Throws    :   On I/O errors
# Returns   :   Array[Str] fully qualified names of questions' files,
#               sorted alphabetically
sub _questions_fnames {
    my $topic_dname = shift;
    my @flist;

    # Find regular files named 'javascript*.html'
    my $rule = File::Find::Rule->file();
    $rule->mindepth(2);
    $rule->name('javascript*.html');
    @flist = $rule->in($topic_dname);

    # Sort and return
    @flist = sort { $a cmp $b } @flist;
    return @flist;
}

# Function
# Delete inputs type from variants noting it for multiplicity
# Takes     :   ArrayRef[Str] variants split from question file
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   Module::Name module
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   Bool multiplicity of variant's input;
#               ArrayRef[Str] inputs as they were split from downloaded
#               html question file
sub _cleanup_variants {
    my $variants = shift;

    # Delete inputs type from variants noting it for multiplicity
    my $variants_new;
    my $multiplicity = '';
    foreach my $variant (@$variants) {
        if ( $variant eq 'checkbox' ) {

            # Do not copy 'checked' input type to new variants array
            # Note it for 'multiplicity'
            $multiplicity = 1;

        }
        elsif ( $variant ne 'radio' ) {

            # Copy variant's text to new variants array
            push @$variants_new, $variant;
        }
    }
    $variants = $variants_new;

    return $multiplicity => $variants;
}

# Function
# Gets list of state of a single question's inputs
# Takes     :   ArrayRef[Str] variants as they were split from downloaded
#               question html file
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   Module::Name module
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   ArrayRef[Str] variants cleaned from rest of input tag;
#               ArrayRef[Bool] states of variants
sub _get_checked {
    my $variants     = shift;
    my $variants_new = [];
    my $checked      = [];

    # Get values for radios
    foreach my $variant (@$variants) {
        my $variant_new;

        # Find variant's value
        Carp::croak("No value match for radio: $variant!")
            unless $variant_new
            = $variant =~ s{value=['"](\d+)['"][^>]*>}{}ir;
        my $value = $1;

        # Grab to output then
        push @$checked,      $value;
        push @$variants_new, $variant_new;
    }
    $variants = $variants_new;

    return $variants => $checked;

}

# Function
# Reads question information from file keeping html information dirty
# Takes     :   Str name of the question file to read and split
# Depends   :   On file contents
# Requires  :   File::Slurp, Carp, autodie modules
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   - Str text of the question;
#               - ArrayRef[Str] variants of answers;
#               - ArrayRef[Bool] checked variants;
#               - Bool if input is multiple (e.g., checkbox not a
#                 radio);
sub _split_file {
    my $fname = shift;
    my ( $multiplicity => $variants ) = ( '' => [] );

    # Read middle of file
    my $str = File::Slurp::read_file($fname);    # autodie
    $str =~ s{^.*<my:qtext[^>]*>|<input\s[^>]*type=['"]?button['"]?.*$}{}isg;

    # Split by inputs; first slice is question's text
    ( my $qtext => @$variants )
        = split /<input\s[^>]*type=['"]?(radio|checkbox)['"]?\s/is, $str;
    Carp::croak("No variants for: $fname")
        unless @$variants;

    # Delete inputs type from variants noting it for multiplicity
    ( $multiplicity => $variants ) = _cleanup_variants($variants);

    # With newer variants, get values for 'checked' inputs and strip
    # rest of input tag from start of every variant
    ( $variants => my $checked ) = _get_checked($variants);

    # Return splitted question
    return ( $qtext, $variants, $checked, $multiplicity );
}

# Function
# Cleans up html from unnecessary tags and line breaks
# The only allowed tag is <img> and its contents should be downloaded
# into 'src' attribute
# Takes     :   Str piece of html body code
# Returns   :   Str cleaned up html body code
sub _cleanup_html {
    my $str = shift;

    # Find inline images in qtext and radios
    my @str_arr = split /<img\s+/is, $str;

    # warn Data::Dumper::Dumper( @str_arr );

    my @str_arr_new;
    foreach my $str_part (@str_arr) {
        my $str_part_new;

        # Clean up 'img' tag
        $str_part_new = App::Limpx::Img::cleanup_img($str_part);
        push @str_arr_new, $str_part_new;
    }

    # Glue string back and return
    $str = join ' ' => @str_arr_new;
    return $str;
}

# Function
# gets question from file specified by its name
# Takes     :   Str fully qualified file name of the question
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   Module::Name module
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   HashRef of question with fields of every
#               question's hash reference as follows:
#                   - 'qtext'       :   Str text of the question;
#                   - 'variants'    :   ArrayRef[Str] variants of
#                                       answers;
#                   - 'checked'     :   ArrayRef[Bool] checked
#                                       variants;
#                   - 'multiplicity':   Bool if input is multiple (e.g.,
#                                       checkbox not a radio);
sub _get_question {
    my $fname = shift;
    my ( $qtext, $variants, $checked, $multiplicity );

    # Get question info cleaning up html
    ( $qtext, $variants, $checked, $multiplicity ) = _split_file($fname);
    $qtext = _cleanup_html($qtext);
    my $variants_new = [];
    foreach my $variant (@$variants) {
        $variant = _cleanup_html($variant);
        push @$variants_new, $variant;
    }
    $variants = $variants_new;

    my $question = {
        'qtext'        => $qtext,
        'variants'     => $variants,
        'checked'      => $checked,
        'multiplicity' => $multiplicity,
    };
    return $question;
}

# Function
# Static method
# Takes     :   Array[Str] sorted names of questions' files
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   Module::Name module
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   ArrayRef[HashRef[]] questions with fields of every
#               question's hash reference as follows:
#                   - 'qtext'       :   Str text of the question;
#                   - 'variants'    :   ArrayRef[Str] variants of
#                                       answers;
#                   - 'checked'     :   ArrayRef[Bool] checked
#                                       variants;
#                   - 'multiplicity':   Bool if input is multiple (e.g.,
#                                       checkbox not a radio);
sub _get_questions_from_files {
    my @flist     = @_;
    my $questions = [];

    foreach my $fname (@flist) {

        # Get every question from its file into array
        my $question = _get_question($fname);
        push @$questions, $question;
    }

    return $questions;
}

# Function
# Gets list of questions
# Takes     :   Str topic's directory name
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   Carp module
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   ArrayRef[HashRef[]] questions with fields of every
#               question's hash reference as follows:
#                   - 'qtext'       :   Str text of the question;
#                   - 'variants'    :   ArrayRef[Str] variants of
#                                       answers;
#                   - 'checked'     :   ArrayRef[Bool] checked
#                                       variants;
#                   - 'multiplicity':   Bool if input is multiple (e.g.,
#                                       checkbox not a radio);
sub get_questions {
    my $topic_dname = shift;
    my $questions;

    # Get files list then questions from files
    my @flist = _questions_fnames($topic_dname);
    Carp::croak( "No questions files found for directory: '$topic_dname'", )
        unless @flist;
    $questions = _get_questions_from_files(@flist);

    return $questions;
}

# Returns true to require()
1;

__END__

=pod

=head1 NAME

App::Limpx::Questions – Gets questions from directory of the topic

=head1 VERSION

This documentation refers to App::Limpx::Questions version 0.0.1.

=head1 SYNOPSIS

    # Gets questions, their variants and checks
    require App::Limpx::Questions;

    # Get questions for given topic
    my $questions = App::Limpx::Questions::get_questions(
        '/tmp/course', );

=head1 DESCRIPTION

L<App::Limpx> is application to work with 'limpx' courses. Every course
consists of topics. Every topic consists of questions. This module
processes questions.

Every question is downloaded into its own C<html> file that contains question text,
question variants and checks. This module collates them all to questions
and returns them.


=head1 SUBROUTINES/METHODS

=head2 get_questions( Str $dname )

Gets questions with variants/checks from topic's directory.

    # Get questions for given topic
    my $questions = App::Limpx::Questions::get_questions(
        '/tmp/course', );

Funstion that returns array reference that contains hash references
every of which corresponds to a single question.  Each hash reference
contains: text of question, variants of question, checks of question.
Text of question is Str, every variant of question is Str and variants
are ArrayRef; and checked is array reference of booleans.

Returns ArrayRef information about questions.

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
