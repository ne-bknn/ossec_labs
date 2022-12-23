#!/bin/bash

REGULAR=$(find ~/ -maxdepth 1 -type f \! -name ".*" | wc -l)
HIDDEN=$(find ~/ -maxdepth 1 -type f -name ".*" | wc -l)

printf "Домашний каталог пользователя\n$USER\nсодержит обычных файлов:\n$REGULAR\nскрытых файлов:\n$HIDDEN\n"
