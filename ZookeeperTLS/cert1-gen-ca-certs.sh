#!/bin/bash


# set -o nounset \
#     -o errexit \
#     -o verbose \
#     -o xtrace


. ./set_env.sh

rm -f truststore.jks $CA_KEY $CA_CRT

#Set up local CA for local testing and dev
echo "  >>>  Generate CA cert and key"
openssl req -new -x509 \
    -keyout $CA_KEY \
    -out $CA_CRT \
    -days 365 \
    -subj '/CN=example.confluent.io/OU=example/O=CONFLUENT/L=MountainView/S=Ca/C=US' \
    -passin pass:capassword \
    -passout pass:capassword


echo "  >>>  Create truststore and import the CA cert"
keytool -noprompt -import \
    -keystore truststore.jks \
    -alias CARoot \
    -file $CA_CRT  \
    -storepass truststorepass \
    -keypass truststorepass

echo " >>> Create the Kafka Client TrustSture and import the CA Certificate "
keytool -noprompt -keystore $CLIENT_TRUSTSTORE -alias CARoot -importcert -file $CA_CRT -storepass truststorepass -keypass truststorepass

echo " >>> Create the Kafka Server TrustSture and import the CA Certificate "
keytool -noprompt -keystore $SERVER_TRUSTSTORE -alias CARoot -importcert -file $CA_CRT -storepass truststorepass -keypass truststorepass
