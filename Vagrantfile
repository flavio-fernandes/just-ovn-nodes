# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require 'ipaddr'

vagrant_config = YAML.load_file("provisioning/virtualbox.conf.yml")

Vagrant.configure(2) do |config|
  config.vm.box = vagrant_config['box']
  config.vm.box_check_update = false

  # ssh tinkering...
  # ref: http://stackoverflow.com/questions/14715678/vagrant-insecure-by-default
  # ref: https://www.vagrantup.com/docs/vagrantfile/ssh_settings.html
  config.ssh.insert_key = false
  ##config.ssh.paranoid = false
  ##config.ssh.keys_only = false
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'" # avoids 'stdin: is not a tty' error.
  config.vm.provision "shell", inline: <<-SCRIPT
    printf "%s\n" "#{File.read("#{ENV['HOME']}/.ssh/id_rsa.pub")}" >> /home/vagrant/.ssh/authorized_keys
    printf "%s\n" "#{File.read("./provisioning/id_rsa.pub")}" >> /home/vagrant/.ssh/authorized_keys
    printf "%s\n" "#{File.read("./provisioning/id_rsa.pub")}" >> /home/vagrant/.ssh/id_rsa.pub
    printf "%s\n" "#{File.read("./provisioning/id_rsa")}" >> /home/vagrant/.ssh/id_rsa
    chown -R vagrant:vagrant /home/vagrant/.ssh
    chmod 600 /home/vagrant/.ssh/id_rsa
  SCRIPT

  num_compute_nodes = (ENV['NUM_COMPUTE_NODES'] || 3).to_i

  if Vagrant.has_plugin?("vagrant-cachier")
    # Configure cached packages to be shared between instances of the same base box.
    # More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
    config.cache.scope = :box
  end

  # update kernel and reload. This is needed so the geneve and vport_geneve modules
  # become available, while using a stock trusty distro
  config.vm.provision "shell", inline: <<-SCRIPT
    apt-get update && sudo apt-get install -y linux-generic-lts-xenial
  SCRIPT
  config.vm.provision :reload

  # Use the ipaddr library to calculate the netmask of a given network
  net = IPAddr.new vagrant_config['provider_network']
  netmask = net.inspect().split("/")[1].split(">")[0]

  # Build the common args for the setup-base.sh scripts.
  setup_base_common_args = "#{vagrant_config['ovncentral']['ip']} #{vagrant_config['ovncentral']['short_name']} " +
                           "#{vagrant_config['ovncompute1']['ip']} #{vagrant_config['ovncompute1']['short_name']} " +
                           "#{vagrant_config['ovncompute2']['ip']} #{vagrant_config['ovncompute2']['short_name']} " +
                           "#{vagrant_config['ovncompute3']['ip']} #{vagrant_config['ovncompute3']['short_name']} "

  # Bring up the Mock-Devstack ovsdb/ovn-northd node on Virtualbox
  config.vm.define "central", primary: true, autostart: vagrant_config['ovncentral']['autostart'] do |ovncentral|

    ovncentral.vm.hostname = vagrant_config['ovncentral']['host_name']
    ovncentral.vm.network "private_network", ip: vagrant_config['ovncentral']['ip']
    ovncentral.vm.network "private_network", ip: vagrant_config['ovncentral']['prov-ip'], netmask: netmask, virtualbox__intnet: "providernet"
    ovncentral.vm.provision "shell", path: "provisioning/setup-base.sh", privileged: false,
      :args => "#{vagrant_config['ovncentral']['mtu']} #{setup_base_common_args}"
    ovncentral.vm.provision "shell", path: "provisioning/setup-ovn-package.sh", privileged: false,
      :args => "#{vagrant_config['ovn_repo']} #{vagrant_config['ovn_branch']} #{vagrant_config['ovncentral']['cpus']} #{vagrant_config['ovncentral']['install_ovn_controller']} yes #{vagrant_config['ovn_pkg_dir']} no"
    config.vm.provider "virtualbox" do |vb|
       vb.memory = vagrant_config['ovncentral']['memory']
       vb.cpus = vagrant_config['ovncentral']['cpus']
       vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
       vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
       vb.customize ["modifyvm", :id, "--nictype3", "virtio"]
       vb.customize ['modifyvm', :id, "--nicpromisc3", "allow-all"]
       vb.customize [
           "guestproperty", "set", :id,
           "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000
          ]
    end
  end

  num_compute_nodes.times do |n|
    compute_id = "ovncompute#{n+1}"
    # Bring up the Mock-Devstack compute node on Virtualbox
    config.vm.define "compute#{n+1}", autostart: vagrant_config[compute_id]['autostart'] do |ovncompute|

      ovncompute.vm.hostname = vagrant_config[compute_id]['host_name']
      ovncompute.vm.network "private_network", ip: vagrant_config[compute_id]['ip']
      ovncompute.vm.network "private_network", ip: vagrant_config[compute_id]['prov-ip'], netmask: netmask, virtualbox__intnet: "providernet"
      ovncompute.vm.provision "shell", path: "provisioning/setup-base.sh", privileged: false,
      :args => "#{vagrant_config[compute_id]['mtu']} #{setup_base_common_args}"
      ovncompute.vm.provision "shell", path: "provisioning/setup-ovn-package.sh", privileged: false,
      :args => "#{vagrant_config['ovn_repo']} #{vagrant_config['ovn_branch']} #{vagrant_config[compute_id]['cpus']} yes no #{vagrant_config['ovn_pkg_dir']} no"
      ovncompute.vm.provision "shell", path: "provisioning/setup-nvfapp.sh", privileged: false
      ovncompute.vm.provision "shell", path: "provisioning/setup-extras.sh", privileged: false
      config.vm.provider "virtualbox" do |vb|
        vb.memory = vagrant_config[compute_id]['memory']
        vb.cpus = vagrant_config[compute_id]['cpus']
        vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
        vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
        vb.customize ["modifyvm", :id, "--nictype3", "virtio"]
        vb.customize ['modifyvm', :id, "--nicpromisc3", "allow-all"]
        vb.customize [
                      "guestproperty", "set", :id,
                      "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000
                     ]
      end
    end
  end
end
