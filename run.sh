#!/bin/bash

# Choose running machine name
unameOut="$(uname -s)"
case "$(uname -s)" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

# Mount repository path
if [ $machine == "Linux" ]
then
	docker run --rm -it -v $(pwd):/app-dir/local -w /app-dir/local contacts-fixer sh
else
	windows_path=$(pwd | sed 's/^\///' | sed 's/\//\\/g' | sed 's/^./\0:/')
	docker run --rm -it -v $windows_path:/app-dir/local contacts-fixer sh
fi
