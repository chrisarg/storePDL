# storePDL
Examines various ways to process long arrays of integers in perl, PDL and inline C. 
This is just preliminary work to iron out some design decisions for a Nanonore sequence alignment application.

**The code is straightforward:**
1. Store an array of integers by packing them into a perl string one by one. These integers could represent for example, alignment scores from a database search
2. Benchmark the creation process and the unpacking of said string into native perl arrays
3. Benchmark passing the string as a void pointer to an _inlined C_ function that transforms the array of integers into un-normalized alignment probabilities by subtracting the maximum score, scaling the differences and then exponentiating
4. Carry out the computations under 3 using _PDL_
5. Carry out the computations under 4 using native _perl_

One can benchmark the performance of the 3 approaches using different array sizes (number of integers under 1). While C is always faster, small problems will execute faster in native perl. As the problem sizes grows, one will see the following pattern emerging: 
**inline C ~ 2 - 5 x PDL ~ 3 - 4 x native perl**

The scaling factors depend very much on whether the cache is sufficient to contain the arrays and the overhead for storing them in PDL and native perl. 
The preprint [Practical Magick with C, PDL, and PDL::PP -- a guide to compiled add-ons for PDL](https://arxiv.org/abs/1702.07753) goes into much more detail about various hacks that can simultaneously leverage the PDL interface and inlined C code. 
