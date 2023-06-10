#!/bin/bash

while read -r line; do
  cloc_out=$(cloc $line | grep SUM)
  IFS=' ' read -r array <<< "$cloc_out"
  echo "Repository: $line \nFiles: ${array[1]} \nblank: ${array[2]} \nComment: ${array[3]} \nTotal LOC: ${array[4]}"
done <../repositories.cfg