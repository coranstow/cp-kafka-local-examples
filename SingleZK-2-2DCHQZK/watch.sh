#!/bin/bash
docker exec -t tools bash -c  "/bin/kafka-console-consumer --bootstrap-server kafka_1:29092,kafka_2:29093 --topic load_test_topic --group test_reader"
