#!/bin/bash

# Choose running machine name
case "$(uname -s)" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:$(uname -s)"
esac

# Mount repository path
if [[ $machine == "Linux"  || $machine == "Mac" ]]
then
	docker run --rm -it -v $(pwd):/app-dir/local -w /app-dir/local contacts-fixer bash
else
	windows_path=$(cygpath -w $(pwd))
	docker run --rm -it -v $windows_path:/app-dir/local contacts-fixer bash
fi
