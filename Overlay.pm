package Tie::Hash::Overlay;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);

use Carp;
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(&overlay);

$VERSION = '0.01';

sub overlay {
    my($hash, $self);
    my $type = ref $_[0];

    if($type eq "HASH") {
	$hash = shift;
	croak "ARRAY ref needed for argument 2 of overlay()"
	    if ref $_[0] ne "ARRAY";
    } elsif($type ne "ARRAY") {
	croak "ARRAY or HASH ref needed for argument 1 of overlay()";
    } else { $hash = {} }

    tie(%{$hash}, 'Tie::Hash::Overlay', @_);

    return $hash;
}

sub TIEHASH {
    my $class = shift;
    my $self = bless {}, $class;

    $$self{'hashes'} = ref($_[0]) eq "ARRAY" ? $_[0] :
	croak "ARRAY ref needed for argument 1 of TIEHASH";
    $$self{'remainder'} = (defined $_[1] && ref($_[1]) eq "HASH") ? $_[1] : {};

    return $self;
}

sub CLEAR {
    my $self = shift;

    foreach(@{$$self{'hashes'}}, $$self{'remainder'}) { %{$_} = () }
}

sub FETCH {
    my $self = shift;
    my $key = shift;

    foreach(@{$$self{'hashes'}}, $$self{'remainder'}) {
	return $$_{$key} if exists $$_{$key};
    }

    return undef;
}

sub STORE {
    my $self  = shift;
    my($key, $value) = @_;

    foreach(@{$$self{'hashes'}}, $$self{'remainder'}) {
	if(exists $$_{$key}) { $$_{$key} = $value; return }
    }
    $$self{'remainder'}{$key} = $value;
}

sub DELETE {
    my $self = shift;
    my $key = shift;

    foreach(@{$$self{'hashes'}}, $$self{'remainder'}) {
	if(exists $$_{$key}) { delete $$_{$key}; return }
    }
}

sub EXISTS {
    my $self = shift;
    my $key = shift;

    foreach(@{$$self{'hashes'}}, $$self{'remainder'}) {
	return 1 if exists $$_{$key};
    }

    return 0;
}

sub FIRSTKEY {
    my $self = shift;
    my $key;
    my $cnt = 0;

    foreach(@{$$self{'hashes'}}, $$self{'remainder'}) {
	$key = scalar keys %{$_};       # This resets the key counter
	$key = each %{$_};
	return $key if $key;
	$$self{'count'}++;
    }

    $$self{'count'} = 0;
    return ();
}

sub NEXTKEY {
    my $self = shift;
    my $key;
    my $count = 0;

    foreach(@{$$self{'hashes'}}, $$self{'remainder'}) {
	next if $count++ < $$self{'count'};
	$key = each %{$_};
	return $key if $key;
	$$self{'count'}++;
    }

    $$self{'count'} = 0;
    return ();
}

sub DESTROY {}

1;
__END__

=head1 NAME

Tie::Hash::Overlay - base class for overlayed hashed

=head1 SYNOPSIS

  use Tie::Hash::Overlay qw(&overlay);
  $a = overlay($arrayref [, $remainder]);
  overlay(\%foo, $arrayref [, $remainder]);

=head1 DESCRIPTION

This module provides a standardized method for interfacing two hashes through
one variable using tie().

If the first parameter is a hash reference, it will be tied and returned as
the overlayed hash. Otherwise, a new tied hash created within overlay() will
be returned.

The $arrayref paramater is a reference to the list of hashes that will be
accessed through the overlayed hash. They are searched in order for the
variables used in the overlayed hash. If you keep a copy of $arrayref
(or manage to figure out where in the object I hid it), you can modify it
at run-time to change the layout of the overlayed hash.

Ahh... but what happens if you try to read/write a variable that doesn't exist
in any of the hashes you overlay? Fortunatly, B<Tie::Hash::Overlay> has
thought of that already. A secret hash is kept that stores these unexpected
variables. If you want to have access to those variables, add a $remainder
parameter. It should just be an empty hashref (which you keep a copy of).

B<Tie::Hash::Overlay> does I<not> copy the hashes passed to it. Nor does
it copy the array ref passed to it. Everything is kept completely intact
on purpose, in order to allow the programmer the most flexibility. Perhaps
you have DBM hash that you want to capture all of the accesses to a certain
element? Or maybe you have a diabolical plan to take over the Earth and
need to overlay tied hashes in Perl for it to work? It's reasons like that
which caused me not to fiddle with what is passed to overlay().

=head1 EXAMPLES

Go ahead and consider me a show-off, but I think a little demonstration is
in order.

	use Tie::Hash::Overlay qw(&overlay);  # import &overlay manually

	$hashes = [ { a => 1, b => 200 }, { foo => bar, blurfle => z } ];
	overlay(\%a, $hashes);
	$b = overlay($hashes);

	print "$a{b}\n";		# This prints 200
	$$b{what} = 'is that?';
	print "what $$b{what}\n";	# This prints "what is that?"
	$x = join(", ", sort keys(%{$b});
	print "$x\n";		# This prints "a, b, blurfle, foo, what"
	$a{b}++;
	print "$$b{b}\n";	# This prints 201. Interesting.
	push @{$hashes}, { "good guys" => "never win" };
	print "$a{good guys}\n";	# Print "never win"

Getting the idea? Basically they're identical to any other hash, except
they're extremely different. Makes sense to me.

=head1 BUGS

Bugs? If there was a bug, do you think it would exist long enough to be put
in here? The only things that could be considered annoying is the need to
pass a hash to be tied by reference, and having to explicitly tell use to
import overlay(). But that last one is a I<good> thing!

On second thought... If two hashes contained the same key in different hashes,
C<each %overlay> would see that key twice before reaching the end of the hash.

Anyways, the mere fact that this thing has a version-number of 0.01 nearly
qualifies as a bug in and of itself.

Oh, and blame any other bugs on tie(). :)

=head1 TODO

Well, I'm pretty sure I'll need to make some minor modifications to the code
in order to support D<Data::Inherit> (which I plan on writing), and any
bugs that can be easily fixed probably should be.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>

=head1 SEE ALSO

perl(1).

=cut
