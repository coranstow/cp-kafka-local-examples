#!/bin/bash
# This script instantiates the keystore for each node and generates a CSR

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

      # external=${split_hostnames[2]}
      echo "Service: $service hostname: $internal"

      alias=$service.$internal
      KEYSTORE_FILENAME=$KEYSTORE_DIR/$internal.keystore.jks

      CSR_FILENAME=$CERT_DIR/$internal-csr.pem
      CRT_SIGNED_FILENAME=$CERT_DIR/$internal-ca1-signed.crt
      KEY_FILENAME=$CERT_DIR/$internal-key.pem
      # EXT="SAN=dns:$internal"

      fqdn=$internal$DOMAIN
      [[ -z "$DOMAIN" ]] && EXT="SAN=dns:$internal" || EXT="SAN=dns:$internal,dns:$fqdn"
      echo "EXT = $EXT"
      #FORMAT=$1
      FORMAT=pkcs12

      echo "  >>>  Create host keystore"
      keytool -genkeypair -noprompt \
          -keystore $KEYSTORE_FILENAME \
          -alias $fqdn \
          -dname "cn=mTLS_User,O=CONFLUENT,L=PaloAlto,ST=Ca,C=US" \
          -ext $EXT \
          -keyalg RSA \
          -storetype $FORMAT \
          -keysize 2048 \
          -storepass keystorepass \
          -keypass keystorepass


      if [ $FORMAT = "pkcs12" ]; then
         echo "  >>>  Get host key from Keystore"
         openssl pkcs12 \
             -in $KEYSTORE_FILENAME \
             -passin pass:keystorepass \
             -passout pass:keypass \
             -nodes -nocerts \
             -out $KEY_FILENAME
      fi

      echo "  >>>  Create the certificate signing request (CSR)"
      keytool -certreq \
          -keystore $KEYSTORE_FILENAME \
          -alias $fqdn \
    			-ext $EXT \
          -file $CSR_FILENAME \
          -storepass keystorepass \
          -keypass keystorepass

done
