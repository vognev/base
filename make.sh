#!/usr/bin/env bash

# stop on any error happened
set -e

TAG=${TAG:-latest}

if [ "$#" == "0" ]; then
  echo "Usage: $0 <tar> <image> <test> <run> <push>"
  exit 1
fi

# base packages to be installed
base="apt base-passwd bash ca-certificates coreutils debconf findutils grep gzip libc-bin login passwd sed"

# build directory
build=$(dirname $(readlink -m $0))

# chroot directory
root=$build/root

# now operating relative to build.sh
cd $build

# using basic apt configuration
APT_CONFIG="etc/apt/apt.conf"

# shorthand for apt-get with our layout
function aptget() {
  APT_CONFIG=$APT_CONFIG apt-get -o Dir=$root \
    -o Dir="$root" \
    -o Dir::State::status="$root/var/lib/dpkg/status" \
    $@
}

while test $# -gt 0; do
case "$1" in
  "tar" )
    # cleanup
    mkdir -p $root; rm -rf $root/*

    # make skel
    mkdir -p $root/etc/apt/apt.conf.d/
    mkdir -p $root/etc/apt/preferences.d/
    mkdir -p $root/etc/apt/sources.list.d/
    mkdir -p $root/etc/apt/trusted.gpg.d/
    mkdir -p $root/var/cache/apt/archives/partial
    mkdir -p $root/var/lib/dpkg
    touch $root/var/lib/dpkg/status

    cp etc/apt/sources.list etc/apt/apt.conf $root/etc/apt/

    # fetch fresh packages database
    aptget update

    # get uris of debs and cache them
    aptget --print-uris --yes install $base | cut -d\' -f2 | grep http:// > list.txt
    wget -P $root/var/cache/apt/archives -i list.txt && rm list.txt

    # unpack debs to $root
    for pkg in $root/var/cache/apt/archives/*.deb; do 
        echo `basename "$pkg"`
        dpkg-deb --fsys-tarfile "$pkg" | tar -C $root -xpf -
    done

    # settle postinstall script
    cp bin/postinst.sh $root/ && chmod +x $root/postinst.sh

    ./bin/chroot.sh $root /postinst.sh

    cd root; tar czf ../root.tar.gz .
    ;;
  "image" )
    docker rmi vognev/base || true
    docker build --build-arg http_proxy=$http_proxy -f Dockerfile.base -t vognev/base:$TAG .
    ;;
  "run" )
    docker run -it --rm --entrypoint /bin/bash vognev/base:$TAG
    ;;
  "push" )
    docker push vognev/base:$TAG
    ;;
  "test" )
    # todo
    ;;
esac

shift
done
