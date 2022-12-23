#!/bin/bash
FILES=$(find ~ -type f -name "*.txt")
echo "$FILES"
echo -ne "bytes: "
echo $FILES | xargs du -bc 2>/dev/null | tail -1 | cut -f1
echo -ne "lines: "
echo $FILES | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}'
