#!/bin/bash
for i in {3..9}
do
   echo "Launching cluster dsw0$i ..."
   ./cb cluster create --cli-input-json template.json --name dsw0$i
done

for i in {10..23}
do
   echo "Launching cluster dsw$i ..."
   ./cb cluster create --cli-input-json template.json --name dsw$i
done