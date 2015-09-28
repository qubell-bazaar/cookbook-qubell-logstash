# Install logstash standalone

require 'uri'
require 'open-uri'
include_recipe "java"
if node['qubell_logstash']['role'] == 'indexer'
  include_recipe "qubell_logstash::kibana"
  include_recipe "qubell_logstash::elasticsearch_site"
end
include_recipe "service_factory"
include_recipe "qubell_logstash::logger"
case node['platform_family']
   when "rhel"
     service 'iptables' do
       action :stop
     end
   when "windows"
     powershell_script "disable_firewall" do
       flags "-ExecutionPolicy Unrestricted"
       code <<-EOH
          netsh advfirewall set allprofiles state off
       EOH
     end
   end
