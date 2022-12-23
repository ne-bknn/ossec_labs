#!/bin/bash 

cat bash.txt | grep "000000" > /tmp/zeros

cat bash.txt | grep -v "000000" > /tmp/nozeros

echo "head -10 /tmp/zeros"
head -10 /tmp/zeros

echo "tail -10 /tmp/zeros"
tail -10 /tmp/zeros

echo "head -10 /tmp/nozeros"
head -10 /tmp/nozeros

echo "tail -10 /tmp/nozeros"
tail -10 /tmp/nozeros
