#!/bin/bash

if [[ ! -f .qmake.super ]]; then
  echo "need to create an empty file ${BUILD_DIRECTORY}/.qmake.super. This appears"
  echo "to be a long-standing bug. This should be checked periodically to see if it is fixed."
  if ! touch .qmake.super; then
    echo "Failed to touch the file. Build exiting."
    exit -1
  fi
fi