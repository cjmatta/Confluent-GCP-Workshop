#!/bin/bash


WORKER1=$(gcloud compute instances list --format=json --filter="name~confluent-cloud"  | jq -r '.[0] | .networkInterfaces[0].accessConfigs[0].natIP')
WORKER2=$(gcloud compute instances list --format=json --filter="name~confluent-cloud"  | jq -r '.[1] | .networkInterfaces[0].accessConfigs[0].natIP')
CONNECT_HOST=${WORKER1}

if [[ $1 ]];then
    CONNECT_HOST=$1
fi

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "wikipedia-irc",
  "config": {
    "connector.class": "com.github.cjmatta.kafka.connect.irc.IrcSourceConnector",
    "transforms": "WikiEditTransformation",
    "transforms.WikiEditTransformation.type": "com.github.cjmatta.kafka.connect.transform.wikiedit.WikiEditTransformation",
    "transforms.wikiEditTransformation.save.unparseable.messages": true,
    "transforms.wikiEditTransformation.dead.letter.topic": "wikipedia.failed",
    "irc.channels": "#en.wikipedia,#fr.wikipedia,#es.wikipedia,#ru.wikipedia,#en.wiktionary,#de.wikipedia,#zh.wikipedia,#sd.wikipedia,#it.wikipedia,#mediawiki.wikipedia,#commons.wikimedia,#eu.wikipedia,#vo.wikipedia,#eo.wikipedia,#uk.wikipedia",
    "irc.server": "irc.wikimedia.org",
    "kafka.topic": "wikipedia",
    "producer.interceptor.classes": "io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor",
    "key.converter":"org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": "http://${WORKER1}:8081,http://${WORKER2}:8081",
    "tasks.max": "1"
  }
}
EOF
)

echo "curl -X POST -H \"${HEADER}\" --data \"${DATA}\" http://${CONNECT_HOST}:8083/connectors"
curl -X POST -H "${HEADER}" --data "${DATA}" http://${CONNECT_HOST}:8083/connectors
echo
