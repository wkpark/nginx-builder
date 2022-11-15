#!/bin/sh

. ./.settings

mkdir -p conf
cp -a nginx/conf/* conf/
mkdir -p logs
mkdir -p temp
mkdir -p html
cp -a nginx/docs/html/* html/
mkdir -p contrib
cp -a nginx/contrib/* contrib/

version=$(cat nginx/src/core/nginx.h | grep NGINX_VERSION | grep -ioP '((\d+\.)+\d+)')

# setup $CC and $machine
CC=x86_64-w64-mingw32-gcc
machine=$($CC -dumpmachine | cut -d- -f1)

for tag in "" slim; do
    name=nginx
    [ "$tag" != "" ] && name=$name-$tag
    name=$name-$version-$machine
    for static in "" static static-debug; do
        if [ "$static" = "" ]; then
            dlls="zlib*.dll libpcre2*.dll"
            [ "$tag" != "slim" ] && dlls="$dlls libssl*.dll libcrypto*.dll"
            exe=$name.exe
            zip=$name.zip
        else
            dlls=
            exe=$name-$static.exe
            zip=$name-$static.zip
        fi
        if [ -f $exe ]; then
            cp -a $exe nginx.exe
            rm -f $zip
            zip -r $zip docs temp logs nginx.exe $dlls html contrib
        fi
    done
done


