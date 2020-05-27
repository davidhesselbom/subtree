#!/bin/bash

# TODO: Consider changing "main" to "application", "sub" to "library", "subt" to "libraryrepo" or similar,
# to avoid the confusion between "sub" and "subt", without using the word "subtree" for either the repo or the remote.

gitdiffsubtree() {
    # Diff the master branch in the remote "subt" with the "sub" folder in the local master branch (at least, that's what I think this does...)
    git diff subt/master master:sub

    # [[ $(command) ]] returns "0" (true) if the command outputs anything
    # git diff only outputs something if there is a difference. In that case, print the message.
    [[ $(git diff subt/master master:sub) ]] && echo "There are unmerged commits in subtree!"
    # Similarly, [[ -z $(command) ]] returns "0" (true) if the commands outputs nothing.
    [[ -z $(git diff subt/master master:sub) ]] && echo "No unmerged commits in subtree!"

    # gif diff will list, each on a new line, each commit that doesn't exist both locally and on the remote,
    # and also each modified file. The line will start with a single '+' for local commits and '+++' for modified files.
    # The regex '^\+([\+])' means "lines that start with a '+' that is not followed by more '+'".
    git diff subt/master master:sub | grep -E '^\+([\+])'
    [[ $(git diff subt/master master:sub | grep -E '^\+([\+])') ]] && echo "There are unmerged local subtree commits!"
    # Similarly, the line will start with a single '-' for remote commits and '---' for modified files.
    git diff subt/master master:sub | grep -E '^\-([\-])'
    [[ $(git diff subt/master master:sub | grep -E '^\-([\-])') ]] && echo "There are unmerged remote subtree commits!"
}

set -v

###########################################################
# Create main repository on "GitHub"
###########################################################

mkdir -p github/main
cd github/main
git init --bare
cd ../..

###########################################################
# Create future subtree repository on "GitHub"
###########################################################

mkdir -p github/sub
cd github/sub
git init --bare
cd ../..

###########################################################
# Clone main repository to "local" folder, and add a commit
###########################################################

git clone github/main
cd main
echo "First main commit" > readme.txt
git add readme.txt
git commit -m "First main commit"
git push origin master
cd ..

###########################################################
# Clone sub repository to "local" folder, and add a commit
###########################################################

git clone github/sub
cd sub
echo "First sub commit" > readme.txt
git add readme.txt
git commit -m "First sub commit"

# Add another commit, so there's something to squash in the main repo later
###########################################################

echo "Second sub commit" >> readme.txt
git add readme.txt
git commit -m "Second sub commit"
git push origin master
cd ..

###########################################################
# Make sub repo a subtree in main repo
###########################################################

cd main
git remote add -f subt ../github/sub
git subtree add --prefix sub subt master --squash -m "Merged changes in subtree until $(git rev-parse subt/master)"
git push origin master
cd ..

###########################################################
# Make changes in sub repo
###########################################################

cd sub
echo "Third sub commit" >> readme.txt
git add readme.txt
git commit -m "Third sub sommit"
echo "Fourth sub commit" >> readme.txt
git add readme.txt
git commit -m "Fourth sub sommit"
git push origin master
cd ..

###########################################################
# Update subtree in main
###########################################################

cd main
git fetch subt master

# There should be unmerged commits in the subtree now
###########################################################

gitdiffsubtree
git subtree pull --prefix sub subt master --squash -m "Merged changes in subtree until $(git rev-parse subt/master)"

# There should be no unmerged commits in the subtree now
###########################################################

gitdiffsubtree

# Push the changes made to the local main repository to "GitHub"
###########################################################

git push origin master
cd ..

###########################################################
# Update sub repo again
###########################################################

cd sub
echo "Fifth sub commit" >> readme.txt
git add readme.txt
git commit -m "Fifth sub sommit"
echo "Sixth sub commit" >> readme.txt
git add readme.txt
git commit -m "Sixth sub sommit"
git push origin master
cd ..

###########################################################
# Delete main clone, make a new clone, and try to update its subtree
###########################################################

rm -rf main
git clone github/main
cd main
git remote add -f subt ../github/sub
git fetch subt master
git subtree pull --prefix sub subt master --squash -m "Merged changes in subtree until $(git rev-parse subt/master)"
git push origin master
cd ..

###########################################################
# Add commits to subtree inside main
###########################################################

cd main/sub
echo "Seventh sub commit" >> readme.txt
git add readme.txt
git commit -m "Seventh sub sommit"
echo "Eighth sub commit" >> readme.txt
git add readme.txt
git commit -m "Eighth sub sommit"
cd ..
gitdiffsubtree

# Push the subtree commits to the "GitHub" sub repo
###########################################################

git subtree push --prefix=sub subt master
gitdiffsubtree

# Push the changes in main to the "GitHub" main repo
###########################################################

git push origin master
cd ..

###########################################################
# Update the local sub repo
###########################################################

cd sub
git pull origin master
cd ..
