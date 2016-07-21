#!/bin/bash

set -e
#set -x

source /vagrant/scripts/helper-functions

if test $(hostname --short) != "central" ; then
    echo >&2 "Run this command from central node"
    exit 2
fi

if [ -f "$COMPUTE_NODES" ] ; then
    echo >&2 "There is already a cluster configured."
    echo >&2 "If you think that is expected, try rm $COMPUTE_NODES"
    cat $COMPUTE_NODES
    exit 1
fi

source /vagrant/provisioning/ovn-common-functions

populate_compute_nodes () {
  # a super dummy [nested] function...
  noop () {
	  :
  }

  # execute a dummy function on each of the compute nodes
  # if it all goes well, append the compute node to the list
  # of available compute nodes we got in the cluster
  touch $COMPUTE_NODES
  for x in $(awk '/\scompute/ { print $2 }' /etc/hosts) ; do
	  rpcsh -h $x -m noop && echo $x >> $COMPUTE_NODES
      if (( $? )) ; then
		  echo >&2 "Note: node unavailable: $x"
	  fi
  done

  # if ovn-controller (aka ovn-host) is installed in central,
  # add itself to list of compute nodes as well
  if [[ -x /etc/init.d/ovn-host ]] ; then
      echo $(hostname --short) >> $COMPUTE_NODES
  fi
}

cluster_start_services () {
   source /vagrant/provisioning/ovn-common-functions
   start_ovx_services
}

populate_compute_nodes

for x in $(cat $COMPUTE_NODES | grep -v central) ; do
    echo "starting ovn in $x"
	rpcsh -h $x -m cluster_start_services || \
		{ echo >&2 "Failed to start ovn in $x"; exit 2; }
done

echo "starting ovn in central"
# note central may also be an ovn-host, thus also call start_ovn_host
(start_ovn_host && start_ovn_central) || { echo >&2 "failed to start ovn_central"; exit 2; }
