#!/bin/sh

. ./.settings

# create dir for docs
mkdir -p docs

cd nginx || exit 1

if [ ! -f ../docs/CHANGES ]; then
  # make changes
  make -f docs/GNUmakefile changes
  mv -f tmp/*/CHANGES* ../docs/
fi

# copy docs and licenses
cp -f docs/text/LICENSE ../docs/
cp -f docs/text/README ../docs/
cp -pf ../$OPENSSL/LICENSE ../docs/OpenSSL.LICENSE
cp -pf ../$WITH_PCRE/LICENCE ../docs/PCRE.LICENCE
# fix ZLIB license
sed -ne '/^ (C) 1995-20/,/^  jloup@gzip\.org/p' ../$ZLIB/README > ../docs/zlib.LICENSE
touch -r../$ZLIB/README ../docs/zlib.LICENSE

# configure
configure_args="--sbin-path=nginx.exe
    --http-client-body-temp-path=temp/client_body
    --http-proxy-temp-path=temp/proxy
    --http-fastcgi-temp-path=temp/fastcgi
    --http-scgi-temp-path=temp/scgi
    --http-uwsgi-temp-path=temp/uwsgi
    --with-http_realip_module
    --with-http_addition_module
    --with-http_sub_module
    --with-http_dav_module
    --with-http_stub_status_module
    --with-http_flv_module
    --with-http_mp4_module
    --with-http_gunzip_module
    --with-http_gzip_static_module
    --with-http_auth_request_module
    --with-http_random_index_module
    --with-http_secure_link_module
    --with-http_slice_module
    --with-mail
    --with-stream
    --crossbuild=win32
    --with-pcre=../$WITH_PCRE
    --with-pcre-jit
    --with-zlib=../$ZLIB
    --with-ld-opt='-Wl,--gc-sections,--build-id=none'
    --prefix= "

# setup $CC and $machine
CC=x86_64-w64-mingw32-gcc
WINDRES=x86_64-w64-mingw32-windres
machine=$($CC -dumpmachine | cut -d- -f1)

echo "==== $machine ===="

# get version
version=$(cat src/core/nginx.h | grep NGINX_VERSION | grep -ioP '((\d+\.)+\d+)')

if [ ! -f ../nginx-slim-$version-$machine-static.exe ]; then
# no-ssl build
auto/configure $configure_args \
    --with-cc=$CC \
    --with-windres=$WINDRES \
    --with-cc-opt='-DFD_SETSIZE=1024 -s -O2 -fno-strict-aliasing -pipe'

echo auto/configure $configure_args \
    --with-cc=$CC \
    --with-cc-opt="'-DFD_SETSIZE=1024 -s -O2 -fno-strict-aliasing -pipe'" > .config-slim-static
# build
ZLIB_CONF_OPT="PREFIX=x86_64-w64-mingw32-" \
PCRE_CONF_OPT="--target=x86_64-w64-mingw32 --host=x86_64-w64-mingw32" make -j$(nproc)
strip -s objs/nginx.exe
mv -f objs/nginx.exe ../nginx-slim-$version-$machine-static.exe

fi

if [ ! -f ../nginx-slim-$version-$machine.exe ]; then
# no-ssl dynamic build
auto/configure $configure_args \
    --shared-zlib \
    --shared-pcre \
    --shared-pcre2 \
    --with-cc=$CC \
    --with-windres=$WINDRES \
    --with-cc-opt='-DFD_SETSIZE=1024 -s -O2 -fno-strict-aliasing -pipe'

echo auto/configure $configure_args \
    --with-cc=$CC \
    --with-windres=$WINDRES \
    --with-cc-opt="'-DFD_SETSIZE=1024 -s -O2 -fno-strict-aliasing -pipe'" > .config-slim
# re-build
ZLIB_CONF_OPT="PREFIX=x86_64-w64-mingw32-" \
PCRE_CONF_OPT="--target=x86_64-w64-mingw32 --host=x86_64-w64-mingw32" make -j$(nproc)
strip -s objs/nginx.exe
mv -f objs/nginx.exe ../nginx-slim-$version-$machine.exe

# copy shared libs
ls ../$PCRE/.libs/*.dll > /dev/null && cp -a ../$PCRE/.libs/lib*.dll ..
ls ../$PCRE2/.libs/*.dll > /dev/null && cp -a ../$PCRE2/.libs/lib*.dll ..
ls ../$ZLIB/*.dll > /dev/null && cp -a ../$ZLIB/zlib*.dll ..

fi

# re-configure with ssl
configure_args="$configure_args \
    --with-http_v2_module
    --with-openssl=../$OPENSSL
    --with-http_ssl_module
    --with-mail_ssl_module
    --with-stream_ssl_module "

if [ ! -f ../nginx-$version-$machine-static.exe ]; then

auto/configure $configure_args \
    --with-cc=$CC \
    --with-windres=$WINDRES \
    --with-cc-opt='-DFD_SETSIZE=1024 -s -O2 -fno-strict-aliasing -pipe' \
    --with-openssl-opt='no-tests -D_WIN32_WINNT=0x0501'

echo auto/configure $configure_args \
    --with-cc=$CC \
    --with-windres=$WINDRES \
    --with-openssl-opt="'no-tests -D_WIN32_WINNT=0x0501'" \
    --with-cc-opt="'-DFD_SETSIZE=1024 -s -O2 -fno-strict-aliasing -pipe'" > .config-static

# re-build
ZLIB_CONF_OPT="PREFIX=x86_64-w64-mingw32-" \
PCRE_CONF_OPT="--target=x86_64-w64-mingw32 --host=x86_64-w64-mingw32" \
OPENSSL_CONF_OPT="mingw64 --cross-compile-prefix=x86_64-w64-mingw32-" make -j$(nproc)

strip -s objs/nginx.exe
mv -f objs/nginx.exe ../nginx-$version-$machine-static.exe

fi

if [ ! -f ../nginx-$version-$machine-static-debug.exe ]; then
# re-configure with debugging log
auto/configure $configure_args \
    --with-debug \
    --with-cc=$CC \
    --with-windres=$WINDRES \
    --with-cc-opt='-DFD_SETSIZE=1024 -O2 -fno-strict-aliasing -pipe' \
    --with-openssl-opt='no-tests -D_WIN32_WINNT=0x0501'

echo auto/configure $configure_args \
    --with-debug \
    --with-cc=$CC \
    --with-windres=$WINDRES \
    --with-openssl-opt="'no-tests -D_WIN32_WINNT=0x0501'" \
    --with-cc-opt="'-DFD_SETSIZE=1024 -s -O2 -fno-strict-aliasing -pipe'" > .config-static-debug

# re-build with debugging log
ZLIB_CONF_OPT="PREFIX=x86_64-w64-mingw32-" \
PCRE_CONF_OPT="--target=x86_64-w64-mingw32 --host=x86_64-w64-mingw32" \
OPENSSL_CONF_OPT="mingw64 --cross-compile-prefix=x86_64-w64-mingw32-" make -j$(nproc)
mv -f objs/nginx.exe ../nginx-$version-$machine-static-debug.exe

fi

if [ ! -f ../nginx-$version-$machine.exe ]; then
# re-configure with shared libs
auto/configure $configure_args \
    --shared-zlib \
    --shared-pcre \
    --shared-pcre2 \
    --shared-openssl \
    --with-cc=$CC \
    --with-windres=$WINDRES \
    --with-cc-opt='-DFD_SETSIZE=1024 -s -O2 -fno-strict-aliasing -pipe' \
    --with-openssl-opt='no-tests -D_WIN32_WINNT=0x0501'

echo auto/configure $configure_args \
    --shared-zlib \
    --shared-pcre \
    --shared-pcre2 \
    --shared-openssl \
    --with-cc=$CC \
    --with-windres=$WINDRES \
    --with-cc-opt="'-DFD_SETSIZE=1024 -s -O2 -fno-strict-aliasing -pipe'" \
    --with-openssl-opt="'no-tests -D_WIN32_WINNT=0x0501'" > .config

# re-build
ZLIB_CONF_OPT="PREFIX=x86_64-w64-mingw32-" \
PCRE_CONF_OPT="--target=x86_64-w64-mingw32 --host=x86_64-w64-mingw32" \
OPENSSL_CONF_OPT="mingw64 --cross-compile-prefix=x86_64-w64-mingw32-" make -j$(nproc)

strip -s objs/nginx.exe
mv -f objs/nginx.exe ../nginx-$version-$machine.exe

# copy shared libs
ls ../$PCRE/.libs/*.dll > /dev/null && cp -a ../$PCRE/.libs/lib*.dll ..
ls ../$PCRE2/.libs/*.dll > /dev/null && cp -a ../$PCRE2/.libs/lib*.dll ..
ls ../$OPENSSL/*.dll > /dev/null && cp -a ../$OPENSSL/lib*.dll ..
ls ../$ZLIB/*.dll > /dev/null && cp -a ../$ZLIB/zlib*.dll ..

fi

exit 0
