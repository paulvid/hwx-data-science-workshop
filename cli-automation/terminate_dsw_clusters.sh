#!/bin/bash
for i in {2..9}
do
   echo "Terminate cluster dsw0$i ..."
   ./cb cluster delete --name dsw0$i
done

for i in {10..23}
do
   echo "Terminate cluster dsw$i ..."
   ./cb cluster delete --name dsw$i
done