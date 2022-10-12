#!/bin/bash

SW_DEV=$PWD/sw-dev
if [ ! -z "$QT_BUILD_SWDEV" ]; then
  SW_DEV=$QT_BUILD_SWDEV
fi

if [ ! -d "$SW_DEV" ]; then
  echo "Please set QT_BUILD_SWDEV to a valid sw-dev directory path; $SW_DEV does not exist"
  exit 1;
fi
