name             'qubell_logstash'
maintainer       'The Authors'
maintainer_email 'support@qubell.com'
license          'all_rights'
description      'Installs/Configures Logstash Kibana Elasticsearch stack'
long_description 'Installs/Configures Logstash Kibana Elasticsearch stack'
version          '0.1.0'

depends "redisio"
depends "windows", "= 1.38.1"
depends "java"
depends "nginx"
depends "service_factory"
depends "logstash"
depends "yum"
