#!/bin/bash

set -e
source /vagrant/provisioning/ovn-common-functions
## set -x

# Script Arguments:
# $1 - INSTALL_WIRESHARK
# $2 - WIRESHARK_USER to be added to wireshark grp

INSTALL_WIRESHARK=$(translate_yes ${1-yes})
WIRESHARK_USER=${2-vagrant}

if test X"$INSTALL_WIRESHARK" = Xyes ; then
    # grab latest -- yet stable -- version of wireshark from dev
    sudo add-apt-repository -y ppa:wireshark-dev/stable

    sudo apt-get update
    sudo apt-get install -y xbase-clients wireshark || true
    sudo usermod -a -G wireshark ${WIRESHARK_USER}
else
    echo >&2 "not installing wireshark in $(hostname --short)"
fi
