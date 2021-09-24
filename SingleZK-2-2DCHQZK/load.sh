docker cp ./assets/text/textfile.txt tools:/tmp
docker exec -t tools bash -c  "/bin/kafka-topics --create --bootstrap-server kafka_1:29092  --replication-factor 2 --partitions 1 --topic load_test_topic --config retention.bytes=10485760"
echo "launch watch.sh in a new shell to see the messages being delivered to a test topic"
docker exec -t tools bash -c "/bin/kafka-producer-perf-test --num-records 1000 --throughput 1 --producer-props acks=all bootstrap.servers=kafka_1:29092,kafka_2:29093 --topic load_test_topic --payload-file /tmp/textfile.txt"
