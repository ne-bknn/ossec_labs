#!/bin/bash

while IFS='$\n' read -r line
do
	echo "$line" | grep -w bin >&2
done
