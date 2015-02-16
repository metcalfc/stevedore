#!/opt/vagrant/embedded/bin/ruby

require 'YAML'
require 'optparse'

$get_manager=false
$get_host=false
OptionParser.new do |opts|
  opts.banner = "Usage: get-swarm-hosts.rb [options]"

  opts.on('-m', '--manager', 'Get manager') { $get_manager=true }
  opts.on('-h', '--hosts', 'Get hosts') { $get_hosts=true }

end.parse!


SPEC_FILE=ENV['STEVEDORE_FILE'] || File.expand_path(File.dirname(__FILE__) + '/..') + '/stevedore.yaml'

SPEC=YAML::load(File.open(SPEC_FILE))

swarm_hosts= []
swarm_manager=''

SPEC['vms'].each do |vm|
  vm['roles'].each do |role|
    swarm_hosts << vm['name'] + "." + vm['domain'] if role == 'swarm'
    swarm_manager = vm['name'] + "." + vm['domain'] if role == 'swarm-manager'
  end
end

if $get_manager
  printf "%s" % swarm_manager + ':12345' if $get_manager
  if $get_hosts
    printf " "
  else
    printf "\n"
  end
end

printf "%s\n" % swarm_hosts.map{|x| x + ':2376'}.join(',') if $get_hosts
