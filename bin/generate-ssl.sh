#!/bin/bash

delim="/"

ROOT_DIR=$(dirname $(dirname $(readlink -f "$0")))
SSL_DIR="$ROOT_DIR/ssl"
CONFIG_DIR="$ROOT_DIR/config"

case "$(uname -s)" in
   Darwin)
     echo 'Mac OS X'
     ;;
   Linux)
     echo 'Linux'
     ;;
   CYGWIN*|MINGW*|MSYS*)
     echo 'MS Windows'
     delim="//"
     ;;
   *)
     echo 'Unknown OS'
     exit -1
     ;;
esac

mkdir -p $SSL_DIR
cp "$CONFIG_DIR/openssl.cnf" "$SSL_DIR/openssl.cnf"
cd $SSL_DIR

# CA Certificate
openssl genrsa -out ca-key.pem 2048
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj $delim"CN=kube-ca"

# API Server Keypair
openssl genrsa -out apiserver-key.pem 2048
openssl req -new -key apiserver-key.pem -out apiserver.csr -subj $delim"CN=kube-apiserver" -config openssl.cnf
openssl x509 -req -in apiserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out apiserver.pem -days 1825 -extensions v3_req -extfile openssl.cnf

# Worker Keypair
openssl genrsa -out worker-key.pem 2048
openssl req -new -key worker-key.pem -out worker.csr -subj $delim"CN=kube-worker"
openssl x509 -req -in worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out worker.pem -days 1825

# Cluster Admin Keypair
openssl genrsa -out admin-key.pem 2048
openssl req -new -key admin-key.pem -out admin.csr -subj $delim"CN=kube-admin"
openssl x509 -req -in admin.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out admin.pem -days 1825

rm "$SSL_DIR/openssl.cnf"
