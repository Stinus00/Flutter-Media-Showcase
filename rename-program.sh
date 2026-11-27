#!/bin/bash

set -e

read -p "Please input the new appname here: " newAppName

dart run rename setAppName --targets 'linux,windows,android,macos,ios' --value "$newAppName"