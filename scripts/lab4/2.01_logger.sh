#!/bin/bash

date >> /tmp/run.log
echo "Hello world"
wc -l >&2 < /tmp/run.log
