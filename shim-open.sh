#!/bin/bash

if [ -z $1 ]; then
    exit
fi

file_path=$1

# Extract the parent directory from the provided path.
# The `dirname` command is used to strip the non-directory suffix.
parent_dir=$(dirname "$file_path")
filename=$(basename "$file_path")

# Check if the parent directory exists and is a directory.
# The `-d` test checks for the existence and type of the file.
if [ ! -d "$parent_dir" ]; then
  echo "The parent directory '$parent_dir' does not exist."
  exit 1
fi

absolute_parent=$(realpath "$parent_dir")
absolute_path=$absolute_parent/$filename

echo you would like to open $absolute_path
ssh -p 6678 vim@localhost python3 /shim/open_files.py $absolute_path
