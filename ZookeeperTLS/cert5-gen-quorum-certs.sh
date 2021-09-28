#!/bin/bash
. ./set_env.sh

echo " >>> Create the Zookeeper Quorum TrustStore and import the CA Certificate "
keytool -noprompt -keystore $QUORUM_TRUSTSTORE -alias CARoot -importcert -file $CA_CRT -storepass truststorepass -keypass truststorepass


filename="certificate-hosts"
# remove the empty lines
for line in $(grep '^zookeeper' $filename);
do
    echo $line
    OIFS=$IFS
    IFS=':'
    read -ra split_hostnames <<< "$line"
    IFS=$OIFS
    service=${split_hostnames[0]}
    internal=${split_hostnames[1]}

    # external=${split_hostnames[2]}
    echo "Service: $service hostname: $internal"

    alias=$service.$internal
    KEYSTORE_FILENAME=$KEYSTORE_DIR/$internal.quorum.keystore.jks

    CSR_FILENAME=$CERT_DIR/$internal-quorum-csr.pem
    CRT_SIGNED_FILENAME=$CERT_DIR/$internal-quorum-ca1-signed.crt
    KEY_FILENAME=$CERT_DIR/$internal-quorum-key.pem
    # EXT="SAN=dns:$internal"

    fqdn=$internal$DOMAIN
    [[ -z "$DOMAIN" ]] && EXT="SAN=dns:$internal" || EXT="SAN=dns:$internal,dns:$fqdn"
    echo "EXT = $EXT"
    #FORMAT=$1
    FORMAT=pkcs12

    echo "  >>>  Create quorum host keystore "
    keytool -genkeypair -noprompt \
        -keystore $KEYSTORE_FILENAME \
        -alias $fqdn \
        -dname "cn=$fqdn" \
        -ext $EXT \
        -keyalg RSA \
        -storetype $FORMAT \
        -keysize 2048 \
        -storepass keystorepass \
        -keypass keystorepass


    if [ $FORMAT = "pkcs12" ];
    then
       echo "  >>>  Get quorum host key from quorum Keystore"
       openssl pkcs12 \
           -in $KEYSTORE_FILENAME \
           -passin pass:keystorepass \
           -passout pass:keypass \
           -nodes -nocerts \
           -out $KEY_FILENAME
    fi

    echo "  >>>  Create the certificate signing request (CSR) for the quorum certificate"
    keytool -certreq \
        -keystore $KEYSTORE_FILENAME \
        -alias $fqdn \
    		-ext $EXT \
        -file $CSR_FILENAME \
        -storepass keystorepass \
        -keypass keystorepass

    echo "  >>>  Sign the quorum host certificate with the certificate authority (CA)"
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

      echo "  >>>  Import the CA cert into the quorum keystore"
      keytool -noprompt -import \
          -keystore $KEYSTORE_FILENAME \
          -alias CARoot \
          -file $CA_CRT  \
          -storepass keystorepass \
          -keypass keystorepass


      echo "  >>> Import the host certificate into Quorum the keystore"
      keytool -noprompt -import \
          -keystore $KEYSTORE_FILENAME \
          -alias $fqdn \
          -file $CRT_SIGNED_FILENAME \
          -storepass keystorepass \
          -keypass keystorepass

      echo " >>> Import the host certificate into the Quorum truststore"
      keytool -noprompt -keystore $QUORUM_TRUSTSTORE \
            -alias $fqdn \
            -importcert \
            -file $CRT_SIGNED_FILENAME \
            -storepass truststorepass \
            -keypass truststorepass

done
