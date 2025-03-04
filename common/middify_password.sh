#!/bin/bash
pwd=123456
# if [ $# -eq 0 ]; then
#     echo "No arguments provided."
# else
#     echo "Number of arguments: $#"
#     echo "info: $1"
#     pwd=$1
# fi

echo "root runner user password is:$pwd"

expect -c "
    spawn sudo passwd runner
    expect {
        \"password\" { send \"$pwd\r\";}
    }
    expect {
        \"password\" { send \"$pwd\r\";}
    }
expect eof"
expect -c "
    spawn sudo passwd root
    expect {
        \"password\" { send \"$pwd\r\";}
    }
    expect {
        \"password\" { send \"$pwd\r\";}
    }
expect eof"
