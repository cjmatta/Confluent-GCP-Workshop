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
  "name": "bigquery-wikipediaedits",
  "config": {
    "connector.class": "com.wepay.kafka.connect.bigquery.BigQuerySinkConnector",
    "topics": "WIKIPEDIAEDITS,wikipedia",
    "topicsToTables": "WIKIPEDIAEDITS=WIKIPEDIAEDITS,wikipedia=wikipediasource",
    "autoCreateTables": true,
    "sanitizeTopics": true,
    "autoUpdateSchemas": true,
    "schemaRetriever": "com.wepay.kafka.connect.bigquery.schemaregistry.schemaretriever.SchemaRegistrySchemaRetriever",
    "schemaRegistryLocation": "http://${WORKER1}:8081,http://${WORKER2}:8081",
    "key.converter":"org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": "http://${WORKER1}:8081,http://${WORKER2}:8081",
    "bufferSize": 100000,
    "maxWriteSize": 10000,
    "tableWriteWait": 1000,
    "project": "sales-engineering-206314",
    "datasets": ".*=wikipedia",
    "keyfile": "/etc/kafka/gbq-keyfile.json",
    "tasks.max": "4"
  }
}
EOF
)

echo "curl -X POST -H \"${HEADER}\" --data \"${DATA}\" http://${CONNECT_HOST}:8083/connectors"
curl -X POST -H "${HEADER}" --data "${DATA}" http://${CONNECT_HOST}:8083/connectors
echo
