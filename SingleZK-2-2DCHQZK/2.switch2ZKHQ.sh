#!/bin/bash
DELAY=10
echo "Applying Hierarchical Quorum settings to the Zookeeper ensemble"
for i in {1..8}
  do docker-compose -f docker-compose-step0.yml -f docker-compose-step1.yml -f docker-compose-step2.yml up -d zookeeper_$i
  echo "Sleeping for $DELAY"
  sleep $DELAY
done
