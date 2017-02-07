package Sereal::Path::Iterator;
use 5.008;
use strict;
use warnings;
use Carp qw/croak/;
use XSLoader;

our $VERSION    = '0.014';
our $XS_VERSION = $VERSION; $VERSION= eval $VERSION;

# TODO autogenerate constants from srl_iterator.h
use constant {
    SRL_INFO_ROOT    => (1 << 0),
    SRL_INFO_REF     => (2 << 0),
    SRL_INFO_HASH    => (3 << 0),
    SRL_INFO_ARRAY   => (4 << 0),
    SRL_INFO_REGEXP  => (5 << 0),
    SRL_INFO_SCALAR  => (6 << 0),
    SRL_INFO_BLESSED => (1 << 8),
    SRL_INFO_REF_TO  => (1 << 16),
};

use Exporter 'import';
our @EXPORT = qw(
    SRL_INFO_ROOT
    SRL_INFO_REF
    SRL_INFO_HASH
    SRL_INFO_ARRAY
    SRL_INFO_REGEXP
    SRL_INFO_SCALAR
    SRL_INFO_BLESSED
    SRL_INFO_REF_TO
);

our %EXPORT_TAGS = (all => \@EXPORT);

sub CLONE_SKIP {1}

XSLoader::load(__PACKAGE__, $Sereal::Path::Iterator::VERSION);

1;

__END__

=encoding utf8

=head1 NAME

Sereal::Path::Iterator - iterator over Sereal documents

=cut
