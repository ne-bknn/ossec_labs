gcc 2.2_forking.c -o 2.2_forking

./2.2_forking &

FORKING_PID=$!

pstree $FORKING_PID

kill $FORKING_PID
