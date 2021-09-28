# ZooKeeper TLS Demoonstration

This is a project to demonstrate the securing of Zookeeper with TLS, both for client connections and for connections that are internal to the zookeeper ensemble.

When running, the ZooKeeper ensemble communicates exclusively over TLs using one set of certificates/keystores for the internal Quorum communication and a different set of certificates/keystores for client communication. In this case the client is exclusively the Kafka brokers.

### Prerequisite
1. Docker
2. Docker-compose
3. OpenSSL, keytool ,etc
4. Netcat

### Process
1. Generate the certificates by running `./generate-certificates.sh`.
  * This will place a set of certificates in `./certs` and a set of Java Key Stores in `./keystores`.
  * The keystores are important, see below for descriptions
2. Start the Docker containers with `docker-compose up -d`


### keystores
1. `kafka.cient.truststore.jks` - Just contains the Root CA so that clients can trust the servers certificates
2. `kafka.server.truststore.jks` - The trust store for the ZooKeeper and Kafka servers mTLS. Contains all of the certificates used between the Zookeeper and Kafka servers.
3. `zookeeper.quorum.truststore.jks` - The trust store for the Kafka Quorum mTLS. Contains all of the certificates used by the ZooKeeper ensemble for quorum communication.
4. `zookeeper-[1..3].quorum.keystore.jks` - The keystore containing the ZooKeeper server's private key for quorum communication.
5. `zookeeper-[1..3].keystore.jks` - The keystore containing the ZooKeeper server's private key for client communication.
6. `kafka-[1..2].keystore.jks` - The keystore containing the Kafka server's private key for TLS, including communication with the Kafka ensemble.
7. other keystores not relevant to what we're demonstrating.


### Demonstrating

As the encrypted communication channels are generally on the data plane, where clients cannot see them, this is challenging to demonstrate. For this demonstration, `Zookeeper-1` has an unencrypted client listener on port `12181` and the ZooKeeper Four Letter Words are enabled so use netcat to ping the ZooKeeper server:

<code>ZookeeperTLS % echo ruok | nc -v localhost 12181<br/>
Connection to localhost port 12181 [tcp/*] succeeded!<br/>
imok%<br/>
ZookeeperTLS %
</code>

In contrast, the standard ZooKeeper port `2181` is secures with TLS. Netcat can connect to the post, but cannot communicate, so there is no response to `ruok`:

<code>ZookeeperTLS % echo ruok | nc -v localhost 2181<br/>
Connection to localhost port 2181 [tcp/eforward] succeeded!<br/>
ZookeeperTLS %
</code>

As can be seen from the `docker-compose.yml` file, the kafka servers are communcating with ZooKeeper over the encrypted ports:<br/>
<code>KAFKA_ZOOKEEPER_CONNECT: "zookeeper-1:2181,zookeeper-2:2182,zookeeper-3:2183"</code>


### The important config items for Zookeeper/Kafka
The important parts of the config for the Zookeeper/Kafka TLS communication are:<br/>
#### zookeeper<br/>
```      ZOOKEEPER_SERVER_CNXN_FACTORY: "org.apache.zookeeper.server.NettyServerCnxnFactory"
      ZOOKEEPER_SECURE_CLIENT_PORT: 2181
      ZOOKEEPER_AUTH_PROVIDER_X509: "org.apache.zookeeper.server.auth.X509AuthenticationProvider"
      ZOOKEEPER_SSL_KEYSTORE_LOCATION: /usr/share/keystores/zookeeper-1.keystore.jks<br>
      ZOOKEEPER_SSL_KEYSTORE_PASSWORD: "keystorepass"
      ZOOKEEPER_SSL_TRUSTSTORE_LOCATION: /usr/share/keystores/kafka.server.truststore.jks
      ZOOKEEPER_SSL_TRUSTSTORE_PASSWORD: "truststorepass"
```
#### kafka<br/>
```
      KAFKA_ZOOKEEPER_SSL_CLIENT_ENABLE: "true"
      KAFKA_ZOOKEEPER_CLIENT_CNXN_SOCKET: "org.apache.zookeeper.ClientCnxnSocketNetty"
      KAFKA_ZOOKEEPER_SSL_KEYSTORE_LOCATION: /usr/share/keystores/kafka-1.keystore.jks
      KAFKA_ZOOKEEPER_SSL_KEYSTORE_PASSWORD: "keystorepass"
      AFKA_ZOOKEEPER_SSL_TRUSTSTORE_LOCATION: /usr/share/keystores/kafka.server.truststore.jks
      KAFKA_ZOOKEEPER_SSL_TRUSTSTORE_PASSWORD: "truststorepass"
```
#### Certificates
Also note that for the ZooKeeper/Kafka mTLS, each server's private key has the same subject, with we set to `CN=mTLS_User,O=CONFLUENT,L=PaloAlto,ST=Ca,C=US` and a Subject Alternative Name containing the DNS name of the server. For example, the private key for `kafka-1` is:<br>
```
Alias name: kafka-1.zookeepertls
Creation date: 28 Sep. 2021
Entry type: PrivateKeyEntry
Certificate chain length: 2
Certificate[1]:
Owner: CN=mTLS_User, O=CONFLUENT, L=PaloAlto, ST=Ca, C=US
Issuer: C=US, L=MountainView, O=CONFLUENT, OU=example, CN=example.confluent.io
Serial number: b694ef184255b3aa
Valid from: Tue Sep 28 10:38:15 AEST 2021 until: Fri Feb 12 11:38:15 AEDT 2049
Certificate fingerprints:
	 SHA1: AB:10:3A:F3:B3:C1:80:F8:D6:FC:8E:F5:AF:E1:52:C6:5E:3F:B4:B6
	 SHA256: 3A:C7:ED:3B:B2:5E:28:3E:79:24:14:C9:E1:25:9B:5F:D7:77:2C:E1:B9:60:B1:75:02:D4:68:7A:65:30:3F:58
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 2048-bit RSA key
Version: 3

Extensions:

#1: ObjectId: 2.5.29.17 Criticality=false
SubjectAlternativeName [
  DNSName: kafka-1
  DNSName: kafka-1.zookeepertls
]

Certificate[2]:
Owner: C=US, L=MountainView, O=CONFLUENT, OU=example, CN=example.confluent.io
Issuer: C=US, L=MountainView, O=CONFLUENT, OU=example, CN=example.confluent.io
Serial number: a5283e7603726d8c
Valid from: Tue Sep 28 10:37:59 AEST 2021 until: Wed Sep 28 10:37:59 AEST 2022
Certificate fingerprints:
	 SHA1: A1:6C:20:AB:15:C9:6C:BA:33:EA:58:B3:52:EB:17:5F:90:32:07:3A
	 SHA256: 26:79:07:F6:65:6D:F1:72:C3:CE:C3:B1:7B:83:12:44:B5:9C:D7:43:77:4D:54:CB:1E:BB:AA:56:1B:6F:54:A5
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 2048-bit RSA key
Version: 1
```

### The important config items for Zookeeper Quorum
The important parts of the config for the Zookeeper Quorum TLS communication are:<br/>
#### zookeeper<br/>
```
      ZOOKEEPER_SERVER_CNXN_FACTORY: "org.apache.zookeeper.server.NettyServerCnxnFactory"
      ZOOKEEPER_SSL_QUORUM_KEYSTORE_LOCATION: /usr/share/keystores/zookeeper-2.quorum.keystore.jks
      ZOOKEEPER_SSL_QUORUM_KEYSTORE_PASSWORD: "keystorepass"
      ZOOKEEPER_SSL_QUORUM_TRUSTSTORE_LOCATION: /usr/share/keystores/zookeeper.quorum.truststore.jks
      ZOOKEEPER_SSL_QUORUM_TRUSTSTORE_PASSWORD: "truststorepass"
      ZOOKEEPER_SSL_QUORUM: "true"

```

#### Certificates
Also note that for the ZooKeeper quorum mTLS, each server's private key has the subject name set to the server's DNS name. For example, the private key for `zookeeper-1` is:<br>
```
Alias name: zookeeper-1.zookeepertls
Creation date: 28 Sep. 2021
Entry type: PrivateKeyEntry
Certificate chain length: 2
Certificate[1]:
Owner: CN=zookeeper-1.zookeepertls
Issuer: C=US, L=MountainView, O=CONFLUENT, OU=example, CN=example.confluent.io
Serial number: b694ef184255b3af
Valid from: Tue Sep 28 10:38:34 AEST 2021 until: Fri Feb 12 11:38:34 AEDT 2049
Certificate fingerprints:
	 SHA1: FE:2F:5A:36:E4:67:2D:7B:19:8C:7C:8B:4F:52:3D:7F:FC:88:57:19
	 SHA256: C6:DE:11:92:3D:71:D6:F1:CB:7C:97:20:CE:F0:D7:2B:59:D6:33:CA:BF:75:2E:6A:BC:C0:4C:BB:71:52:60:F4
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 2048-bit RSA key
Version: 3

Extensions:

#1: ObjectId: 2.5.29.17 Criticality=false
SubjectAlternativeName [
  DNSName: zookeeper-1
  DNSName: zookeeper-1.zookeepertls
]
```
