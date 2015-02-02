# -*- mode: ruby -*-
# vi: set ft=ruby :



SPEC_FILE=ENV['STEVEDORE_FILE'] || File.expand_path(File.dirname(__FILE__)) + '/stevedore.yaml'

SPEC=YAML::load(File.open(SPEC_FILE))

$ip_range = IPAddr.new(SPEC['vm_defaults']['ip_range']).to_range.to_enum
$domain = SPEC['vm_defaults']['domain']
$build_host = ''

def get_ip
  ip = $ip_range.next
  if ip.to_s.end_with?('.0') || ip.to_s.end_with?('.255')
    $ip_range.next
  else
    ip
  end
end

# Grab any ENV
SPEC['roles'].each do |role, provisioners|
  provisioners.each do |provisioner|
    if provisioner['args']
      provisioner['args'].each do |k,v|
        provisioner['args'][k] = eval(v) if v.start_with? 'ENV'
      end
    end
  end
end

Vagrant.configure("2") do |config|

  config.landrush.enabled = true
  config.landrush.tld = $domain

  SPEC['vms'].each do |vm|

    labels=''

    $build_host = vm['name'] if $build_host == ''

    if vm['labels']
      labels = vm['labels'].map{|k,v| "#{k}=#{v}"}.join(' ')
    end

    ip = get_ip.to_s

    config.vm.define vm['name'] do |node_config|

      node_config.vm.box = SPEC['boxes'][vm['box']]

      node_config.vm.host_name = vm['name'] + '.' + $domain
      node_config.vm.network "private_network", ip: ip

      # This is a work around because landrush IP auto detection picks the
      # last defined interface. When docker is already installed in the base
      # box the docker bridge gets picked up.
      config.landrush.host_ip_address = ip

      node_config.vm.provider "virtualbox" do |vb|
        vb.customize [
          'modifyvm', :id,
          '--name', vm['name'],
          '--memory', vm['memory'].to_s,
          '--cpus', vm['cpus'].to_s
        ]
      end

      vm['roles'].each do |role|
        SPEC['roles'][role].each do |provisioner|

          args = "BUILD_HOST=" + $build_host

          if provisioner['args']
            args << ' ' + provisioner['args'].map{|k,v| "#{k}=#{v}"}.join(' ')
          end

          args << ' ' + labels if role == 'docker'

          node_config.vm.provision provisioner['type'],
            path: provisioner['script'],
            args: args
        end
      end
    end
  end
end
