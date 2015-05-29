#!/bin/bash

response=$(curl --write-out %{http_code} --max-time 5 --connect-timeout 5  --silent --output /dev/null http://localhost)

if [ $response -eq 200 ]; then
  echo "Http working.";
else
  echo "Restarting http service"
  service starman restart
fi
