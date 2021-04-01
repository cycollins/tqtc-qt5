#!/usr/bin/env bash

set -ex

# Activate these modules
sudo SUSEConnect -p sle-module-desktop-applications/15/x86_64
sudo SUSEConnect -p sle-module-development-tools/15/x86_64
# This is needed by Nodejs and QtWebEngine
sudo SUSEConnect -p sle-module-web-scripting/15/x86_64
