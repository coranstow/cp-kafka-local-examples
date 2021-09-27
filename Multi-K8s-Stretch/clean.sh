#!/bin/bash
kubectl delete ns confluent-dc1 confluent-dc2
helm repo remove confluentinc
