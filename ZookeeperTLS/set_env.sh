#!/bin/bash


CERT_DIR=./certs
CA_CRT=$CERT_DIR/ca-crt.pem
CA_KEY=$CERT_DIR/ca-key.pem

KEYSTORE_DIR=./keystores
CLIENT_TRUSTSTORE=$KEYSTORE_DIR/kafka.client.truststore.jks
SERVER_TRUSTSTORE=$KEYSTORE_DIR/kafka.server.truststore.jks

DOMAIN=".zookeepertls"
