#!/usr/bin/env perl
#
####### APP::LIMPX - COLLATES LIMPX INFO FROM DOWNLOADED STUFF #########
#
# ABSTRACT: Produce human/machine -readable files from downloaded limpx
#
# Copyright (C) 2016 No One
# All rights reserved.
#
package App::Limpx;

# Helps you to behave
use strict;
use warnings;

### MODULES ###
#
# Able to load application's own modules and concatenate paths making
# them absolute, too
require lib::abs;

# Dies more nicely
require Carp;

# Dies on I/O errors
# use autodie;

# Collates topics
require App::Limpx::Topics;

# Lists files in directory; keeps configuration values
require App::Limpx::Util;

# Lists files in directory; keeps configuration values
require App::Limpx::Util;

# Attends courses
require App::Limpx::Attend;

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# Directory that keeps data to work with
const my $LIMBXXX => App::Limpx::Util::get_limbxxx();

# Directory that keeps downloaded stuff
# Requires  : lib::abs module
# Throws    : If downloaded stuff directory is not found
my $DOWNLOADED = 'courses-downloaded';
$DOWNLOADED = "$LIMBXXX/$DOWNLOADED";
const $DOWNLOADED => $DOWNLOADED;

### SUBS ###
#
# Function
# Collate courses file given
# Takes     :   Str name of downloaded course file
# Requires  :   Carp, App::Limpx::Topics modules
# Throws    :   If course file name extension is not 'html' or if
#               its' directory was not found
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   n/a
sub _collate_course {
    my $fname = shift;
    my $dname;

    # Find directory
    Carp::croak("File name extension is not 'html' for '$fname'")
        unless $dname = $fname =~ s{\.html$}{}ir;
    Carp::croak("Directory does not exist: '$dname'")
        unless -d $dname;

    # Collate topics from directory
    App::Limpx::Topics::collate($dname);
}

# Function
# Main entry point
# Collates downloaded stuff by topics
# Takes     :   Array[Str] Optional list of courses' files to get topics out of
# Requires  :   Carp module
# Throws    :   If no courses file(s) found
# Changes   :   File system contents in the called subroutines
# Returns   :   n/a
sub collate {
    my @flist = @_;
    unless (@flist) {

        # Find files if none supplied
        @flist = App::Limpx::Util::list_fnames($DOWNLOADED);
    }

    # Croak if no courses were found
    Carp::croak("No courses file(s) found!") unless @flist;

    foreach my $fname (@flist) {

        # Collate every course
        _collate_course($fname);
    }
}

# Function
# Attends the course from collate, i. e., concatenates collate
# per-topics collate files into per-course attend files
# Takes     :   n/a
# Returns   :   n/a
sub attend {
    App::Limpx::Attend::attend();
}

# Returns true to require()
1;

__END__

=pod

=head1 NAME

App::Limpx – Output readable topic files from downloaded limpx

=head1 VERSION

This documentation refers to App::Limpx version 0.0.1.

=head1 SYNOPSIS

    # Able to collate downloaded limpx
    require App::Limpx;

    # Collate stuff from @ARGV or from downloaded directory
    App::Limpx::collate( @ARGV );

=head1 DESCRIPTION

    A full description of the module and its features.
    May include numerous subsections (i.e., =head2, =head3, etc.).

=head1 SUBROUTINES/METHODS

=head2 collate( $fname0, $fname1, ... )

Colllates downloaded courses

    # Collate the course downloaded to '/tmp'
    my $fname = '/tmp/course.html';
    App::Limpx::collate( $fname );

Finds every topic in the directory named the same as course file name
but without extension, and collates topic(s) to newer location(s) all
within 'collate' directory.

Takes optional file name(s), for the case if no any supplied finds them
in 'downloaded' directory configured.

Returns nothing meaningful.

=head2 attend

Concatenates per-topic 'collate' directories into course 'attend' files.

    # Concatenate topics into per-course files for attendees
    App::Limpx::attend();

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
