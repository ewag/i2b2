#!/usr/bin/env bash
## Author: Marc Griffiths
## Description: Rotate link and location of optional stats page

## Use prefix so its always easily itentifyable (this is how we identify the old key - dsk = Dynamic Stats Key)
key_prefix="dsk-"
rand_length=16
## Nothing to configure below here

old_key=$(ls -1 /var/www/html/ | grep ${key_prefix})
if [[ $old_key == "" ]] ; then
    echo "Initialising 'old_key'..."
    old_key=$(echo "${key_prefix}base")
fi

echo "$(date --iso-8601) $(date +%R) -- Begin stats key/link rotation"
## Generate new random key
new_key=${key_prefix}$(tr -dc A-Za-z0-9 </dev/urandom | head -c ${rand_length})

## Rename path
if [[ ! -d /var/www/html/${old_key} ]] ; then
  mkdir /var/www/html/${old_key}
  echo "Directory did not already exist! Created: /var/www/html/${old_key}"
fi
mv /var/www/html/{${old_key},${new_key}}
echo "Renamed: /var/www/html/${old_key} => /var/www/html/${new_key} "

## Update links
#i2b2
# sed -i.bak "s/${old_key}/${new_key}/g" /var/www/html/webclient/default.htm
sed -i.bak "s/${key_prefix}[^/]*/${new_key}/g" /var/www/html/webclient/default.htm
#base_path in stats app
# sed -i.bak "s/${old_key}/${new_key}/g" /var/www/html/${new_key}/index.html
sed -i.bak "s/${key_prefix}[^/]*/${new_key}/g"  /var/www/html/${new_key}/index.html
echo "Updated key in /var/www/html/webclient/default.htm and /var/www/html/${new_key}/index.html"
