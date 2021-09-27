#!/bin/bash

rm -f certs/* keystores/*
./cert1-gen-ca-certs.sh
./cert2-gen-csrs.sh
./cert3-sign-csrs.sh
./cert4-import-signed-certs.sh
