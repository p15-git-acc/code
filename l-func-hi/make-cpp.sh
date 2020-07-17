#!/bin/bash
#
g++ -O2 -o $1 ${1}.cpp mpfi-fft.o -I $FFTWINCLUDE -I /panfs/panasas01/math/madjp/arb-master/ -I /panfs/panasas01/math/madjp/flint2-trunk -I /panfs/panasas01/math/madjp/mpfi-1.5.1/src -I /panfs/panasas01/math/madjp/mpfr-3.1.2/src -I /panfs/panasas01/math/madjp/gmp-5.1.3 -L /panfs/panasas01/math/madjp/arb-master/ -larb -L /panfs/panasas01/math/madjp/flint2-trunk -lflint -L /panfs/panasas01/math/madjp/mpfi-1.5.1/src/.libs/ -lmpfi -L /panfs/panasas01/math/madjp/mpfr-3.1.2/src/.libs/ -lmpfr -L /panfs/panasas01/math/madjp/gmp-5.1.3/.libs/ -lgmp -L $FFTWDIR -lfftw3
