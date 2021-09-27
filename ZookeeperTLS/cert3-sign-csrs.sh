#!/bin/bash
# Shamelessly copied from ~/cp-ansible/roles/confluent.test/molecule/certs-create.sh
# and modified from there
# This script signs the CSR using the CA
# DEVELOPMENT only - the client should be doing this on-site.

# set -o nounset \
#     -o errexit \
#     -o verbose \
#     -o xtrace

# # Cleanup files

. ./set_env.sh


filename="certificate-hosts"
# remove the empty lines
for line in `sed '/^$/d' $filename`; do

    OIFS=$IFS
    IFS=':'
    read -ra split_hostnames <<< "$line"
      IFS=$OIFS
      service=${split_hostnames[0]}
      internal=${split_hostnames[1]}
      fqdn=$internal$DOMAIN
      external=${split_hostnames[2]}
      echo "Service: $service hostname: $internal dns:$internal dns:$fqdn"

      alias=$service.$internal
      KEYSTORE_FILENAME=$KEYSTORE_DIR/$internal.keystore.jks

      CSR_FILENAME=$CERT_DIR/$internal-csr.pem
      CRT_SIGNED_FILENAME=$CERT_DIR/$internal-ca1-signed.crt
      KEY_FILENAME=$CERT_DIR/$internal-key.pem
      # EXT="SAN=dns:$internal"
      EXT="SAN=dns:$internal,dns:$fqdn"

      #FORMAT=$1
      FORMAT=pkcs12

      echo "  >>>  Sign the host certificate with the certificate authority (CA)"
      openssl x509 -req \
          -CA $CA_CRT \
          -CAkey $CA_KEY \
          -in $CSR_FILENAME \
          -out $CRT_SIGNED_FILENAME \
          -days 9999 \
          -sha256 \
          -CAcreateserial \
          -passin pass:capassword \
    			-extensions v3_req \
    			-extfile <(cat <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
CN = $fqdn
[v3_req]
subjectAltName = @alt_names
[alt_names]
DNS.1 = $internal
DNS.2 = $fqdn
EOF
)

done
