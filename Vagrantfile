# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

def die(msg)
  puts msg
  exit 1
end

SPEC_FILE=ENV['STEVEDORE_FILE'] || File.expand_path(File.dirname(__FILE__)) + '/stevedore.yaml'
SPEC=YAML::load(File.open(SPEC_FILE))

$domain = SPEC['vm_defaults']['domain']
$build_host = {}

# Grab any ENV
SPEC['roles'].each do |role, provisioners|

  provisioners.each do |provisioner|
    if provisioner['args']
      provisioner['args'].each do |k,v|
        provisioner['args'][k] = eval(v) if v.start_with? 'ENV'
      end
    end
  end if provisioners
end

Vagrant.configure("2") do |config|

  SPEC['vms'].each do |vm|

    labels=''

    if vm['labels']
      labels = vm['labels'].map{|k,v| "#{k}=#{v}"}.join(' ')
    end

    config.vm.define vm['name'] do |node_config|

      node_config.vm.box = SPEC['boxes'][vm['box']]

      node_config.vm.host_name = vm['name'] + '.' + $domain
      node_config.vm.network "private_network", type: :dhcp

      node_config.vm.provider "virtualbox" do |vb|
        vb.customize [
          'modifyvm', :id,
          '--name', vm['name'],
          '--memory', vm['memory'].to_s,
          '--cpus', vm['cpus'].to_s,
          '--natdnshostresolver1', 'on',
          '--hostonlyadapter2', vm['vboxnet']
        ]
      end

      node_config.vm.provision "shell",
        path: "scripts/fix-hostname.sh",
        args: [ vm['name'] ]

      vm['roles'].each do |role|
        SPEC['roles'][role].each do |provisioner|

          args = ""

          if provisioner['args']
            args << ' ' + provisioner['args'].map{|k,v| "#{k}=#{v}"}.join(' ')
          end

          args << ' ' + labels if role == 'docker'

          node_config.vm.provision provisioner['type'],
            path: provisioner['script'],
            args: args

        end if SPEC['roles'][role]
      end
    end
  end
end
