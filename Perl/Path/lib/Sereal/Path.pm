package Sereal::Path;

use 5.008;
use strict qw(vars refs);

our $AUTHORITY = 'cpan:IKRUGLOV';
our $VERSION   = '0.1';

use Carp;
use Scalar::Util qw[blessed];
use Sereal::Path::Iterator;

sub new {
    defined $_[1] or die "first argument must be defined";

    my $iter;
    if (blessed($_[1]) && $_[1]->isa(Sereal::Path::Iterator)) {
        $iter = $_[1];
    } else {
        $iter = Sereal::Path::Iterator->new($_[1]);
    }

    bless {
        iter       => $iter,
        obj        => undef,
        resultType => 'VALUE',
        result     => [],
    }, $_[0];
}

sub _normalize {
    my ($self, $x) = @_;
    #$x =~ s/[\['](\??\(.*?\))[\]']/_callback_01($self,$1)/eg;
    $x =~ s/'?\.'?|\['?/;/g;
    $x =~ s/;;;|;;/;..;/g;
    $x =~ s/;\$|'?\]|'$//g;
    #$x =~ s/#([0-9]+)/_callback_02($self,$1)/eg;
    #$self->{'result'} = [];   # result array was temporarily used as a buffer
    return $x;
}

sub _store {
    my ($self, $path, $value) = @_;
    push @{ $self->{'result'} }, ( $self->{'resultType'} eq "PATH"
                                   ? $self->asPath($path)
                                   : $value ) if $path;
    return !!$path;
}

sub traverse {
    my ($self, $expr) = @_;

    my $norm = $self->_normalize($expr);
    $norm =~ s/^\$;//;

    $self->{iter}->reset;
    #warn("norm=$norm");
    return $self->_trace_next_object($norm, '$');
}

sub _trace_next_object {
    my ($self, $expr, $path) = @_;
    my $iter = $self->{iter};

    #warn("_trace_next_object: expr=$expr path=$path");

    return if $iter->eof;
    return $self->_store($path, $iter->decode) if "$expr" eq '';
    
    my ($loc, $x);
    {
        my @x = split /\;/, $expr;
        $loc  = shift @x;
        $x    = join ';', @x;
    }

    my ($type, $cnt) = $iter->info;
    #warn("_trace_next_object: type=$type cnt=$cnt loc=$loc odepth=" . $iter->stack_depth);

    if ($type eq 'ARRAY') {
        if ($loc =~ /^\-?[0-9]+$/) {
            #warn("_trace_next_object: ARRAY loc=$loc");
            $iter->step_in;
            $iter->array_goto($loc);
            return $self->_trace_next_object($x, "$path;$loc");
        } elsif ($loc eq '*') {
            $iter->step_in;
            my $depth = $iter->stack_depth;
            #warn("_trace_next_object: WALK ARRAY, depth=$depth");

            foreach (1 .. $cnt) {
                $depth == $iter->stack_depth or die "assert depth inside walking array failed";
                #warn("_trace_next_object: WALK ARRAY offset=" . $iter->offset . " iter=$_ depth=$depth");

                $self->_trace_next_object($x, $path);

                #warn(sprintf('$iter->stack_depth > $depth (%s > %s)', $iter->stack_depth, $depth));
                if ($iter->stack_depth > $depth) {
                    #warn("_trace_next_object: WALK ARRAY srl_next_at_depth($depth)");
                    $iter->srl_next_at_depth($depth)
                }
            }

            $depth == $iter->stack_depth and die "assert depth after walking failed";
        } elsif ($loc =~ m/\,/) {
            $iter->step_in;
            my $depth = $iter->stack_depth;
            my @idxs = map { $_ >= 0 ? $_ : $cnt + $_ }
                       grep { /^\-?[0-9]+$/ }
                       split(/\,/, $loc);

            # TODO verify that array is sorted
            foreach my $idx (@idxs) {
                $iter->array_goto($idx);
                $self->_trace_next_object($x, "$path;$idx");
                $iter->srl_next_at_depth($depth) if $iter->stack_depth > $depth;
            }
        }
    } elsif ($type eq 'HASH') {
        if ($loc eq '*') {
        } elsif ($loc =~ m/\,/) {
            $iter->step_in;
            my $depth = $iter->stack_depth;
            my @names = grep { $_ } split(/\,/, $loc);

            foreach my $name (@names) {
                $self->_trace_next_object($x, "$path;$name")
                    if $iter->hash_exists($name);
                $self->step_out();
            }
        } else {
            $iter->step_in;
            #warn("_trace_next_object: HASH depth=" . $iter->stack_depth);

            if ($iter->hash_exists($loc)) {
                #warn("_trace_next_object: HASH key found=$loc depth=" . $iter->stack_depth);
                return $self->_trace_next_object($x, "$path;$loc");
            }

            #warn("_trace_next_object: HASH key not found=$loc depth=" . $iter->stack_depth . " offset=" . $iter->offset);
        }
    }

    ##warn("_trace_next_object: end of function depth=" . $iter->stack_depth);
}

1;

__END__

=head1 AUTHOR

Ivan Kruglov <ivan.kruglov@yahoo.com>

This module is pretty much a straight line-by-line port of the 
JSON::Path module by Toby Inkster which is a port of the PHP JSONPath
implementation (version 0.8.x) by Stefan Goessner. See
L<http://code.google.com/p/jsonpath/>.

=head1 COPYRIGHT AND LICENCE

Copyright 2007 Stefan Goessner.

Copyright 2010-2013 Toby Inkster.

Copyright 2014 Ivan Kruglov.

This module is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=head2 a.k.a. "The MIT Licence"

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.