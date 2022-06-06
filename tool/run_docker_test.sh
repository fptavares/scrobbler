#!/bin/bash

set -e

image="$(docker build -q -f pkgs/bluos_monitor_server/Dockerfile .)"
echo Image created: "$image"
container=$(docker run -d -p 8080:8080 --rm "$image")
echo Container started: "$container"
sleep 1
cd pkgs/bluos_monitor_server && dart test test/docker_test.dart -t docker-test --run-skipped || EXIT_CODE=$?
echo Container killed "$(docker kill "$container")"
echo Image deleted "$(docker rmi "$image")"
exit ${EXIT_CODE}
