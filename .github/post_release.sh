#!/bin/bash
# $1 == GH_TOKEN
# $2 == org/repo
# $3 == release_version
# $4 == next_version

echo -n "Retrieving current milestone URL: "
milestone_url=`curl -s https://api.github.com/repos/$2/milestones | jq -c ".[] | select (.title == \"$3\") | .url" | sed -e 's/"//g'`
echo $milestone_url

echo "Closing current milestone"
curl -s --request PATCH -H "Authorization: Bearer $1" -H "Content-Type: application/json" $milestone_url --data '{"state":"closed"}'

echo "Creating new milestone"
curl -s --request POST -H "Authorization: Bearer $1" -H "Content-Type: application/json" "https://api.github.com/repos/$2/milestones" --data "{\"title\": \"$4\"}"

echo "Setting new snapshot version"
sed -i "s/^projectVersion.*$/projectVersion\=${4}-SNAPSHOT/" gradle.properties
cat gradle.properties

echo "Configuring git"
git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git config --global user.name "${GITHUB_ACTOR}"
echo "Fetching from origin"
git fetch
echo "Checking out master"
git checkout master
git add gradle.properties 
git commit -m "Back to snapshot"
echo "Pushing"
git push origin master