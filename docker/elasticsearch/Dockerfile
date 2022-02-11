FROM elasticsearch:7.10.1

ENV discovery.type=single-node

RUN sed -i -e 's/rootLogger.level = info/rootLogger.level = error/g' config/log4j2.properties \
    && echo "cluster.routing.allocation.disk.threshold_enabled: false" >> config/elasticsearch.yml

RUN bin/elasticsearch-plugin install --batch analysis-icu