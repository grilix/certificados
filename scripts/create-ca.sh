#!/bin/sh

set -ex

usage() {
  echo "Error: faltan parámetros." >&2
  echo "Usa: $0 <config.cnf>" >&2
  echo ""
  echo "     https://www.openssl.org/docs/man1.0.2/man1/req.html"

  exit 1
}

[ "$#" != "1" ] && usage

CERT_ROOT="./certs"
CONFIG_FILE="$1"

if [ ! -f "$CERT_ROOT/root-ca-key.pem" ]; then
  openssl genrsa -aes256 -out "$CERT_ROOT/root-ca-key.pem" 4096
fi

openssl req -new \
  -x509 -sha256 -days 5500 \
  -config "$CONFIG_FILE" \
  -key "$CERT_ROOT/root-ca-key.pem" \
  -out "$CERT_ROOT/root-ca.pem"

openssl pkcs12 \
  -export \
  -in "$CERT_ROOT/root-ca.pem" \
  -inkey "$CERT_ROOT/root-ca-key.pem" \
  -out "$CERT_ROOT/root-ca-combined.p12"
