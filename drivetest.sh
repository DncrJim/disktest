#!/bin/bash

#single incoming variable for drive name (sdxx)

#if there's no variable, throw error
if [ -z "$1" ]
  then
  echo "missing argument"
  echo "usage: drivetest.sh <sdxx>"
  exit 1
  fi

#if variable is greater than 4 or less than 3 chars, throw error
if [[ ${#1} > 4 || ${#1} < 3 ]]
  then
  echo "incorrect syntax"
  echo "usage: drivetest.sh <sdxx>"
  exit 1
  fi


#if variable $1 does not begin with first two chars "sd", throw error
if [[ "sd" != "${1:0:2}" ]]
  then
  echo "incorrect syntax"
  echo "usage: drivetest.sh <sdxx>"
  exit 1
  fi

#pull parameter from command line, assign to variable
SDXX=$1

#insert other misc variables
EMAIL=root



exit 0
