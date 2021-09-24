#!/bin/bash
DELAY=10
echo "Updating Kafka brokers to remove zookeeper servers 4 and 5 from the Broker's Zookeeper configuration"
for i in {1,2}
  do docker-compose -f docker-compose-step0.yml -f docker-compose-step1.yml -f docker-compose-step2.yml -f docker-compose-step3a.yml up -d kafka_$i
  echo "Sleeping $DELAY"
  sleep $DELAY
done

echo "Updating Zookeeper ensemble to remove servers 4 and 5 from the ensemble"
for i in {1,2,3,6,7,8}
  do docker-compose -f docker-compose-step0.yml -f docker-compose-step1.yml -f docker-compose-step2.yml -f docker-compose-step3.yml up -d zookeeper_$i
  echo "Sleeping $DELAY"
  sleep $DELAY
done

#docker-compose -f docker-compose-step0.yml -f docker-compose-step1.yml -f docker-compose-step2.yml -f docker-compose-step3.yml up -d
echo "Removing Zookeeper 4..."
docker-compose -f docker-compose-step0.yml -f docker-compose-step1.yml -f docker-compose-step2.yml -f docker-compose-step3.yml stop zookeeper_4
echo "Removing Zookeeper 5..."
docker-compose -f docker-compose-step0.yml -f docker-compose-step1.yml -f docker-compose-step2.yml -f docker-compose-step3.yml stop zookeeper_5
