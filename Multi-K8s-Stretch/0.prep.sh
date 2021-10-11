#!/bin/bash
helm repo add confluentinc https://packages.confluent.io/helm

for i in {1..2}
do
  kubectl create namespace confluent-dc$i
  kubectl config set-context --current --namespace=confluent-dc$i
  helm repo update --namespace confluent-dc$i
#  helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes --namespace confluent-dc$i
done



kubectl apply -f ./confluent-platform-dc1.yaml --namespace=confluent-dc1
