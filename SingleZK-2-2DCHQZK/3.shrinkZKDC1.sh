docker-compose -f docker-compose-step0.yml -f docker-compose-step1.yml -f docker-compose-step2.yml -f docker-compose-step3.yml up -d
echo "Removing Zookeeper 4..."
docker-compose -f docker-compose-step0.yml -f docker-compose-step1.yml -f docker-compose-step2.yml -f docker-compose-step3.yml stop zookeeper_4
echo "Removing Zookeeper 5..."
docker-compose -f docker-compose-step0.yml -f docker-compose-step1.yml -f docker-compose-step2.yml -f docker-compose-step3.yml stop zookeeper_5
