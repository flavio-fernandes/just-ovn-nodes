#!/bin/bash

set -e
source /vagrant/provisioning/ovn-common-functions
## set -x

# Script Arguments:
# $1 - OVN_REPO
# $2 - OVN_BRANCH
# $3 - NUM_CPUS
# $4 - INSTALL_OVN_HOST
# $5 - INSTALL_OVN_CENTRAL
# $6 - OVN_PKG_DIR
# $7 - OVN_FORCE_BUILD

OVN_REPO=$1
OVN_BRANCH=$2
NUM_CPUS=$3
INSTALL_OVN_HOST=$(translate_yes ${4-yes})
INSTALL_OVN_CENTRAL=$(translate_yes ${5-no})
OVN_PKG_DIR=${6-/vagrant/provisioning/pkgs}
OVN_FORCE_BUILD=$(translate_yes ${7-no})

NUM_CPUS=${NUM_CPUS:-1}

# Start off by checking if the linux packages that we need in order to
# install OVS ans OVN are available. It is no big deal if we need to
# have them built, but the time saving potential is always attractive. :)
stat -t ${OVN_PKG_DIR}/*.deb > /dev/null 2>&1 || OVN_FORCE_BUILD='yes'

if test X"$OVN_FORCE_BUILD" = Xyes ; then
    OVN_DEP_PKGS="build-essential fakeroot git graphviz autoconf automake bzip2 \
                  debhelper dh-autoreconf libssl-dev libtool openssl procps \
                  python-all python-qt4 python-twisted-conch python-zopeinterface python-six \
                  libunbound-dev"

    sudo apt-get install -qy $OVN_DEP_PKGS

    if [[ ! -d "ovs" ]]; then
        git clone -b $OVN_BRANCH $OVN_REPO ovs
    fi

    (cd ovs && \
     dpkg-checkbuilddeps && \
     DEB_BUILD_OPTIONS="parallel=${NUM_CPUS} nocheck" fakeroot debian/rules binary) || \
    { echo >&2 "ovn build was bad"; exit 1; }

    # Build kernel modules using module-assistant
    sudo apt-get install -qy module-assistant
    (sudo dpkg -i openvswitch-datapath-source_2*_all.deb && \
     sudo m-a --text-mode prepare && \
     sudo m-a --text-mode build openvswitch-datapath) ||
    { echo >&2 "Unable to build kernel modules"; exit 1; }
    cp -v /usr/src/openvswitch-datapath-module-*.deb .

    rm -rf ${OVN_PKG_DIR}/*.deb
    cp -v ./*.deb $OVN_PKG_DIR
else
    echo "Note: ovn packages already built, not redoing it"
fi

install_ovs_pkgs $OVN_PKG_DIR $INSTALL_OVN_HOST $INSTALL_OVN_CENTRAL

# stop services that may have been started by install dpkg
stop_ovx_services_and_purge_state

# do not start services automatically
disable_ovs_pkgs
