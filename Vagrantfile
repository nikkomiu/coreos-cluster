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
abort("Kubernetes controller config not found!") unless File.exists?(CONTROLLER_CONFIG_PATH)
abort("Kubernetes worker config not found!") unless File.exists?(WORKER_CONFIG_PATH)

# --- DEFAULT CONFIG PARAMETERS ---
$vm_gui = false

$etcd_memory = 512
$etcd_cpus = 1
$controller_memory = 1536
$controller_cpus = 1
$worker_memory = 1024
$worker_cpus = 1

$num_etcd = 2
$num_controller = 1
$num_worker = 4

$new_discovery = "https://discovery.etcd.io/new?size=#{$num_etcd}"
$token = nil

$core_channel = "alpha"
$core_version = "current"
# --- DEFAULT CONFIG PARAMETERS ---

# Optionally include config overrides
require CONFIG if File.exists?(CONFIG)

def get_token
  # Generate new token if needed
  if $token == nil
    require 'open-uri'

    $token = open($new_discovery).read
  end

  $token
end

def update_user_data yaml_file
  return unless ARGV[0].eql? 'up'

  abort("File '#{yaml_file}' not found!") unless File.exists? yaml_file

  require 'yaml'

  data = YAML.load_file(yaml_file)

  if data.key?('coreos') && data['coreos'].key?('etcd')
    data['coreos']['etcd']['discovery'] = get_token
  end

  if data.key?('coreos') && data['coreos'].key?('etcd2')
    data['coreos']['etcd2']['discovery'] = get_token
  end

  contents = YAML.dump data
  File.open(yaml_file, 'w') { |file| file.write("#cloud-config\n\n#{contents}") }
end

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

  # Update the user data for all vm types
  update_user_data ETCD_CONFIG_PATH
  update_user_data CONTROLLER_CONFIG_PATH
  update_user_data WORKER_CONFIG_PATH

  # Setup etcd instances
  (1..$num_etcd).each do |i|
    config.vm.define vm_name = "etcd-#{i}" do |config|
      config.vm.hostname = vm_name

      config.vm.provider :virtualbox do |vbox|
        vbox.gui = $vm_gui
        vbox.memory = $etcd_memory
        vbox.cpus = $etcd_cpus
      end

      ip = "172.17.8.#{i+100}"
      config.vm.network :private_network, ip: ip

      config.vm.provision :file, :source => "#{ETCD_CONFIG_PATH}", :destination => "/tmp/vagrantfile-user-data"
      config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
    end
  end

  # Setup controller instances
  (1..$num_controller).each do |i|
    config.vm.define vm_name = "controller-#{i}" do |config|
      config.vm.hostname = vm_name

      config.vm.provider :virtualbox do |vbox|
        vbox.gui = $vm_gui
        vbox.memory = $controller_memory
        vbox.cpus = $controller_cpus
      end

      ip = "172.17.8.#{i+150}"
      config.vm.network :private_network, ip: ip
      config.vm.network :forwarded_port, guest: 443, host: 443

      config.vm.provision :file, :source => "#{CONTROLLER_CONFIG_PATH}", :destination => "/tmp/vagrantfile-user-data"
      config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
    end
  end

  # Setup worker instances
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
