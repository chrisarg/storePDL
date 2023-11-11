#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl
use v5.38;
###############################################################################
## dependencies
use Config;                    # for getting size of integers
use FindBin   qw($Bin);        # for finding the script location
use Benchmark qw(timethis);    # for benchmarking
use PDL;
use PDL::Core ':Internal';
use List::Util;                # for finding the minimum and maximum
use Inline 'C';

###############################################################################

my $n=200_000; ## number of elements in the array

my $scaling_factor_for_benchmark = ceil(100_000/$n);

my $result;


## create a string that packs an array of integers
## for timing purposes
for (1..$n){
    $result .= pack "i", $_;
}

my @array = unpack "i*", $result;

say "Testbench will use an array size of $n elements";
say "+" x 80;
say "Creation of a string that packs an array ofintegers";
timethis(
    100 * $scaling_factor_for_benchmark ,
    sub {
        my $result;
        for (1..$n){
            $result .= pack "i", $_;
        }
    }
);
say "+" x 80;

say "Unpacking string into a perl array";
timethis(
    100 * $scaling_factor_for_benchmark,
    sub {
        my @array = unpack "i*", $result;
    }
);
say "+" x 80;

say "Transforming a packed string into an array, and substracting\n"
 . " the maximum from its elements using Inline C";
timethis(500 * $scaling_factor_for_benchmark , sub{
    my $result2 = $result;
    subtract_max($result2, $n);
    });
say "+" x 80;

say "Transforming a packed string into a ndarray, substracting\n"
 . " the maximum from its elements, scaling and exponentiating using PDL";
timethis(100 * $scaling_factor_for_benchmark , sub {
    my $pdl = pdl(long(), [1]);
    $pdl->reshape($n);

    my $dr = $pdl->get_dataref;
    $$dr = $result;
    $pdl->upd_data();
    $pdl->inplace->minus($pdl->max);
    $pdl =$pdl->double;
    $pdl->inplace->mult(0.123);
    $pdl->inplace->exp;
});
say "+" x 80;

say "Transforming a packed string into a perl array,  substracting\n"
 . " the maximum from its elements, scaling and exponentiating using native perl";
timethis(50 * $scaling_factor_for_benchmark , sub {
    my @array = unpack "i*", $result;
    my $max = List::Util::max(@array);
    @array = map { exp(0.123* ($_ - $max ) )} @array;
});
say "+" x 80;


__END__

__C__



void subtract_max(char * packed_data, int size) {
    int * int_ptr = (int*) packed_data;
    /* allocate a double pointer of size size */
    double * array = (double*)malloc(size * sizeof(double));
    
    int max = int_ptr[0];

    // Find the maximum value
    for (int i = 1; i < size; i++) {
        if (int_ptr[i] > max) {
            max = int_ptr[i];
        }
    }
    // Subtract the maximum value from each element
    for (int i = 0; i < size; i++) {
        array[i] = exp(0.123*(int_ptr[i] - max));
    }
   free(array);    
}