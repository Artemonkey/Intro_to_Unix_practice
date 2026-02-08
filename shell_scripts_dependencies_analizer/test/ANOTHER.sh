#!/bin/sh

source ./script.sh
. noextention

MY_ULTRA="jjj"

echo "The value is: $my_unset_variable"
grep "The value is: $my_unset_variable2"

cd /
echo $MY_ULTRA

history | grep history
