#!/bin/sh
# from https://github.com/myfreeer/nginx-build-msys2
# original author myfreeer
#
# @author myfreeer
# @license BSD
#
# 2022/11/14 by wkpark
# * POSIX-compliant shell fix
# * mingw64 cross compile under linux
# * some cleanup

SUCCESS="printf \033[1;32m"
FAILURE="printf \033[1;31m"
WARNING="printf \033[1;33m"
MESSAGE="printf \033[1;34m"
NORMAL="printf \033[0;39m"

echo "Check utilities..."

# For debian user, you need to install libxml2-utils for xmllint.
for x in wget curl xmllint xsltproc; do
  echo -n " * check $x... "
  which $x || ($FAILURE;echo " No '$x' utility found! Please install it first";$NORMAL; exit 1)
done

NGINX_TAG=$1

# clone the nginx
if [ -d nginx ]; then
    cd nginx || exit 1
    git checkout master
    if [ "$NGINX_TAG" = "" ]; then
        git reset --hard origin || git reset --hard
        git pull
    else
        git reset --hard $NGINX_TAG || git reset --hard
    fi
    cd ..
else
    if [ "$NGINX_TAG" = "" ]; then
        git clone https://github.com/nginx/nginx.git --depth=1
    else
        git clone https://github.com/nginx/nginx.git --depth=1 --branch "${NGINX_TAG}"
        cd nginx || exit 1
        # You are in 'detached HEAD' state.
        git checkout -b master
        cd ..
    fi
fi

(cd nginx; git checkout -b patch; git am -3 ../patches/*.patch)

# dep versions
ZLIB=$(curl -s 'https://zlib.net/' | grep -ioP 'zlib-(\d+\.)+\d+' | sort -ruV | head -1)
[ "$ZLIB" = "" ] || ZLIB=zlib-1.2.13
echo "* "$ZLIB

PCRE=$(curl -s 'https://sourceforge.net/projects/pcre/rss?path=/pcre/' | grep -ioP 'pcre-(\d+\.)+\d+' |sort -ruV | head -1)
[ "$PCRE" = "" ] || PCRE=pcre-8.45
echo "* "$PCRE

PCRE2=$(curl -L -s 'https://api.github.com/repos/PhilipHazel/pcre2/releases/latest' | grep -ioP 'pcre2-(\d+\.)+\d+' |sort -ruV | head -1)
[ "$PCRE2" = "" ] || PCRE2=pcre2-10.40
echo "* "$PCRE2

OPENSSL=$(curl -s 'https://www.openssl.org/source/' | grep -ioP 'openssl-1\.(\d+\.)+[a-z\d]+' | sort -ruV | head -1)
[ "$OPENSSL" = "" ] || OPENSSL=openssl-1.1.1s
echo "* "$OPENSSL

NV=-nv

# download deps
wget -c -N $NV https://zlib.net/$ZLIB.tar.xz || \
  wget -c -N $NV http://prdownloads.sourceforge.net/libpng/$ZLIB.tar.xz
tar xf $ZLIB.tar.xz
WITH_PCRE=$PCRE
WITH_PCRE=$PCRE2
if [ "$WITH_PCRE" = "$PCRE2" ]; then
  wget -c -N $NV https://github.com/PhilipHazel/pcre2/releases/download/$PCRE2/$PCRE2.tar.bz2
  tar xf $PCRE2.tar.bz2
else
  ver=$(echo $PCRE | sed 's/pcre-//')
  wget -c -nv $NV https://download.sourceforge.net/project/pcre/pcre/$ver/$PCRE.tar.bz2
  tar xf $PCRE.tar.bz2
fi
echo " - Using "$WITH_PCRE

wget -c -N $NV https://www.openssl.org/source/$OPENSSL.tar.gz
tar xf $OPENSSL.tar.gz

# save settings
cat <<EOF > .settings
ZLIB=$ZLIB
PCRE2=$PCRE2
PCRE=$PCRE
OPENSSL=$OPENSSL
WITH_PCRE=$WITH_PCRE
EOF

exit 0
