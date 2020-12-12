#!/bin/bash

docker run --rm -it -v $(pwd):/app-dir/local -w /app-dir/local contacts-fixer sh
