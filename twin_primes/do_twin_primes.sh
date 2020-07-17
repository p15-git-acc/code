#!/bin/bash
#
#PBS -l walltime=240:00:00,nodes=1:ppn=16
#PBS -q medium
date
hostname
cd $HOME/code/twin_primes/results
mkdir /local/madjp
#st=100000000000000000
cs=16
gap=10000000000
#its=64
biggap=$(($its * $gap))
for((n=0;n<cs;n++))
do
   en=$(($st + $biggap))   
   ../twin_primes_serial $st $en $gap > /local/madjp/twin_primes_${st}_${en}.dat &
   st=$en
done
wait
cp /local/madjp/twin_primes_* .
rm -f /local/madjp/*
rmdir /local/madjp
date
