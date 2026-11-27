#!/bin/bash

set -e

read -p "Please input the new appname here: " newAppName

cmakeAppName="${newAppName// /_}"

dart run rename setAppName --targets 'windows,android,macos,ios' --value "$newAppName"

dart run rename setAppName --targets 'linux' -- value "$cmakeAppName"