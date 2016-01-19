#!/bin/bash

# Replace "sculpin generate" with "php sculpin.phar generate" if sculpin.phar
# was downloaded and placed in this directory instead of sculpin having been
# installed globally.

sculpin generate --env=prod --url=http://rjsmelo.com
if [ $? -ne 0 ]; then echo "Could not generate the site"; exit 1; fi

git stash
git checkout master

cp -R output_prod/* .
git add *
git status

echo -n "Do you want to commit changes (y/n): "
read COMMIT 
if [ "_$COMMIT" != "_y" ] ; then
	echo "Aborted by user command, please commit manually"
	exit 1
fi

git commit
git push origin --all

git checkout source
git stash pop

