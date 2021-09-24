#!/bin/bash
DELAY=10
echo "Adding zookeeper servers one at a time"

echo "Starting new zookeeper servers"
for i in {6..8}
  do docker-compose -f docker-compose-step0.yml -f docker-compose-step1.$i.yml up -d zookeeper_$i
  echo "Sleeping $DELAY"
  sleep $DELAY
  echo "Adding new server references to existing Zookeeper ensemble and restarting ensemble to pick up new configuration"
  for j in $(seq 1 $i)
    do docker-compose -f docker-compose-step0.yml -f docker-compose-step1.$i.yml up -d zookeeper_$j
    echo "Sleeping $DELAY"
    sleep $DELAY
  done
done
