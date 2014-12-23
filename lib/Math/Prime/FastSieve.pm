package Math::Prime::FastSieve;

use 5.008001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);    ## no critic (isa)

our @EXPORT_OK = qw( primes );    # We can export primes().
our @EXPORT    = qw(        );    # Export nothing by default.

# our $VERSION = 'x.xx';

use Math::Prime::FastSieve::Inline CPP => 'DATA';

# No real code here.  Everything is implemented in pure C++ using
# Inline::CPP.

# I've grown tired of mistyping isprime() as is_prime().
*Math::Prime::FastSieve::Sieve::is_prime
  = \&Math::Prime::FastSieve::Sieve::isprime;

1;

=head1 NAME

Math::Prime::FastSieve - Generate a list of all primes less than or equal
to C<$n>. Do it quickly.

While we're at it, supply a few additional tools that a Prime Sieve
facilitates.

This is an "Alt::" distribution that stands in place of the original.

=head1 DESCRIPTION

This module provides an optimized implementation of the Sieve of
Eratosthenes, and uses it to return a reference to an array all primes up to
any integer specified, within the limitations of addressable memory.

Additionally the module provides access to other Prime-related functions
that are facilitated as a by-product of having a really fast Prime
Sieve.

At the time of writing, the C<primes> function will return all primes
up to and including C<$n> faster than any other module I can find on CPAN
(including Math::Prime::XS).  While a segmented sieve (which this isn't) would
extend the range of primes accessible, the fact that this module uses
a bit-sieve means that primes over a billion are easily within reach
of most modern systems.


=head1 SYNOPSIS

    # ----------    The simple interface:    ----------
    use Math::Prime::FastSieve qw( primes );

    # Obtain an reference to an array containing all primes less than or
    # equal to 5 Million.
    my $aref = primes( 5_000_000 );



    # ----------   The object (far more flexible) interface.   ----------

    # Create a new sieve and flag all primes less or equal to n.
    my $sieve = Math::Prime::FastSieve::Sieve->new( 5_000_000 );

    # Obtain a ref to an array containing all primes <= 5 Million.
    my $aref = $sieve->primes( 5_000_000 );

    # Obtain a ref to an array containing all primes >= 5, and <= 16.
    my $aref = $sieve->ranged_primes( 5, 16 );

    # Query the sieve: Is 17 prime? Return a true or false value.
    my $result = $sieve->isprime( 17 );

    # Get the value of the nearest prime less than or equal to 42.
    my $less_or_equal = $sieve->nearest_le( 42 );

    # Get the value of the nearest prime greater than or equal to 42.
    my $greater_or_equal = $sieve->nearest_ge( 42 );

    # Count how many primes exist within the sieve (ie, count all primes less
    # than or equal to 5 Million, assuming we instantiated the sieve with
    # Math::Prime::FastSieve::Sieve->new( 5_000_000 );.
    my $num_found = $sieve->count_sieve();

    # Count how many primes fall between 1 and 42 inclusive.
    my $quantity_le = $sieve->count_le( 42 );

    # Return the value of the 42nd prime number.
    my $fourty_second_prime = $sieve->nth_prime( 42 );


=head1 EXPORT

Exports nothing by default.  If you ask nicely it will export the single
subroutine, C<primes>.

    use Math::Prime::FastSieve qw( primes );  # Import primes().
    use Math::Prime::FastSieve;               # No imports.

=head1 SUBROUTINES/METHODS

This module provides two modus operandi.  The simplest also happens to
be the fastest way of generating a list of all primes up to and
including C<$n>.  That is via a direct call to the C<primes($n)>
function.

The more powerful way to use this module is via its object oriented
interface.  With that approach, the constructor C<new($n)> creates a
prime sieve flagging all primes from 2 to C<$n> inclusive, and returns
a Sieve object.  That object may then be queried by way of accessor
methods to get at any of the following:

=over 4

=item * C<primes()>
A list of all primes within the sieve.

=item * C<ranged_primes( $lower, $upper )>
A list of all primes >= C<$lower>, and <= C<$upper>.

=item * C<isprime($n)>
=item * C<is_prime($n)>
A primality test for any integer within the bounds of the sieve.  C<is_prime()>
is synonymous for C<isprime()>, mostly because I got tired of forgetting
how to spell the method.

=item * C<nearest_le($n)>
Find the nearest prime less than or equal to C<$n> within the bounds of
the sieve.

=item * C<nearest_ge($n)>
Find the nearest prime greater or equal to C<$n> within the bounds of
the sieve.

=item * C<count_sieve()>
A count of all primes in the sieve.

=item * C<count_le($n)>
A a count of all primes less than or equal to C<$n> within the bounds of
the sieve.

=item * C<nth_prime($n)>
Return the C<$n>th prime, within the bounds of the sieve.

=back

Because the sieve is created when the object is instantiated, many of
the tests you might call on the sieve object will execute quite quickly.
Each of the subs and methods documented below will also attempt to describe
the computational and memory complexity of the function.

=head1 The Standard Interface

=head2 Objective

Provide a fast and simple means of generating a big list of prime
numbers.

=head3 primes()

This is a regular function (ie, not an object method).

Pass a positive integer as its parameter.  Returns a reference to an
array of all prime numbers C<2 .. $n>.

This function is implemented in C++ using Inline::CPP, which in turn
binds it to Perl via XS.  The method used is the Sieve of Eratosthenes.
The sieve is one of the fastest known methods of generating a list of
primes up to C<$n>.

This implementation makes several optimizations beyond the cannonical
Sieve, including:

=over 4

=item * Uses a bit vector as a sieve: A memory optimization that allows
the sieve to scale well without consuming so much memory that your
system grinds to a stand-still for large C<$n>s (where "large" depends
on your system, of course).

=item * The sieve's bits only represent odd numbers (memory optimization).

=item * Only sifts and tests odd integers. (2 is handled as a special case.)

=item * Returns an array-ref rather than a potentially huge (slow) list.

=item * Other micro-optimizations to squeeze a few cycles out here
and there.

=back

The result is a prime number generator that is...fast.  It operates in
O( n log log n ) time, with a O(n) memory growth rate.

=head1 The Object Oriented Interface

=head2 Objective

Where the standard interface wraps the sieve constructor and the sieve
accessor in a single function called C<primes()>, the object oriented
interface places the sieve constructor in
C<Math::Prime::FastSieve::Sieve->new()>, and leaves the interpretation
of the sieve's results to separate accessor methods.  The advantage is
that if you don't really need "a big list", but instead need other
functionality that may be computationally (and memory) cheaper to obtain
from the sieve, you can get at those results without constructing a huge
list of primes.

The standard interface is slightly faster if you just want a big list.  But
the object interface is still very fast, and provides greater flexibility,
including the ability to use C<ranged_primes()> to process primes in smaller,
more memory efficient chunks.


=head3 new()

Class method of C<Math::Prime::FastSieve::Sieve>  Requires a single
integer parameter that represents the largest value to be held in the
sieve.  For example:

    my $sieve = Math::Prime::FastSieve::Sieve->new( 1_000_000_000 );

This will create a Sieve object that flags all integers from 2 to
1 billion that are prime.

Calling C<new()> is an O(n log log n) operation.  The memory growth is at a
rate that is 1/8th the rate of growth of C<$n>.


=head3 primes()

This works just like the standard C<primes()> function, except that it
is a member function of your Sieve object, and also (behind the scenes)
it doesn't need to create a sieve of prime flags since C<new()> already
did that for you.  You must call C<primes()> with an integer parameter.
The integer must be less than or equal to the integer value previously
passed to the C<new()> constructor.  C<primes()> returns a reference to
an array of all prime numbers from 2 to the integer passed to it.

Passing an out-of-bounds integer will result in a return value of an
array ref pointing to an empty array.

    my $primes_ref = $sieve->primes( 1_000_000_000 );
    my $primes_ref = $sieve->primes( 50 );

The C<primes()> method is an O(n) operation for both time and memory.

=head3 ranged_primes()

This behaves exactly like the C<primes()> method, except that you
specify a lower and upper limit within the bounds of the sieve.  The
return value is a reference to an array holding all prime numbers
greater than or equal to the lower limit, and less than or equal to the
upper limit.

The purpose of this method is to allow you to create a sieve ( with
C<new()> ), and then get results in a segmented form.  The reasons this
may be desirable are two-fold:  First, you may only need a subset.
Second, this gives you finer control over how much memory is gobbled up
by the list returned.  For a huge sieve the sieve's memory footprint is
much smaller than the list of integers that are flagged as prime.  By
dealing with that list in chunks you can have a sieve of billions of
prime flags, but never hold that big of a list of integers in memory
all at once.

    my $primes_ref = $sieve->ranged_primes( 5, 16 );
    # $primes_ref now holds [ 5, 7, 11, 13 ].

The time complexity of this method is O(n) where 'n' is the upper limit
minus the lower limit.  So a range of 5_000_000 .. 5_000_010 consumes as
much time as 100 .. 110.


=head3 isprime()
=head3 is_prime()

Pass a parameter consisiting of a single integer within the range of the
Sieve object.  Returns true if the integer is prime, false otherwise.
If the integer is out of the Sieve object's bounds, the result will be
false.

    if( $sieve->isprime(42) ) {
        say "42 is prime.";
    } else {
        say "42 isn't prime.";
    }

C<is_prime()> is a synonym for C<isprime()>.  They're the same method; I
just grew tired of forgetting which spelling to use when calling the
method.

This is an O(1) operation.


=head3 nearest_le()

The C<nearest_le()> method returns the closest prime that is less than
or equal to its integer parameter.  Passing an out of bounds parameter
will return a C<0>.

    my $nearest_less_or_equal = $sieve->nearest_le( 42 );

Since the nearest prime is never very far away, this is an
O( n / ( log n ) ) operation.


=head3 nearest_ge()

Like the C<nearest_le()> method, but this method returns the prime that
is greater than or equal to the input parameter.  If the input param. is
out of range, or if the next prime is out of range, a C<0> is returned.

    my $nearest_greater_or_equal = $sieve->nearest_ge( 42 );

This is also an O( n / ( log n ) ) operation.

By adding one to the return value and passing that new value as a
parameter to the C<nearest_ge()> method again and again in a loop it is
easy to iterate through a list of primes without generating them all
at once.  Of course it's not going to be as fast as getting the big
list all at once, but you can't have everything in life, now can you?


=head3 count_sieve()

Takes no input parameter.  Counts all of the primes in the sieve and
returns the count.  The first time this is called on a Sieve object
the count takes O(n) time.  Subsequent calls benefit from the first
run being cached, and thus become O(1) time.


=head3 count_le()

Pass an integer within the range of the sieve as a parameter.  Return
value is a count of how many primes are less than or equal to that
integer.  If the value passed as a parameter is the same as the size of
the sieve, the results are cached for future calls to C<count_sieve()>.

This is an O(n) operation.


=head3 nth_prime()

This method returns the n-th prime, where C<$n> is the cardinal index in the
sequence of primes.  For example:

    say $sieve->nth_prime(1) # prints 2: the first prime is 2.
    say $sieve->nth_prime(3) # prints 5: the third prime is 5.

If there is no nth prime in the bounds of the sieve C<0> is returned.




=head1 Implementation Notes

The sieve is implemented as a bit sieve using a C++ vector<bool>.  All odd
integers from 3 to C<$n> are represented based on their index within the
sieve. The only even prime, 2, is handled as a special case.  A bit sieve is
highly efficient from a memory standpoint because obviously it only consumes
one byte per eight integers. This sieve is further optimized by reperesenting
only odd integers in the sieve.  So a sieve from 0 .. 1_000_000_000 only needs
500_000_000 bits, or 59.6 MB.

While a bit sieve was used for memory efficiency, just about every
other optimization favored reducing time complexity.

Furthermore, all functions and methods are implemented in C++ by way of
Inline::CPP.  In fact, the sieve itself is never exposed to Perl (this
decision is both a time and memory optimization).

A side effect of using a bit sieve is that the sieve itself actually
requires far less memory than the integer list of primes sifted from it.
That means that the memory bottleneck with the C<primes()> function, as
well as with the C<primes()> object method is not, in fact, the sieve,
but the list passed back to Perl via an array-ref.

If you find that your system memory isn't allowing you to call C<primes>
with as big an integer as you wish, use the object oriented interface.
C<new> will generate a sieve up to the largest integer your system.  Then
rather than calling the C<primes> method, use C<ranged_primes>, or
C<nearest_ge> to iterate over the list. Of course this is slightly slower, but
it beats running out of memory doesn't it?

NOTE: As of version 0.10, support for long ints is built into
Math::Prime::FastSieve.  If your version of Perl was built with support for
long ints, you can create sieve sizes well over the 2.14 billion limit that
standard ints impose.

=head1 DEPENDENCIES

You will need:  L<Inline|Inline>, L<Inline::C|Inline::C> (which is packaged
with Inline), L<Parse::RecDescent|Parse::RecDescent>,
L<Inline::MakeMaker|Inline::MakeMaker>,
L<ExtUtils::MakeMaker|ExtUtils::MakeMaker> (core), and
L<Test::More|Test::More> (core).

=head1 CONFIGURATION AND ENVIRONMENT

In addition to the module dependencies listed in the previous section, your
system must have a C++ compiler that is compatible with the compiler used to
build Perl.  You may need to install one.  Additionally, if your Perl was
built with long integer support, this module will take advantage of that
support.

While it may sound like there are a lot of dependencies and configuration
requirements, in practice, most users should be able to install this module
with the familiar incantations:

    cpan Math::Prime::FastSieve

Or download and unpack the tarball, and...

    perl Makefile.PL
    make
    make test
    make install

Using the cpan shell, cpanm, or cpanplus will have the added benefit of
pulling in and building the dependencies automatically.

=head1 DIAGNOSTICS

If you encounter an installation failure, please email me a transcript of the
session.

=head1 INCOMPATIBILITIES

This module can only be built using systems that have a C++ compiler, and that
are able to cleanly install L<Inline::CPP|Inline::CPP>.  That is going to
cover the majority of potential users.  If you're one of the unlucky few,
please send me an email.  Since I also maintain Inline::CPP, your feeback
may help me to sort out the few remaining installation problems with that
great module.

=head1 AUTHOR

David Oswald, C<< <davido at cpan.org> >>

=head1 BUGS AND LIMITATIONS

Since the Sieve of Eratosthenes requires one 'bit' per integer in the sieve,
the memory requirements can be high for large tests.  Additionally, as the
result set is generated, because Perl's scalars take up a lot more space than
one bit, it's even more likely the entire result set won't fit into memory.

The OO interface does provide functions that don't build a big huge
memory-hungry list.


Please report any bugs or feature requests to
C<bug-math-prime-FastSieve at rt.cpan.org>, or through the web interface
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Prime-FastSieve>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Prime::FastSieve


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Prime-FastSieve>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Prime-FastSieve>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Prime-FastSieve>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Prime-FastSieve/>

=back


=head1 ACKNOWLEDGEMENTS

This module is made possible by Inline::CPP, which wouldn't be possible
without the hard work of the folks involved in the Inline and Inline::C
project.  There are many individuals who have contributed and continue to
contribute to the Inline project.  I won't name them all here, but they do
deserve thanks and credit.

Dana Jacobsen provided several optimizations that improved even further on
the speed and memory performance of this module.  Dana's contributions include
reducing the memory footprint of the bit sieve in half, and trimming cycles by
cutting in half the number of iterations of an inner loop in the sieve
generator.  This module started fast and got even faster (and more memory
efficient) with Dana's contributions.

=head1 SEE ALSO

L<Math::Prime::Util> is a much larger Primes library, by Dana Jacobsen.  In
some cases Math::Prime::FastSieve's object-oriented interface may be a better
fit, but generally speaking, Dana's module is a little faster, and supercedes
this module in its functionality and capabilities.

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2014 David Oswald.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


__DATA__

__CPP__


#include <vector>


using std::vector;


typedef vector<bool> sieve_type;
typedef vector<bool>::size_type sieve_size_t;


/* Class Sieve below.  Perl sees it as a class named
 * "Math::Prime::FastSieve::Sieve".  The constructor is mapped to
 * "new()" within Perl, and the destructor to "DESTROY()".  All other
 * methods are mapped with the same name as declared in the class.
 *
 * Therefore, Perl sees this class approximately like this:
 *
 * package Math::Prime::FastSieve;
 *
 * sub new {
 *     my $class = shift;
 *     my $n     = shift;
 *     my $self = bless {}, $class;
 *     $self->{max_n} = n;
 *     $self->{num_primes} = 0;
 *     # Build the sieve here...
 *     # I won't bother translating it to Perl.
 *     $self->{sieve} = $primes;  // A reference to a bit vector.
 *     return $self;
 *  }
 *
 */


class Sieve
{
  public:
    Sieve ( long n ); // Constructor. Perl sees "new()".
    bool           isprime      ( long n );    // Test if n is prime.
    SV*            primes       ( long n );    // All primes in an aref.
    unsigned long  nearest_le   ( long n );    // Nearest prime <= n.
    unsigned long  nearest_ge   ( long n );    // Nearest prime >= n.
    unsigned long  nth_prime    ( long n );    // The nth prime.
    unsigned long  count_sieve  (        );    // Sieve's prime count.
    unsigned long  count_le     ( long n );    // Number of primes <= n.
    SV*            ranged_primes( long lower, long upper );

  private:
    sieve_size_t   max_n;
    unsigned long  num_primes;
    sieve_type     sieve;
};


// Set up a primes sieve of 0 .. n inclusive.
// This sieve has been optimized to only represent odds, cutting memory
// footprint in half.
Sieve::Sieve( long n ) :max_n(n), num_primes(0), sieve(n/2+1,0)
{
   if( n < 0 ) // Trap negative n's before we start wielding unsigned longs.
        max_n = 0UL;
    else {
        for( sieve_size_t i = 3; i * i <= n; i+=2 )
            if( ! sieve[i/2] )
                for( sieve_size_t k = i*i; k <= n; k += 2*i)
                    sieve[k/2] = 1;
    }
}


// Yes or no: Is the number a prime?  Must be within the range of
// 0 through max_n (the upper limit set by the constructor).
bool Sieve::isprime( long n )
{
    if( n < 2 || n > max_n )  return false; // Bounds checking.
    if( n == 2 )              return true;  // 2 is prime.
    if( ! ( n % 2 ) )         return false; // No other evens are prime.
    if( ! sieve[n/2] )        return true;  // 0 bit signifies prime.
    return false;                           // default: not prime.
}


// Return a reference to an array containing the list of all primes
// less than or equal to n.  n must be within the range set in the
// constructor.
SV* Sieve::primes( long n )
{
    AV* av = newAV();
    if( n < 2 || n > max_n ) // Logical short circuit order is significant
                             // since we're about to wield unsigned longs.
        return newRV_noinc( (SV*) av );
    av_push( av, newSVuv( 2UL ) );
    for( sieve_size_t i = 3; i <= n; i += 2 )
        if( ! sieve[i/2] )
            av_push( av, newSVuv( static_cast<unsigned long>(i) ) );
    return newRV_noinc( (SV*) av );
}

SV* Sieve::ranged_primes( long lower, long upper )
{
    AV* av = newAV();
    if(
        upper > max_n ||        // upper exceeds upper bound.
        lower > max_n ||        // lower exceeds upper bound.
        upper < 2     ||        // No possible primes.
        lower < 0     ||        // lower underruns bounds.
        lower > upper ||        // zero-width range.
        ( lower == upper && lower > 2 && !( lower % 2 ) ) // Even.
    )
        return newRV_noinc( (SV*) av );  // No primes possible.
    if( lower <= 2 && upper >= 2 )
        av_push( av, newSVuv( 2UL ) );    // Lower limit needs to be odd
    if( lower < 3 ) lower = 3;           // Lower limit cannot < 3.
    if( ( upper - lower ) > 0 && ! ( lower % 2 ) ) ++lower;
    for( sieve_size_t i = lower; i <= upper; i += 2 )
        if( ! sieve[i/2] )
            av_push( av, newSVuv( static_cast<unsigned long>(i) ) );
    return newRV_noinc( (SV*) av );
}


// Find the nearest prime less than or equal to n.  Very fast.
unsigned long Sieve::nearest_le( long n )
{
    // Remember that order of testing is significant; we have to
    // disqualify negative numbers before we do comparisons against
    // unsigned longs.
    if( n < 2 || n > max_n ) return 0; // Bounds checking.
    if( n == 2 ) return 2UL;            // 2 is the only even prime.
    // Even numbers map to the next odd number down.
    sieve_size_t n_idx = (n-1)/2;  // n_idx >= 1
    do {
       if( ! sieve[n_idx] )  return static_cast<unsigned long>(2*n_idx+1);
    } while (--n_idx > 0);
    return 0UL; // We should never get here.
}


// Find the nearest prime greater than or equal to n.  Very fast.
unsigned long Sieve::nearest_ge( long n )
{
    // Order of bounds tests IS significant.
    // Because max_n is unsigned, testing "n > max_n" for values where
    // n is negative results in n being treated as a real big unsigned value.
    // Thus we MUST handle negatives before testing max_n.
    if( n <= 2 ) return 2UL;              // 2 is only even prime.
    n |= 1;                               // Make sure n is odd before check.
    if( n > max_n ) return 0UL;           // Bounds checking.
    sieve_size_t n_idx   = n/2;
    sieve_size_t max_idx = max_n/2;
    do {
       if( ! sieve[n_idx] )  return static_cast<unsigned long>(2*n_idx+1);
    } while (++n_idx < max_idx);
    return 0UL;   // We've run out of sieve to test.
}


// Since we're only storing the sieve (not the primes list), this is a
// linear time operation: O(n).
unsigned long Sieve::nth_prime( long n )
{
    if( n <  1     ) return 0; // Why would anyone want the 0th prime?
    if( n >  max_n ) return 0; // There can't be more primes than sieve.
    if( n == 1     ) return 2; // We have to handle the only even prime.
    unsigned long count = 1;
    for( sieve_size_t i = 3; i <= max_n; i += 2 )
    {
        if( ! sieve[i/2] ) ++count;
        if( count == n ) return static_cast<unsigned long>(i);
    }
    return 0UL;
}


// Return the number of primes in the sieve.  Once results are
// calculated, they're cached.  First time through is O(n).
unsigned long Sieve::count_sieve ()
{
    if( num_primes > 0 ) return num_primes;
    num_primes = this->count_le( max_n );
    return num_primes;
}


// Return the number of primes less than or equal to n.  If n == max_n
// the data member num_primes will be set.
unsigned long Sieve::count_le( long n )
{
    if( n <= 1 || n > max_n ) return 0UL;
    unsigned long count = 1UL;      // 2 is prime. Count it.
    for( sieve_size_t i = 3; i <= n; i+=2 )
        if( !sieve[i/2] ) ++count;
    if( n == max_n && num_primes == 0 ) num_primes = count;
    return count;
}


// ---------------- For export: Not part of Sieve class ----------------

/* Sieve of Eratosthenes.  Return a reference to an array containing all
 * prime numbers less than or equal to search_to.  Uses an optimized sieve
 * that requires one bit per odd from 0 .. n.  Evens aren't represented in the
 * sieve.  2 is just handled as a special case.
 */

SV* primes( long search_to )
{
    AV* av = newAV();
    if( search_to < 2 )
        return newRV_noinc( (SV*) av ); // Return an empty list ref.
    av_push( av, newSVuv( 2UL ) );
    // Allocate space for odd numbers (15 bits per 30 values)
    sieve_type primes( search_to/2 + 1, 0 );
    // Sieve over the odd numbers
    for( sieve_size_t i = 3; i * i <= search_to; i+=2 )
        if( ! primes[i/2] )
            for( sieve_size_t k = i*i; k <= search_to; k += 2*i)
                primes[k/2] = 1;
    // Add each prime to the list ref
    for( sieve_size_t i = 3; i <= search_to; i += 2 )
        if( ! primes[i/2] )
          av_push( av, newSVuv( static_cast<unsigned long>( i ) ) );
    return newRV_noinc( (SV*) av );
}
