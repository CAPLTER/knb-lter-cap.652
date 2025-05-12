#!/bin/bash

latest=$(ls -t ~/databaseDumps/survey200* | head -1)

if [ -e "$latest" ] ; then
  # pg_restore -h localhost -U srearl -d caplter ~/databaseDumps/survey200_20240223
  pg_restore -h localhost -U srearl -d caplter "$latest"
  echo "loaded: $latest"
else
  echo "check that survey200 file exists in databaseDumps"
fi
