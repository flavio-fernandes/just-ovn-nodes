#!/bin/bash
#

#
# Ref: http://blog.spinhirne.com/2016/09/the-ovn-gateway-router.html
#

set -o xtrace


# remove the ACLs and address sets
sudo ovn-nbctl acl-del dmz
sudo ovn-nbctl acl-del inside
sudo ovn-nbctl destroy Address_Set dmz
