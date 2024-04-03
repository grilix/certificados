#!/bin/sh
# Necesita el CA
#   (ver scripts/create-ca.sh)

usage() {
  echo "Error: faltan parámetros." >&2
  echo "Usa: $0 <config.cnf>" >&2
  echo ""
  echo "     https://www.openssl.org/docs/man1.0.2/man1/req.html"

  exit 1
}

contains_extensions() {
  # Values:
  #   req
  #   x509
  TYPE="$1"
  # Values:
  #   path/file.csr
  #   path/file.pem
  FILE_PATH="$2"

  openssl "$TYPE" -noout -text -in "$FILE_PATH" | \
    grep "Subject Alternative Name" > /dev/null
}

[ "$#" != "1" ] && usage

set -e
CONFIG_FILE="$1"

CERT_ROOT="./certs"
CERT_PATH="$CERT_ROOT/$(echo $CONFIG_FILE | sed -E 's~.*/(.*)\.[[:alpha:]]+~\1~')"

[ ! -d "$CERT_PATH" ] && mkdir -p "$CERT_PATH"

if [ ! -f "$CERT_PATH/cert-key.pem" ]; then
  openssl genrsa -out "$CERT_PATH/cert-key.pem" 4069
fi

openssl req -new -sha256 \
  -config "$CONFIG_FILE" \
  -key "$CERT_PATH/cert-key.pem" \
  -out "$CERT_PATH/cert.csr"

if ! contains_extensions "req" "$CERT_PATH/cert.csr"; then
  echo "Error: El CSR generado es inválido." >&2
  exit 1
fi

openssl x509 -req -sha256 \
  -days 90 \
  -in "$CERT_PATH/cert.csr" \
  -CA "$CERT_ROOT/root-ca.pem" \
  -CAkey "$CERT_ROOT/root-ca-key.pem" \
  -out "$CERT_PATH/cert.pem" \
  -extensions req_ext \
  -extfile "$CONFIG_FILE" \
  -CAcreateserial

if ! contains_extensions "x509" "$CERT_PATH/cert.pem"; then
  echo "Error: El certificado generado es inválido." >&2
  exit 1
fi

cat "$CERT_PATH/cert.pem" "$CERT_ROOT/root-ca.pem" > "$CERT_PATH/chain.pem"
echo "Listo."
