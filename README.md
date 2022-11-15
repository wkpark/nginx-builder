NGiNX build scripts
===================

The nginx-builder is a set of shell scripts to build/compile the Nginx source code using dependency library packages with some patches.

It is based on [myfreeer's work](https://github.com/myfreeer/nginx-build-msys2) for windows+MSYS

Included patches:
 * `realpath patch`: please see [fix ngx_realpath() for win32](https://mailman.nginx.org/archives/list/nginx-devel@nginx.org/thread/DQFTWMJU3YC53AWQD56CDIDOVOBOJUP7/)
 * `shared libs patch`: support `--shared-pcre, --shared-pcre2, --shared-openssl, --shared-zlib`
 * `relative prefix patch` by myfreeer: allow prefix with relative path

## Packages
 * `nginx-*.zip`: 64bit nginx shared binary. (`libz1.dll`, `libpcre2*.dll`, `libssl*.dll`, `libcrypto*.dll` included)
 * `nginx-slim-*.zip`: 64bit nginx shared binary without ssl support. (`libz1.dll`, `libpcre2*.dll` included)
 * `nginx-*-static.zip`: 64bit nginx static binary.
 * `nginx-*-static-debug.zip`: debug enabled 64bit nginx static binary.
 * `nginx-slim-*-static.zip`: 64bit nginx binary without ssl support.
