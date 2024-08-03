#!/usr/bin/env bash

set -eu

resolve_link() {
  local the_link=$1
  local ls_res=
  local link_target=
  while [ -h "$the_link" ] ; do
    ls_res="$(ls -ld "$the_link")"
    link_target=$(expr "$ls_res" : '.*-> \(.*\)$')
    if [ "$(echo "$link_target" | cut -c 1)" = "/" ] ; then
      the_link="$link_target"
    else
      the_link="$(dirname "$the_link")/$link_target"
    fi
  done
  printf '%s' "$the_link"
}

this_file="$0"
if ! [ -e "$this_file" ] ; then
  this_file="$(type -p "$this_file")"
fi
if ! [ -e "$this_file" ] ; then
  echo "Failed to resolve file."
  exit 1
fi
if [ "$(echo "$this_file" | cut -c 1)" != "/" ] ; then
  this_file="$(pwd)/$this_file"
fi
this_file="$(resolve_link "$this_file")"
this_dir="$(dirname "$this_file")"

# build frontend
(cd "${this_dir}/templates" ; yarn install ; npx quasar build)

# launch backend with supervisor
sudo apt install supervisor
sudo ln -s "${this_dir}/supervisord.conf" /etc/supervisor/conf.d/
(sudo cd /etc/supervisor && sudo supervisorctl restart greaterwms)

# start nginx
sudo ln -s "${this_dir}/wms-nginx.conf" /etc/nginx/conf.d/
sudo nginx -s reload

