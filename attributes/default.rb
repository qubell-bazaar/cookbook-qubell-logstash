default['kibana']['serve_ssl'] = false

default['ganglia']['root'] = '/var/lib/ganglia'
default['ganglia']['version'] = "3.1.7"
default['ganglia']['uri'] = "http://sourceforge.net/projects/ganglia/files/ganglia%20monitoring%20core/3.1.7/ganglia-3.1.7.tar.gz/download"
default['ganglia']['checksum'] = "bb1a4953"
if (node[:platform] == "ubuntu" and node[:platform_version].to_f <= 10.04) or not node.run_list.include?("recipe[logstash::monitor]")
  default['qubell_logstash']['skip_monitor'] = true
else
  default['qubell_logstash']['skip_monitor'] = false
end

default['kibana']['install_root']             = '/var/lib/kibana'
default['kibana']['ssl_certificate']          = '/var/lib/logstash/server.pem' # TODO
default['kibana']['ssl_certificate_key']      = '/var/lib/logstash/server.key' # TODO
default['kibana']['version']                  = '3.0.0'

default['qubell_logstash']['version']                = '1.3.3'
default['qubell_logstash']['install_root']           = '/var/lib/logstash'
case node['platform_family']
  when 'rhel'
    default['qubell_logstash']['logs']               = '/var/log/logstash/'
    default['qubell_logstash']['install_root']       = '/var/lib/logstash'
    default['qubell_logstash']['patterns_dir']       = '/var/lib/logstash/patterns'
  when 'windows'
    default['qubell_logstash']['install_root']       = "C:\\Logstash"
    default['qubell_logstash']['logs']               = "C:\\Logstash\\log"
    default['qubell_logstash']['patterns_dir']       = "C:\\Logstash\\patterns"
  end
default['qubell_logstash']['ssl_certificate']        = '/var/lib/logstash/server.pem'
default['qubell_logstash']['ssl_certificate_key']    = '/var/lib/logstash/server.key'
default['qubell_logstash']['loglevel']               = 'WARN' # WARN, INFO, VERBOSE, TRACE
default['qubell_logstash']['extra_args']             = []
default['qubell_logstash']['amqp_url']               = nil
default['qubell_logstash']['amqp_queue']             = nil
default['qubell_logstash']['amqp_exchange']          = nil
default['qubell_logstash']['syslog']['enabled']      = false
default['elasticsearch']['serve_ssl']           = false
default['elasticsearch']['proxy_port']          = 9201
default['elasticsearch']['ssl_certificate']     = '/var/lib/logstash/server.pem' # TODO
default['elasticsearch']['ssl_certificate_key'] = '/var/lib/logstash/server.key' # TODO
default['elasticsearch']['path']['home']        = '/var/lib/elasticsearch'
default['elasticsearch']['path']['config']      = '/var/lib/elasticsearch/config'
default['elasticsearch']['path']['data']        = '/var/lib/elasticsearch/data'
default['elasticsearch']['path']['logs']        = '/var/log/elasticsearch'
default['elasticsearch']['file_limits']         = 10000
