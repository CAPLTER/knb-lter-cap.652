#!/bin/bash

latest=$(ls -t ~/databaseDumps/survey200* | head -1)

if [ -e "$latest" ] ; then
  psql -h localhost -U srearl -d caplter -c "DROP SCHEMA IF EXISTS survey200 CASCADE ;"
  pg_restore -h localhost -U srearl -d caplter "$latest"
  echo "loaded: $latest"
else
  echo "check that survey200 file exists in databaseDumps"
fi
