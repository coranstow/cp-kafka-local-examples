
#!/bin/bash
echo "Changing kafa_2 to use the new zookeeper nodes"

docker-compose -f docker-compose-step0.yml docker-compose-step4.yml up -d kafka_2
