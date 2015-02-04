#!/opt/vagrant/embedded/bin/ruby

require 'YAML'

SPEC_FILE=ENV['STEVEDORE_FILE'] || File.expand_path(File.dirname(__FILE__) + '/..') + '/stevedore.yaml'

SPEC=YAML::load(File.open(SPEC_FILE))

swarm_hosts= []

SPEC['vms'].each do |vm|
  vm['roles'].each do |role|
    swarm_hosts << vm['name'] if role == 'swarm'
  end
end

puts swarm_hosts.map{|x| x + '.docker.vm:2375'}.join(',')
