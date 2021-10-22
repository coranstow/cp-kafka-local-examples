#!/bin/bash
# This script instantiated the keystore for each node and generates a CSR

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

      external=${split_hostnames[2]}
      echo "Service: $service hostname: $internal dns:$internal dns:$fqdn"

      alias=$service.$internal
      KEYSTORE_FILENAME=$KEYSTORE_DIR/$internal.keystore.jks

      CSR_FILENAME=$internal.csr
      CRT_SIGNED_FILENAME=$CERT_DIR/$internal-ca1-signed.crt
      KEY_FILENAME=$internal-key.pem
      # EXT="SAN=dns:$internal"
      fqdn=$internal$DOMAIN
      [[ -z "$DOMAIN" ]] && EXT="SAN=dns:$internal" || EXT="SAN=dns:$internal,dns:$fqdn"

      #FORMAT=$1
      FORMAT=pkcs12

      echo "  >>>  Import the CA cert into the keystore"
      keytool -noprompt -import \
          -keystore $KEYSTORE_FILENAME \
          -alias CARoot \
          -file $CA_CRT  \
          -storepass keystorepass \
          -keypass keystorepass


      if (( $# == 2 ))
      then
        echo "  >>>  Import the CA cert twice into the keystore"
        keytool -noprompt -import \
            -keystore $KEYSTORE_FILENAME \
            -alias dumbcert \
            -file $CA_CRT  \
            -storepass keystorepass \
            -keypass keystorepass
      fi

      echo "  >>> Import the host certificate into the keystore"
      keytool -noprompt -import \
          -keystore $KEYSTORE_FILENAME \
          -alias $fqdn \
          -file $CRT_SIGNED_FILENAME \
          -storepass keystorepass \
          -keypass keystorepass

      echo " >>> Import the host certificate into the  truststore"
      keytool -noprompt -keystore $SERVER_TRUSTSTORE \
            -alias $fqdn \
            -importcert \
            -file $CRT_SIGNED_FILENAME \
            -storepass truststorepass \
            -keypass truststorepass


done
