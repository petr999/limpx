#!/usr/bin/env perl
#
####### APP::LIMPX::ATTEND::BLEND - WRITE COURSE WITHOUT WRONG VRIANTS #
#
# ABSTRACT: Remove wrong variants from cou\rse and write to file
#
# Copyright (C) 2016 No One
# All rights reserved.
#
package App::Limpx::Attend::Blend;

# Helps you to behave
use strict;
use warnings;

### MODULES ###
#
# Dies on I/O errors
use autodie;

# Reads/writes strings from/to files
require File::Slurp;

# Dies more nicely
require Carp;

# Parses and surges HTML with DOM
require Mojo::DOM;

# Gets directory name of file
require File::Basename;

# Lists files in directory; keeps configuration values
require App::Limpx::Util;

### CONSTANTS ###
#
# Makes constants possible
# use Const::Fast;

# (Enter constant description here)
# const my $SOME_CONST => 1;

### SUBS ###
#
# Function
# Compose blend content
# Takes     :   Str attend course content
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   Mojo::DOM module
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   Str blend content
sub _blend_html {
    my $html = shift;

    # Remove unwanted variants
    my $dom = Mojo::DOM->new( $html );
    $dom->find( 'div p:not([class~="checked"])' )->each( sub{ $_[0]->remove } );
    $dom->find( 'div p:not([class~="multiplicity"]) span' )->each( sub{ $_[0]->remove } );
    my $html_new = $dom->to_string;

    # Tidy and return
    $html_new = App::Limpx::Util::tidy_clean($html_new);
    return $html_new;
}

# Function
# Remove unwanted variants from course and put to 'blend' file
# Takes     :   Str name of file to output;
#               Str html to output to per-course blend file
# Depends   :   On 'prop' property, $CONST  constant
# Requires  :   File::Slurp, autodie, Carp, File::Basename modules
# Changes   :   File system contents
# Throws    :   On I/O errors
# Outputs   :   I/O errors to STDOUT
# Returns   :   n/a
sub blend_course {
    my ( $course_fname => $html ) = @_;

    # Directory seems to be created from the calling subroutine, the
    # 'App::Limpx::Attend::_output_course()'
    # Append '-blend' to file name before extension
    # my $blend_fname = $course_fname =~ s{\.html$}{-_-blend.html}isgr;
    my $blend_fname = File::Basename::dirname( $course_fname ) . "/blend.html";
    Carp::croak(
        "No blend file name for attend file: '$course_fname'", )
    unless $blend_fname;

    # Compose contents and write them to file
    my $html_blend = _blend_html( $html );
    File::Slurp::write_file( $blend_fname, { binmode => ':utf8' }, $html_blend )
        ;    # use autodie;
}


# Returns true to require()
1;

__END__

=pod

=head1 NAME

App::Limpx::Attend::Blend – blend the attend and put it near

=head1 VERSION

This documentation refers to App::Limpx::Attend::Blend version 0.0.1.

=head1 SYNOPSIS

    # Blends the attend from wrong variants
    require App::Limpx::Attend::Blend;

    # Blend the attended html to '/tmp/course-blend.html'
    App::Limpx::Attend::Blend::blend_course( '/tmp/course.html', '
    <html>
    <body>
    <div>
    <p class="checked">
        Correct
    </p>
    <p>
        Wrong
    </p>
    </div>
    </body>
    </html>
    ', );

=head1 DESCRIPTION

L<App::Limpx> is application to work with 'limpx' courses. Every course
consists of topics. This module processes attended courses.

Every course is attended to the per-course C<html> file contained in
per-course's directory.  This module cleans per-course files making them
easy to read and formulates new per-course 'blend' files within the same
per-course 'attend' directory.

=head1 SUBROUTINES/METHODS

=head2 blend_course

Blends html code and writes it to file near the attended one supplied.

    # Blend the attended html to '/tmp/course-blend.html'
    App::Limpx::Attend::Blend::blend_course( '/tmp/course.html', '
    <html>
    <body>
    <div>
    <p class="checked">
        Correct
    </p>
    <p>
        Wrong
    </p>
    </div>
    </body>
    </html>
    ', );

Attended is the file that contains the right and the wrong variants (and
their marks).

Blended is the file that contains only correct variants. And marks for
multiple choices, if any.

This subroutine takes name of attend file and attend contents, makes
blend contents and writes it to blend file.

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
