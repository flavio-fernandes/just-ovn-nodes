### Automatic deployment using Vagrant and VirtualBox

Use this to provision a cluster of nodes with Open Virtual Network
(OVN) without a CMS (e.g. OpenStack). The intent is to provide a way of using OVS
with a [kinda] real datapath while keeping it simpler and quicker to deploy.

Incomplete list of links to projects and files used in order to put this repo together:

- https://github.com/openvswitch/ovs/blob/master/tutorial/OVN-Tutorial.md
- https://github.com/mangelajo/ovs-experiments
- https://github.com/shettyg/ovn-namespace
- https://github.com/openstack/networking-ovn/tree/master/vagrant

In a not too far future, there will be a blog page that does much better justice in explaining how to use/deploy this environment. Until then, here are the basic stepping stones.

### Pre-reqs
- Hypervisor (only tested with Virtualbox)
- git
- Vagrant
- vagrant plugin install **vagrant-reload**
- vagrant plugin install **sahara**
- vagrant plugin install **vagrant-cachier**

Vagrant plugin _vagrant-reload_ is needed, so the provisioning of the node VMS can reboot them after installing a newer kernel, so we can use Geneve encapsulation.

Vagrant plugin _sahara_ is optional, but highly recommended. With that, you can quickly bring your cluster to a clean state after running the different OVN setup scripts.

Vagrant plugin _vagrant-cachier_ is optional, but will make it quicker to provision the VMS.

### Provisioning Steps

    git clone https://github.com/flavio-fernandes/just-ovn-nodes.git
    cd just-ovn-nodes

- Optional: Edit the file **provisioning/virtualbox.conf.yml**

Adjust the parameters **ovn_repo** and **ovn_branch** to pick up the version of OVS/OVN you want. If you use the default, it will pick up a branch from a forked GitHub OVS repo that is a replica of original OVS master, but not the latest and greatest.

By default, there will be 1 ovn database node and 3 compute nodes in the setup.
However, node compute3 will not start automatically, unless you change the **autostart** parameter, or explicitly call **vagrant up compute3**.

If you want the OVN database node to also be used as a compute node, make sure
to set the **install_ovn_controller** parameter to _yes_.

Since we are not provisioning CMS, the VMS require a lot less memory. In the provisioning steps, the OVN database VM (aka central) will build packages and store them in the directory _provisioning/pkgs_. All other VMS will simply install these packages instead of having to build ovn from scratch.

    vagrant up

    # wait about 10 mins...
    # if you want, you can explicitly bring compute3 up by using
    # vagrant up compute3

    # snapshot vms using sahara
    vagrant sandbox on

At this point, you can start ovn cluster by running the script from the db vm:

    $ vagrant ssh
    vagrant@central:~$ /vagrant/scripts/setup-ovn-cluster.sh

The output will look like this: https://gist.github.com/a54e9289b0838b9391fd30d4b58d7536

Open separate terminal sessions and ssh to other VMS so you can look at what OVS has to say. Note that central will just run OVN db, unless you changed the **install_ovn_controller** parameter to _yes_.

    $ vagrant ssh compute1   ;  # or compute2

At this point, you can try out the various scripts in **/vagrant/scripts/tutorial**. You will want to run them from the _central_ node.
Here is an example of what to expect when doing the **env1** script:

    $ vagrant ssh central
    vagrant@central:~$ ls /vagrant/scripts/tutorial
    env1  env4  env4_2vlans  l3_basic  l3_nat
    vagrant@central:~$ /vagrant/scripts/tutorial/env1/setup.sh

    vagrant@central:~$ sudo ovn-nbctl show
    switch 219d372b-07ea-459b-a639-f02c22d72055 (sw0)
        port sw0-port2
            addresses: ["00:00:00:00:00:02"]
        port sw0-port1
            addresses: ["00:00:00:00:00:01"]

    vagrant@central:~$ sudo ovn-sbctl show
    Chassis "compute1"
        hostname: "compute1.ovn.dev"
        Encap geneve
            ip: "192.168.33.31"
        Port_Binding "sw0-port1"
    Chassis "compute2"
        hostname: "compute2.ovn.dev"
        Encap geneve
            ip: "192.168.33.32"
        Port_Binding "sw0-port2"

Lastly, this is how you can easily revert the cluster to a clean state,
assuming you have **sahara** and saved a snapshot after the initial provisioning.

    $ vagrant sandbox rollback

