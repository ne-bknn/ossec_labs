#!/bin/bash
md5sum *.txt | sort -k2 | uniq -w32 -d -c | sort -k1 | awk '{print $1,$3}'
