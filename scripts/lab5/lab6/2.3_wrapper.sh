gcc 2.3_forking.c -o 2.3_forking

./2.3_forking &

FORKING_PID=$!

pstree -c $FORKING_PID

kill $FORKING_PID
