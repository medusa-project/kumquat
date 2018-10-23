# Configures the elasticsearch-model gem.
#
# https://github.com/elastic/elasticsearch-ruby/tree/master/elasticsearch-transport

Elasticsearch::Model.client = Elasticsearch::Client.new(host: Configuration.instance.elasticsearch_endpoint,
                                                        log: false)