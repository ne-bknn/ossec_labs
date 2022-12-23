#!/bin/bash

du ~/ -a 2>/dev/null | sort -k1 -n -r | awk '{print $2}'
