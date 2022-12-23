#!/bin/bash

date
echo

w -h
echo

uptime | awk '{print $3}' | sed -s 's/,//g'
