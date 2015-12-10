#!/opt/vagrant/embedded/bin/ruby

require 'YAML'

STEVEDORE_ROOT=File.expand_path(File.dirname(__FILE__) + '/..')
SPEC_FILE=ENV['STEVEDORE_FILE'] || STEVEDORE_ROOT + '/stevedore.yaml'
SPEC=YAML::load(File.open(SPEC_FILE))

SPEC['vms'].each do |vm|
    ip = vm['ip']
    name = vm['name'] + '.' + vm['domain']
    cmd = "#{STEVEDORE_ROOT}/scripts/gen-keys.sh #{name} #{ip}"
    system(cmd)
end
