#!/bin/bash
CCLOUD_CONFIG=~/.ccloud/config
BOOTSTRAP_SERVER=$(cat ${CCLOUD_CONFIG} | grep "bootstrap.servers" | awk -F= '{print $2}' | sed s/\\\\:/\:/g)
API_KEY=$(cat ${CCLOUD_CONFIG} | grep 'sasl.jaas.config' | cut -d '"' -f2)
SECRET=$(cat ${CCLOUD_CONFIG} | grep 'sasl.jaas.config' | cut -d '"' -f4)

cat channel-language-mapping.csv | kafkacat -X sasl.mechanisms=PLAIN -X security.protocol=SASL_SSL  \
-X sasl.username=${API_KEY} -X sasl.password=${SECRET} \
    -b ${BOOTSTRAP_SERVER} -P -t wikipedia-language-map -K: