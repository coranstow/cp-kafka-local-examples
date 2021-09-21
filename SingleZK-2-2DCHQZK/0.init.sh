#!/bin/bash
echo "Creating Confluent installation using Docker Compose"
docker-compose -f docker-compose-step0.yml up -d
echo "Give it a minute, then go to Confluent Control Centre at http://localhost:9021"
