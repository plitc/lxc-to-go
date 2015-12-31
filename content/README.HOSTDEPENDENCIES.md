# LXC-to-GO [![Build Status](https://travis-ci.org/plitc/lxc-to-go.svg?branch=master)](https://travis-ci.org/plitc/lxc-to-go)

HOST (Package) Dependencies
===========================
* Debian 7 Wheezy HOST

```
   [WHEEZY]: debootstrap libcap2-bin libpam-cap
   [WHEEZY-BACKPORTS]: initramfs-tools
   [WHEEZY-BACKPORTS]: firmware-linux-free irqbalance libcap-ng0 libglib2.0-0 libglib2.0-data libnuma1 linux-compiler-gcc-4.6-x86 linux-headers-3.16.0-0.bpo.4-amd64 linux-headers-3.16.0-0.bpo.4-common linux-image-3.16.0-0.bpo.4-amd64 linux-kbuild-3.16 shared-mime-info
   [WHEEZY-BACKPORTS]: firmware-linux-nonfree
   [WHEEZY-BACKPORTS]: build-essential dpkg-dev g++ g++-4.7 libalgorithm-diff-perl libalgorithm-diff-xs-perl libalgorithm-merge-perl libdpkg-perl libfile-fcntllock-perl libstdc++6-4.7-dev libtimedate-perl module-assistant
   [JESSIE]: dh-python init-system-helpers libalgorithm-c3-perl libapparmor1 libarchive-extract-perl libcgi-fast-perl libcgi-pm-perl libclass-c3-perl libclass-c3-xs-perl libcpan-meta-perl libdata-optlist-perl libdata-section-perl libdb5.3 libfcgi-perl libffi6 liblog-message-perl liblog-message-simple-perl libmodule-build-perl libmodule-pluggable-perl libmodule-signature-perl libmpdec2 libmro-compat-perl libpackage-constants-perl libparams-util-perl libperl4-corelibs-perl libpod-latex-perl libpod-readme-perl libpython3-stdlib libpython3.4-minimal libpython3.4-stdlib libregexp-common-perl libseccomp2 libsoftware-license-perl libsub-exporter-perl libsub-install-perl libterm-ui-perl libtext-soundex-perl libtext-template-perl python3 python3-minimal python3.4 python3.4-minimal rename
   [JESSIE]: dpkg install-info libalgorithm-diff-xs-perl libc-bin libc-dev-bin libc6 libc6-dev libfile-fcntllock-perl libgssapi-krb5-2 libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 liblocale-gettext-perl libpipeline1 libselinux1 libtext-charwidth-perl libtext-iconv-perl libtirpc1 libuuid-perl lxc man-db nfs-common perl perl-base perl-modules
```

* Debian 7 Wheezy HOST (virtualbox-ose-guest)

```
   [WHEEZY/WHEEZY-BACKPORTS] libasound2 libasyncns0 libcaca0 libcurl3 libdbus-1-3 libdirectfb-1.2-9 libflac8 libgsoap4 libjpeg8 libjson-c2 libogg0 libpng12-0 libpulse0 libpython2.7 libsdl1.2debian libsndfile1 libts-0.0-0 libvncserver0 libvorbis0a libvorbisenc2 libvpx1 libx11-xcb1 libxcursor1 libxi6 libxtst6 tsconf virtualbox virtualbox-dkms
```

* Debian 8 Jessie HOST

```
   [JESSIE]: screen bridge-utils lxc
```

* Debian 9 Testing (Stretch/Sid) HOST

```
   [STRETCH]: screen bridge-utils lxc cgmanager
```

