#!/opt/vagrant/embedded/bin/ruby

require 'YAML'
require 'optparse'

$controller='ducp.docker.vm'
OptionParser.new do |opts|
  opts.banner = "Usage: cluster-docker.rb [options]"
  opts.on('-c', '--controller', 'Controller FDQN or IP') { |val| $controller=val }

end.parse!

SPEC_FILE=ENV['STEVEDORE_FILE'] || File.expand_path(File.dirname(__FILE__) + '/..') + '/stevedore.yaml'

SPEC=YAML::load(File.open(SPEC_FILE))

SPEC['vms'].each do |vm|
  vm['roles'].each do |role|
    if role.include? 'ducp'
      puts "Reconfiguring %s" % vm['name']
      cmd="vagrant ssh %s -c 'sudo /vagrant/scripts/cluster-docker.sh %s'" \
        % [ vm['name'], $controller ]
      system(cmd)
    end
  end
end
