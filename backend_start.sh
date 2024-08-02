#!/bin/bash

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

. "${this_dir}/.venv/bin/activate"

python3 manage.py makemigrations
python3 manage.py migrate

echo "starting daphne"
daphne -b 0.0.0.0 -p 8008 greaterwms.asgi:application
echo "starting daphne ok"
