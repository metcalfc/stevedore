#!/opt/vagrant/embedded/bin/ruby

require 'YAML'
require 'optparse'

$ucp_version='latest'

OptionParser.new do |opts|
  opts.banner = "Usage: upgrade-ucp.rb [options]"
  opts.on('-v', '--version', "=MANDATORY", 'UCP version') { |v| $ucp_version=v }
end.parse!

SPEC_FILE=ENV['STEVEDORE_FILE'] || File.expand_path(File.dirname(__FILE__) + '/..') + '/stevedore.yaml'

SPEC=YAML::load(File.open(SPEC_FILE))

SPEC['vms'].each do |vm|
  vm['roles'].each do |role|
    if role.include? 'ducp'
      puts "Reconfiguring %s" % vm['name']
      cmd="vagrant ssh %s -c 'docker run --rm -it --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:%s upgrade'" \
        % [ vm['name'], $ucp_version ]
      system(cmd)
    end
  end
end
