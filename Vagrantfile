# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://portal.cloud.hashicorp.com/vagrant/discover
  #config.vm.box = "base"
# CUSTOM: use a Swift-compatible box
# (Swift version compatibility can be determined at https://swift.org/download/ -> "Older Releases")
  #config.vm.box = "ubuntu/trusty64"      # ubuntu 14.04 LTS (Swift 2.2 - 5.1.5)
  #config.vm.box = "ubuntu/wily64"        # ubuntu 15.10 (Swift 2.2 - 3.0.1)
  #config.vm.box = "ubuntu/xenial64"      # ubuntu 16.04 LTS (Swift 3.0.1 - 5.5.3)
  #config.vm.box = "ubuntu/yakkety64"     # ubuntu 16.10 (Swift 3.1 - 4.1.3)
  #config.vm.box = "ubuntu/bionic64"      # ubuntu 18.04 LTS (Swift 4.2 - 5.7)
  #config.vm.box = "ubuntu/focal64"       # ubuntu 20.04 LTS (Swift 5.2.4 - current)
  config.vm.box = "ubuntu/jammy64"       # ubuntu 22.04 LTS (Swift 5.7 - current)
# (per https://askubuntu.com/a/1521304, Ubuntu no longer produces official Vagrant boxes;
# currently, bento and alvistack appear to be the most popular providers of ubuntu 24.04+ boxes)
  #config.vm.box = "bento/ubuntu-24.04"   # ubuntu 24.04 LTS (Swift 6.0 - current) (see also "alvistack/ubuntu-24.04")

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080
# CUSTOM: forward additional ports (host/parent machine -> guest/VM)
  #config.vm.network "forwarded_port", host: 8080, guest: 80      #default apache/httpd port
  #config.vm.network "forwarded_port", host: 3000, guest: 3000    #default node/express port
  #config.vm.network "forwarded_port", host: 5432, guest: 5432    #default postgres port
  #config.vm.network "forwarded_port", host: 6379, guest: 6379    #default redis port
  #config.vm.network "forwarded_port", host: 27017, guest: 27017  #default mongod port
  #config.vm.network "forwarded_port", host: 3306, guest: 3306    #default mysql port

  #config.vm.network "forwarded_port", host: 3001, guest: 3001    #misc. dev port
  #config.vm.network "forwarded_port", host: 8000, guest: 8000    #misc. dev port
  #config.vm.network "forwarded_port", host: 8099, guest: 8099    #misc. dev port

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"
# CUSTOM: we may need to explicitly specify the current directory in our case
# (see https://stackoverflow.com/questions/29731003/synced-folder-in-vagrant-is-not-syncing-in-realtime )
  #config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: ""

  # Disable the default share of the current code directory. Doing this
  # provides improved isolation between the vagrant box and your host
  # by making sure your Vagrantfile isn't accessible to the vagrant box.
  # If you use this you may want to enable additional shared subfolders as
  # shown above.
  # config.vm.synced_folder ".", "/vagrant", disabled: true

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.
# CUSTOM: functionality tweaks for VirtualBox
  config.vm.provider "virtualbox" do |v|
    # increase memory (with default "1024", `npm install` can run out of memory and report `Killed`: https://github.com/npm/npm/issues/6428)
    v.memory = "2048"
  end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
# CUSTOM: use our own shell provisioning script for additional environment setup
  config.vm.provision "shell", path: "Vagrantboot.sh"
end
