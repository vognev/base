#!/bin/bash

set -e

find /usr/share/doc/ -type f -delete
find /usr/share/man/ -type f -delete
find /usr/share/info/ -type f -delete
find /usr/share/locale/ -type f -delete

mkdir -p /etc/dpkg/dpkg.cfg.d
echo "log /dev/null" > /etc/dpkg/dpkg.cfg.d/lognull
echo "path-exclude=/usr/share/doc/*
path-exclude=/usr/share/man/*
path-exclude=/usr/share/info/*
path-exclude=/usr/share/locale/*
path-exclude=/etc/cron.*
path-include=/usr/share/locale/{en,en_US}/*
" > /etc/dpkg/dpkg.cfg.d/pathexclude

mkdir -p /etc/apt/apt.conf.d
echo 'DPkg::Post-Invoke  { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };
APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };
Dir::Cache::pkgcache ""; 
Dir::Cache::srcpkgcache "";
' > /etc/apt/apt.conf.d/nocache

echo "* Initscripts stuff"

cat > /usr/sbin/policy-rc.d <<EOF
#!/bin/sh
# For most Docker users, "apt-get install" only happens during "docker build",
# where starting services doesn't work and often fails in humorous ways. This
# prevents those failures by stopping the services from attempting to start.
exit 101
EOF
chmod +x /usr/sbin/policy-rc.d

dpkg-divert --local --rename --add /sbin/initctl
cp -a /usr/sbin/policy-rc.d /sbin/initctl
sed -i 's/^exit.*/exit 0/' /sbin/initctl

ln -s /bin/true /sbin/runlevel

echo "* Reinstalling packages"
dpkg -i --force-depends /var/cache/apt/archives/base-passwd_*.deb && rm /var/cache/apt/archives/base-passwd_*.deb
dpkg -i --force-depends /var/cache/apt/archives/mawk_*.deb        && rm /var/cache/apt/archives/mawk_*.deb
dpkg -i --force-depends /var/cache/apt/archives/base-files_*.deb  && rm /var/cache/apt/archives/base-files_*.deb
dpkg -R -i --force-depends /var/cache/apt/archives/

echo "* Adding debian user"
useradd -u 1000 -m debian || echo "Fail: $?"

echo "* Cleanup"
find /var/cache/apt -type f -delete
find /var/lib/apt/lists -type f -delete
find /var/log -type f -delete
rm -- "$0"

echo "* Stats"
du -h --max-depth=1 --one-file-system  /