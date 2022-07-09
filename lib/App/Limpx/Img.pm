#!/usr/bin/env perl
#
####### App::Limpx::Img - QUESTIONS HTML IMG TAGS PROCESSING ###########
#
# ABSTRACT: Put html img tag to parsed html code
#
# Copyright (C) 2016 No One
# All rights reserved.
#
package App::Limpx::Img;

# Helps you to behave
use strict;
use warnings;

### MODULES ###
#
# Dies more nicely
require Carp;

# Keeps configuration
require App::Limpx::Util;

# Fetches inline images
require WWW::Mechanize::GZip;

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# Base URL to fetch images from
# Requires  :   App::Limpx::Util module
const my $BASE_URL => App::Limpx::Util::get_base_url();

# Encodes images to 'base64'
require MIME::Base64;

### PACKAGE LEXICAL VARIABLES ###
#
# Image download cache
my $IMG_CACHE = {};

# Image downloader; dies on failure
# Requires  :   WWW::Mechanize::GZip module
my $MECH = WWW::Mechanize::GZip->new(
    qw{autocheck 1 agent},
    'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36'
        . ' (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36',
);

### SUBS ###
#
# Function
# Gets image file blob with caching
# Takes     :   Str source URL of image
# Depends   :   On $IMG_CACHE package lexical, $BASE_URL constant
# Requires  :   Module::Name module
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   Blob downloaded image; empty blob if image was not
#               downloaded
sub _get_img {
    my $src = shift;
    my $image;

    if (exists( $IMG_CACHE->{$src} )
        and defined $IMG_CACHE->{$src}    # cache empty images?
        )
    {

        # Take from cache
        $image = $IMG_CACHE->{$src};
    }
    else {

        my $url = "$BASE_URL/$1";

        # Get image
        $MECH->get($url);                 # autocheck => 1
        $image = $MECH->content;

        # Put to cache
        $IMG_CACHE->{$src} = $image;      # cache empty images?
    }

    return $image;
}

# Function
# Gets image contents for html inline placement
# Takes     :   Int count of the ...
# Depends   :   On $BASE_URL constant
# Requires  :   MIME::Base64 module
# Changes   :   'prop' property, $GLOB package global
# Throws    :   If 'arg' argument is more than ...
# Outputs   :   This to STDOUT, that to STDERR, and more to TAP
# Returns   :   Array this if wantarray,
#           :   Str that otherwise
sub _get_img_src {
    my $src   = shift;
    my $image = _get_img($src);

    my $src_new;
    if ( length $image ) {
        $image   = MIME::Base64::encode_base64($image);
        $src_new = "data:image/gif;base64,$image";
    }
    else {
        warn "Empty image: $src";
        $src_new = "$BASE_URL/$src";
    }

    return $src_new;
}

# Function
# Cleans up 'img' tag after split, normalizes html substring
# Takes     :   Str html substring after split by start of 'img' tag
# Requires  :   Carp module
# Throws    :   If unclosed tag from the start contains no 'src'
#               attribute (doesn't seem to be an image)
# Returns   :   Str html substring with inline image contents,
#               normalized
sub cleanup_img {
    my $str = shift;

    # Find source link of inline image
    if ( $str =~ m{^[^<]*>} ) {
        if ( $str =~ s{[^>]*src=['"]?([^>'"]+)['"]?[^>]*>}{}is ) {
            my $src = $1;

            # Try to get image link
            $src = _get_img_src($src);

            # put img element with src attribite
            $str =~ s{<[^>]*>}{}sg;
            $str =~ s{\s+}{ }g;
            $str = "<img src='$src'> $str";
        }
        else {

            # croak() on unclosed tag found when it's not image
            Carp::croak("No match for image source link: '$str'");
        }
    }
    else {

        # No image found; strip tags
        $str =~ s{<[^>]*>}{}sg;
        $str =~ s{\s+}{ }g;
    }

    $str =~ s{^\s+|\s+$}{}sg;
    $str =~ s/\302\240/ /g;
    return $str;
}

# Returns true to require()
1;

__END__

=pod

=head1 NAME

App::Limpx::Img – Process images for App::Limpx

=head1 VERSION

This documentation refers to App::Limpx::Img version 0.0.1.

=head1 SYNOPSIS

    # Process inline images
    require App::Limpx::Img;

    # Cleanup images from html code
    # results into mage's html code inlinne containment
    my $str = App::Limpx::Img::cleannup_img( 'src="?test00">test01' );

=head1 DESCRIPTION

HTML code of text of questions (and variants, too) contains inline
images. They need special treatment.

First, they should be downloaded to be saved locally. Second, they
should be cached while downloading. Third, they should be contained in
html code in inline manner.

As encoding of image contents use to contain new line characters, this
influences cleanup of html code from new line characters.

=head1 SUBROUTINES/METHODS

=head2 cleanup_img( Str $str )

Cleans up html substring after split by staret of C<img> tag.

    # Cleanup images from html code
    # results into mage's html code inlinne containment
    my $str = App::Limpx::Img::cleannup_img( 'src="?test00">test01' );

After split of html substring by start of C<img> tag, it starts from
tag's attribute(s) and closing angle bracket. Attributes should include
the C<src> value, the location of the image file.

This subroutine tries to download image from file to inline html code,
deleting any other inline tag(s), and has a special treatment on newline
characters those should be present in encoded C<src> attribute value,
and deleted from rest of html substring .

Returns C<Str> normalized C<html> substring with images brought inline, if
any.

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
