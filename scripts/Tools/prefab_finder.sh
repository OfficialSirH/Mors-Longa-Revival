#!/bin/bash

# Define the root folder
root_folder="../../prefabs/spawnables/enemies"

# Define the list of folders
folders=(
    "civilian"
    "cult"
    "millitary"
    "security"
    "survior"
    "um"
    "vip"
)

# Loop through each folder in the list
for folder in "${folders[@]}"; do
    # Get all files in the folder
    files=$(find "$root_folder/$folder" -type f)

    # Loop through each file
    for file in $files; do
        # Print the file with its relative path from the root folder
        echo "MOD/prefabs/spawnables/enemies/${file#$root_folder/}"
    done
done