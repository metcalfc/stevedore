#!/opt/vagrant/embedded/bin/ruby

require 'YAML'
require 'IPAddr'

STEVEDORE_ROOT=File.expand_path(File.dirname(__FILE__) + '/..')
SPEC_FILE=ENV['STEVEDORE_FILE'] || STEVEDORE_ROOT + '/stevedore.yaml'
SPEC=YAML::load(File.open(SPEC_FILE))

$ip_range = IPAddr.new(SPEC['vm_defaults']['ip_range']).to_range.to_enum

def get_ip
  ip = $ip_range.next
  if ip.to_s.end_with?('.0') || ip.to_s.end_with?('.255')
    $ip_range.next
  else
    ip
  end
end

SPEC['vms'].each do |vm|
    ip = get_ip.to_s
    name = vm['name'] + '.' + vm['domain']
    cmd = "#{STEVEDORE_ROOT}/scripts/gen-keys.sh #{name} #{ip}"
    system(cmd)
end
