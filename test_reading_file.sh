#!/bin/bash

FILE_PATH=$1

declare -a paths_methods

# Read the file line by line
while IFS= read -r line
do
 # Check if the line contains a path
 if [[ $line == *'"path": "'* ]]; then
 # Extract the path
 path=$(echo $line | awk -F'"path": "' '{print $2}' | awk -F'"' '{print $1}')
 # Add the path to the array
 paths_methods+=("$path")
 fi

 # Check if the line contains a method
 if [[ $line == *'"method": "'* ]]; then
 # Extract the method
 method=$(echo $line | awk -F'"method": "' '{print $2}' | awk -F'"' '{print $1}')
 # Add the method to the array
 paths_methods+=("$method")
 fi
done < $FILE_PATH

# Print the paths and methods
for ((i=0; i<${#paths_methods[@]}; i+=2)); do
 echo "Path: ${paths_methods[$i]}, ${paths_methods[$i+1]}"
done