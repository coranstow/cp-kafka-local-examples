./kafka-topics --create --bootstrap-server localhost:9092 --topic test --partitions 1 --replica-placement /opt/Dev/cp-kafka-local/dc1.json --config min.insync.replicas=2
