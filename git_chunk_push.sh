#!/bin/bash

# Script to split a large Git push into chunks to avoid Git's 2 GiB push limit
# This assumes your repo already has changes staged or untracked files.

# Constants
CHUNK_SIZE=10  # Number of chunks (adjust as needed)
REMOTE="origin"  # Change this if your remote is named differently
BRANCH="main"  # Commit to the main branch

# Ensure we are in a Git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not a Git repository. Exiting."
    exit 1
fi

# Get the list of changed files
FILES=($(git status --porcelain | awk '{print $2}'))
TOTAL_FILES=${#FILES[@]}

if [ $TOTAL_FILES -eq 0 ]; then
    echo "No changes to commit. Exiting."
    exit 0
fi

# Calculate number of files per chunk
FILES_PER_CHUNK=$(( (TOTAL_FILES + CHUNK_SIZE - 1) / CHUNK_SIZE ))

# Loop to commit and push in chunks
for ((i=0; i<CHUNK_SIZE; i++)); do
    START_INDEX=$((i * FILES_PER_CHUNK))
    END_INDEX=$((START_INDEX + FILES_PER_CHUNK - 1))

    if [ $START_INDEX -ge $TOTAL_FILES ]; then
        break
    fi

    # Prepare chunk
    CHUNK_FILES=(${FILES[@]:$START_INDEX:$FILES_PER_CHUNK})
    echo "Staging files ${START_INDEX} to ${END_INDEX}:"
    printf '%s\n' "${CHUNK_FILES[@]}"

    # Stage files
    git add "${CHUNK_FILES[@]}"

    # Commit changes
    COMMIT_MSG="Chunk $(($i + 1)) of $CHUNK_SIZE: Adding ${#CHUNK_FILES[@]} files"
    echo "Committing: $COMMIT_MSG"
    git commit -m "$COMMIT_MSG"

    # Push changes with --force
    echo "Pushing chunk $(($i + 1))..."
    git push --force $REMOTE $BRANCH
    
    echo "Chunk $(($i + 1)) pushed successfully."
    echo "---------------------------------"
done

echo "All chunks committed and pushed successfully!"
