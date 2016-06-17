#!/opt/vagrant/embedded/bin/ruby

require 'YAML'
require 'optparse'

$command='echo "Forgot the command"'
OptionParser.new do |opts|
  opts.banner = "Usage: cluster-docker.rb [options]"
  opts.on('-c', '--command', "=MANDATORY", 'UCP command') { |v| $command=v }
end.parse!

SPEC_FILE=ENV['STEVEDORE_FILE'] || File.expand_path(File.dirname(__FILE__) + '/..') + '/stevedore.yaml'

SPEC=YAML::load(File.open(SPEC_FILE))

SPEC['vms'].each do |vm|
  vm['roles'].each do |role|
    if role.include? 'ducp'
      puts "Commanding %s" % vm['name']
      cmd="vagrant ssh %s -c '%s'" \
        % [ vm['name'], $command]
      system(cmd)
    end
  end
end
