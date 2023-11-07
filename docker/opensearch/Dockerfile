FROM public.ecr.aws/opensearchproject/opensearch:2

ENV discovery.type=single-node

RUN sed -i -e 's/rootLogger.level = info/rootLogger.level = error/g' config/log4j2.properties \
    && sed '/^plugins.security/d' config/opensearch.yml \
    && echo "plugins.index_state_management.enabled: false" >> config/opensearch.yml \
    && rm -rf plugins/opensearch-security

RUN bin/opensearch-plugin remove opensearch-performance-analyzer \
    && bin/opensearch-plugin install --batch analysis-icu
