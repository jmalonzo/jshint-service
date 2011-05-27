#!/bin/bash
# add to or replace .git/hooks/pre-commit

# helper to print information for users on bad exit status
function on_error {
  if [[ $? -gt 0 ]]; then
    echo [error] "$1"
    exit 0
  fi
}

# Prevent console.log() or alert statements from being committed.
# adapted from jlindley's console check https://gist.github.com/673376
grep_bad=$(grep -inR "console\.\|alert(" js/*.js)
count=$(echo -e "$grep_bad" | grep "[^\s]" | wc -l | awk '{print $1}')

if [[ "$count" -ge 1 ]]; then
  echo "[warning] aborting commit" 1>&2
  echo "[warning] $count config.log/alert found:" 1>&2
  echo -e "$grep_bad" 1>&2
  exit 1
fi

# check connection
ping -c 1 -w 1 google.com > /dev/null
on_error "internet connection appears to be down, skipping jshint"

# check for curl
which curl > /dev/null
on_error "curl is required to contact jshint service, please install"

#TODO point at actual service
jshint_uri=http://33.33.33.10:3000/

# git command aped from https://github.com/jish/pre-commit/blob/master/lib/pre-commit/utils.rb
# grabs all the names of the files staged in the index
for file in $(git diff --cached --name-only --diff-filter=ACM | grep "\.js$"); do
  contents=$(cat "$file")

	# push the current file's contents to the jshint service
  hints=$(curl -s --connect-timeout 2 -f -H "Content-Type: text/javascript" -X POST -d "$contents" "$jshint_uri")
  on_error "couldn't connect to $jshint_uri"

	# if there's at least one line of output from the curl reponse
	# dump it to stdout for review
  counts=$(echo -e "$hints" | grep "[^\s]" | wc -l)
  if [[  "$counts" -gt 0 ]]; then
    echo
    echo "$file":
    echo "$hints"
  fi
done