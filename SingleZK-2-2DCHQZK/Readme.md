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
3. 2.switch2ZKHQ.sh - uses docker-compose overload to
  * Enables the Zookeeper Hierarchical Quorum feature by setting `ZOOKEEPER_GROUPS` and `ZOOKEEPER_WEIGHTS` appropriately on each node.
  * The Hierarchical Quorums are split across the two DCs.
4. 3.shrinkZKDC1.sh - uses docker-compose overload to
  * Changes the Hierarchical Quorums to remove zookeeper_4 and zookeeper_5
  * Stops the zookeeper_4 and zookeeper_5 services
  * Interestingly, does NOT update the ZOOKEEPER_SERVERS value on the existing servers.
5. 4.kafkaToLocalZK.sh - uses docker-compose overload to
  * Update the Kafka Broker `kafka_2` to use the new zookeeper ensemble
