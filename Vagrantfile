# -*- mode: ruby -*-
# # vi: set ft=ruby :

require 'fileutils'

Vagrant.require_version ">=1.6.0"

ETCD_CONFIG_PATH = File.join(File.dirname(__FILE__), "config/user-data-etcd")
CONTROLLER_CONFIG_PATH = File.join(File.dirname(__FILE__), "config/user-data-controller")
WORKER_CONFIG_PATH = File.join(File.dirname(__FILE__), "config/user-data-worker")
CONFIG = File.join(File.dirname(__FILE__), "config/config.rb")

# The user data config files must exist
abort("CoreOS etcd config not found!") unless File.exists?(ETCD_CONFIG_PATH)
abort("Kubernetes worker config not found!") unless File.exists?(WORKER_CONFIG_PATH)

# --- DEFAULT CONFIG PARAMETERS ---
$vm_gui = false

$etcd_memory = 2048
$etcd_cpus = 1
$worker_memory = 1024
$worker_cpus = 1

$num_etcd = 1
$num_worker = 1

$new_discovery = "https://discovery.etcd.io/new?size=#{$num_etcd}"
$token = nil

$core_channel = "beta"
$core_version = "current"
# --- DEFAULT CONFIG PARAMETERS ---

# Optionally include config overrides
require CONFIG if File.exists?(CONFIG)

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false

  config.vm.box = "coreos-#{$core_channel}"
  config.vm.box_version = $core_version unless $core_version == "current"

  config.vm.box_url = "http://#{$core_channel}.release.core-os.net/amd64-usr/#{$core_version}/coreos_production_vagrant.json"

  config.vm.provider :virtualbox do |vbox|
    vbox.check_guest_additions = false
    vbox.functional_vboxsf     = false
  end

  config.vbguest.auto_update = false if Vagrant.has_plugin?("vagrant-vbguest")

  # Setup etcd instance
  (1..$num_etcd).each do |i|
    config.vm.define vm_name = "etcd-#{i}" do |config|
      config.vm.hostname = vm_name

      config.vm.provider :virtualbox do |vbox|
        vbox.gui = $vm_gui
        vbox.memory = $etcd_memory
        vbox.cpus = $etcd_cpus
      end

      ip = "172.17.8.#{i+150}"
      config.vm.network :private_network, ip: ip

      config.vm.provision :file, :source => "#{ETCD_CONFIG_PATH}", :destination => "/tmp/vagrantfile-user-data"
      config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
    end
  end

  # Setup worker instance
  (1..$num_worker).each do |i|
    config.vm.define vm_name = "worker-#{i}" do |config|
      config.vm.hostname = vm_name

      config.vm.provider :virtualbox do |vbox|
        vbox.gui = $vm_gui
        vbox.memory = $worker_memory
        vbox.cpus = $worker_cpus
      end

      ip = "172.17.8.#{i+200}"
      config.vm.network :private_network, ip: ip

      config.vm.provision :file, :source => "#{WORKER_CONFIG_PATH}", :destination => "/tmp/vagrantfile-user-data"
      config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true

      config.vm.synced_folder "shared_data/", "/opt/external/"
    end
  end
end
