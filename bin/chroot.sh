#!/bin/bash

where=$1
binry=${2:-/bin/bash}

set -e

m_dev=0
m_proc=0
m_sys=0

function do_mount()
{
  mount -o bind /dev/ $where/dev && m_dev=1
  mount -t proc none $where/proc && m_proc=1
  mount -t sysfs none $where/sys && m_sys=1
}

function do_umount()
{
  errcode=$?
  [ -n $m_sys ] && umount $where/sys
  [ -n $m_proc ] && umount $where/proc
  [ -n $m_dev ] && umount $where/dev
  exit $errcode
}

trap do_umount EXIT
do_mount

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
  LANG=C LC_ALL= \
  DEBIAN_FRONTEND=noninteractive \
  DEBCONF_NONINTERACTIVE_SEEN=true \
  chroot $where $binry
