# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  #config.vm.box = "ubuntu/trusty64"      # ubuntu 14.04 LTS
  #config.vm.box = "ubuntu/wily64"        # ubuntu 15.10 (deprecated: https://wiki.ubuntu.com/Releases)
  config.vm.box = "ubuntu/xenial64"      # ubuntu 16.04 LTS
  #config.vm.box = "ubuntu/yakkety64"     # ubuntu 16.10 (deprecated: https://wiki.ubuntu.com/Releases)
  #config.vm.box = "ubuntu/zesty64"       # ubuntu 17.04 (not yet officially supported for Swift)
  #config.vm.box = "ubuntu/artful64"      # ubuntu 17.10 (not yet officially supported for Swift)
  #config.vm.box = "ubuntu/bionic64"      # ubuntu 18.04 LTS prerelease (not yet officially supported for Swift)

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
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

  #config.vm.network "public_network"

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
  # NOTE: we need to explicitly specify the current directory in our case
  # (see https://stackoverflow.com/questions/29731003/synced-folder-in-vagrant-is-not-syncing-in-realtime )
  #config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: ""

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
# CUSTOM:
  config.vm.provider "virtualbox" do |v|
    # allow symlinks (needed for some npm packages, ie. bower dependencies)
    #v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant", "1"]
    # increase memory (with default "1024", `npm install` can run out of memory and report `Killed`: https://github.com/npm/npm/issues/6428)
    v.memory = "2048"
    # suppress creation of the "ubuntu-xenial-16.04-cloudimg-console.log" file
    # (see: https://groups.google.com/forum/#!topic/vagrant-up/eZljy-bddoI)
    v.customize ["modifyvm", :id, "--uartmode1", "disconnected"]
  end

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline <<-SHELL
  #   sudo apt-get install apache2
  # SHELL
  config.vm.provision :shell, path: "Vagrantboot.sh"
end
