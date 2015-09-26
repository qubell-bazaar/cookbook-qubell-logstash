include_recipe "redisio"
include_recipe "redisio::enable"
node.set['qubell_logstash']['redis_url'] = "redis://#{node['ipaddress']}:#{node['redisio']['servers'][0]['port']}"
