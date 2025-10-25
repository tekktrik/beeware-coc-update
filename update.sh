#!/bin/bash

# Information about this code
this_repo="tekktrik/beeware-coc-update"
author="Alec Delaney"
author_email="tekktrik@gmail.com"
user="tekktrik"

# Information about destination and changes
owner=beeware
coc_filename=CODE_OF_CONDUCT.md

# Create a temporary working directory
echo "Creating temporary working directory..."
if [ ! -d temp ]; then
    mkdir temp
fi
cd temp
timestamp=$(date +%s)
mkdir $timestamp
cd $timestamp

# Get all non-archived repositories
readarray -t repo_list < <(gh repo list $owner --no-archived --json name --jq ".[].name")

# Save a list of repositories for deletion after pull requests are merged
for repo in "${repo_list[@]}"; do
  echo "$repo"
done > "../../repo_list.txt"

# Make changes to found repos
for repo in "${repo_list[@]}"; do

    # Skip the .github repo
    full_repo="$owner/$repo"

    # Fork and clone the repo
    echo "Forking and cloning $full_repo..."
    gh repo fork $full_repo --clone --remote
    cd $repo
    git config --local user.name "$author"
    git config --local user.email "$author_email"

    # Make new branch for change
    echo "Creating new branch..."
    branch_name="$user-coc-update"
    git checkout -b $branch_name

    # Add the new code of conduct
    echo "Replacing Code of Conduct..."
    cp ../../$coc_filename .

    # Commit and push the update
    echo "Syncing updates to remote..."
    git add "$coc_filename"
    git commit -m "Updated code of conduct"
    git push --set-upstream origin "$branch_name"

    # Create the pull request
    echo "Creating pull request to upstream..."
    gh pr create --repo $full_repo --title "Update Code of Conduct" --body "Updated using $this_repo"

    # Exit completed repo
    cd ..
done

# Remove the temporary working directory
cd ..
rm -rf $timestamp

cd ..
rm -rf temp
