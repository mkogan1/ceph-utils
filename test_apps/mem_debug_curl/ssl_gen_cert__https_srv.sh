#!/bin/bash -x

#openssl req -x509 -sha256 -nodes -days 365 -subj '/C=XX/ST=Here/L=There/O=MyOrg/CN=localhost' -newkey rsa:4096 -keyout server.key -out server.crt
openssl req \
  -newkey rsa:2048 \
  -x509 \
  -nodes \
  -keyout server.key \
  -new \
  -out server.crt \
  -subj /CN=localhost \
  -reqexts SAN \
  -extensions SAN \
  -config <(cat /etc/pki/tls/openssl.cnf \
      <(printf '[SAN]\nsubjectAltName=DNS:localhost')) \
      -sha256 \
      -days 3650

openssl s_server -key server.key -cert server.crt -www    # > /dev/null &    # bind to https://localhost:4433

