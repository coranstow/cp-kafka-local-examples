#!/bin/bash
echo "Creating Confluent installation using Docker Compose"
docker-compose -f docker-compose-step0.yml up -d
echo "Give it a minute, then go to Confluent Control Center at http://localhost:9021"
echo "When Control Center shows the cluster is operating normally, run load.sh and watch.sh in separate terminals"
