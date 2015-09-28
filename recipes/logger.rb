# Install logstash standalone

require 'uri'
require 'open-uri'
include_recipe "java"
include_recipe "service_factory"

rootdir = node['qubell_logstash']['install_root']

loglevels = {
  "WARN" => "",
  "INFO" => "-v",
  "DEBUG" => "-vv",
  "TRACE" => "-vvv"
}
loglevels.default = "-vv"

directory rootdir do
  owner node.qubell_logstash.user
  group node.qubell_logstash.group
  mode "0755"
  action :create
end
directory node.qubell_logstash.logs do
  owner node.qubell_logstash.user
  group node.qubell_logstash.group
  mode "0755"
  action :create
end
directory node.qubell_logstash.patterns_dir do
  owner node.qubell_logstash.user
  group node.qubell_logstash.group
  mode "0755"
  action :create
end
patterns = ["tomcat", "apache", "weblogic"]
patterns.each do |p|
  template "#{node.qubell_logstash.patterns_dir}/#{p}-patterns" do
    owner node.qubell_logstash.user
    group node.qubell_logstash.group
    mode "0644"
    source "#{p}-patterns.erb"
  end
end

if node['qubell_logstash']['role'] == 'indexer'
  node['elasticsearch']['path'].each_value do |path|
    directory path do
      owner node.qubell_logstash.user
      group node.qubell_logstash.group
      mode "0755"
      recursive true
      action :create
    end
  end
      
  template "/etc/security/limits.d/80-elasticsearch.conf" do
    owner "root"
    group "root"
    mode "0644"
    source "80-elasticsearch.conf.erb"
  end

  template "#{node['elasticsearch']['path']['config']}/elasticsearch.yml" do
    owner node.qubell_logstash.user
    group node.qubell_logstash.group
    mode "0644"
    source "elasticsearch.yml.erb"
  end

  bash "generate logstash certificate" do
    not_if { File.exists? ::File.join(rootdir, "server.pem") }
    cwd rootdir
    user node.qubell_logstash.user
    group node.qubell_logstash.group
    code <<-EOC
      openssl genrsa -out #{::File.join(rootdir, "server.key")} 2048
      openssl req -new -x509 -extensions v3_ca -days 1100 -subj "/CN=Logstash" -nodes -out #{::File.join(rootdir, "server.pem")} -key #{::File.join(rootdir, "server.key")}
    EOC
  end
end


remote_file "#{rootdir}/logstash.jar" do
  source "https://download.elasticsearch.org/logstash/logstash/logstash-#{node['qubell_logstash']['version']}-flatjar.jar"
  owner node.qubell_logstash.user
  group node.qubell_logstash.group
  mode "0644"
  action :create
end

inputs = []
if platform_family?('windows')
  if node['qubell_logstash']['syslog']['enabled'] == true
    inputs.push "eventlog" => {
      :type => "WindowsEventLog"
    }
  end
end
if node['qubell_logstash']['redis_url'] and node['qubell_logstash']['role'] == 'indexer'
  redis_uri = URI(node['qubell_logstash']['redis_url'])
  inputs.push "redis" => {
    :host => redis_uri.host,
    :port => (redis_uri.port or 6379),
    :data_type => "list",
    :key => "logstash",
  }
elsif node['qubell_logstash']['log_target'] 
  redis_uri = URI(node['qubell_logstash']['redis_url'])
  node['qubell_logstash']['log_target'].each do |p|
   path = p.split('::')[0]
   type = p.split('::')[1]
   inputs.push "file" => {
    :path => path,
    :format => 'plain',
    :type => type,
    :tags => type
  }
  end
end

outputs = []

if node['qubell_logstash']['redis_url'] and node['qubell_logstash']['role'] == 'consumer'
  redis_uri = URI(node['qubell_logstash']['redis_url'])
  outputs.push "redis" => {
    :host => redis_uri.host,
    :port => (redis_uri.port or 6379),
    :data_type => "list",
    :key => "logstash"
  }
elsif node['qubell_logstash']['role'] == 'indexer'
  outputs.push "elasticsearch" => {
    :index => "logstash-%{+YYYY.MM.dd}",
    :embedded => true 
  }
end

template "#{rootdir}/logstash.conf" do
  owner node.qubell_logstash.user
  group node.qubell_logstash.group
  mode "0644"
  source "logstash-#{node.qubell_logstash.role}.conf.erb"
  variables ({
    "inputs" => inputs,
    "outputs" => outputs
  })
end

if platform_family?('rhel')
  mem_kb = node['memory']['total'].split('kB')[0].to_i * 2 / 3
  if node['qubell_logstash']['role'] == 'indexer'
    exec_args = ["-Xmx#{mem_kb}k", "-Des.path.home=#{node['elasticsearch']['path']['home']}", "-Des.path.config=#{node['elasticsearch']['path']['config']}", "-jar #{rootdir}/logstash.jar", "agent", "-f #{rootdir}/logstash.conf", "--log #{node['qubell_logstash']['logs']}/logstash.log", loglevels[node['qubell_logstash']['loglevel']]] + node['qubell_logstash']['extra_args']
  elsif node['qubell_logstash']['role'] == 'consumer'
    exec_args = ["-Xmx#{mem_kb}k", "-jar #{rootdir}/logstash.jar", "agent", "-f #{rootdir}/logstash.conf", "--log #{node['qubell_logstash']['logs']}/logstash.log", loglevels[node['qubell_logstash']['loglevel']]] + node['qubell_logstash']['extra_args']
  end
  service_factory "logstash" do
    service_desc "Lostash and Elasticsearch"
    exec "/usr/bin/java"
    exec_args exec_args 
    after_start "sleep 300" # logstash startup is very slow
    run_user node.qubell_logstash.user
    run_group node.qubell_logstash.group
    action [:create, :enable, :start]
  end
end
if platform_family?('windows')
remote_file "#{rootdir}\\nssm.zip" do
  source "https://s3.amazonaws.com/qubell-starter-kit-artifacts/loky9000/nssm-2.24.zip"
  action :create
end 

remote_file "#{rootdir}\\7z920-x64.msi" do
  source "https://s3.amazonaws.com/qubell-starter-kit-artifacts/loky9000/unzip.exe"
  action :create
end

root_dir_mod="#{rootdir.gsub(/\\/, '/')}"
template "#{rootdir}/logstash.bat" do
  owner node.qubell_logstash.user
  group node.qubell_logstash.group
  mode "0644"
  source "logstash.bat.erb"
  variables ({
    "root_dir" => rootdir,
    "root_dir_mod" => root_dir_mod,
    "loglevel" => loglevels[node['qubell_logstash']['loglevel']],
    "extra_args" => node['qubell_logstash']['extra_args'].join(" ")
   })
end

mem_kb = 512
 batch 'create logstash service' do
    cwd "#{rootdir}"
    code <<-EOH
        unzip.exe nssm-2.24.zip 
        nssm-2.24\\win64\\nssm.exe install logstash #{rootdir}\\logstash.bat
        nssm-2.24\\win64\\nssm.exe set logstash AppDirectory C:\\Logstash
        nssm-2.24\\win64\\nssm.exe set logstash AppStdout #{node['qubell_logstash']['logs']}\\stdout.log
        nssm-2.24\\win64\\nssm.exe set logstash AppStderr #{node['qubell_logstash']['logs']}\\stderr.log
        nssm-2.24\\win64\\nssm.exe set logstash AppStdoutCreationDisposition 2
        nssm-2.24\\win64\\nssm.exe set logstash AppStderrCreationDisposition 2
        nssm-2.24\\win64\\nssm.exe set logstash AppStopMethodSkip 6
        net stop logstash
        net start logstash
    EOH
  end
end
node.set['qubell_logstash']['tag'] = node['hostname']
