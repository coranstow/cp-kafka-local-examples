#MDC-KafkaBroker-Expansion

This is a project to work through the challenges of expanding a Kafka/CP installation from a single DC to being a stretch across multiple DCs.
This part of the project expands the Zookeeper ensemble.

###Process
1. 0.init.sh - Sets up an installation using Docker-compose that contains
  * 5 Zookeeper nodes `zookeeper_[1-5]` with IDs `[1-5]`.
  * 3 Kafka Brokers
  * Metrics services (node-exporter + prometheus)
  * Schema Registry, Kafka Connect, C3
2. 1.expand.sh - Uses Docker-compose overload to
  * Add 3 new zk servers `zookeeper_[6-8]` with IDs `[10-12]`
  * Update the `ZOOKEEPER_SERVERS` value on the existing servers to include the new servers.
  * New ZK severs are added one at a time and the whole ensemble is restarted before the next zk server is added.
3. 2.switch2ZKHQ.sh - uses docker-compose overload to
  * Enable the Zookeeper Hierarchical Quorum feature by setting `ZOOKEEPER_GROUPS` and `ZOOKEEPER_WEIGHTS` appropriately on each node.
  * Split the Hierarchical Quorums across the two DCs.
4. 3.shrinkZKDC1.sh - uses docker-compose overload to
  * Reconfigure and restart the Kafka servers so they don't communicate with the server's we're decommissioning.
  * Updates the ZOOKEEPER_SERVERS value on the existing servers to remove zookeeper_4 and zookeeper_5.
  * Changes the Hierarchical Quorums to remove zookeeper_4 and zookeeper_5
  * Stops the zookeeper_4 and zookeeper_5 services
5. 4.kafkaToLocalZK.sh - uses docker-compose overload to
  * Update the Kafka Broker kafka_2 to use the new zookeeper ensemble zookkeeper_6 to zookeeper_8.
6. clean.sh - uses docker-compose to drop all containers.

###Demonstrating

Start with <code>0.init.sh </code> to set up a sample Confluent installation.
After a minute or two Confluent Control Center should be available to `http://localhost:9021`

If you'd like to see a producer and consumer working uninterrupted while the zookeeper ensemble is expanded, run the following in separate terminals:
1. `load.sh` - creates a new topic and starts kafka-producer-perf-test
2. `watch.sh` - reads from the topic using kafka-console-consumer

Then run:
1. `1.expand.sh` to add the new ZooKeeper servers to the ensemble
2. `2.switch2ZKHQ.sh` to enable ZooKeeper Hierarchical Quorums
3. `3.shrinkZKDC1.sh` to decommission two of the original five ZooKeeper servers.
4. `4.kafkaToLocalZK.sh` to update the kafka_2 server to use the new ZooKeeper servers.
