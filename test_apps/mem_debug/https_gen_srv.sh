#!/bin/bash -x

openssl req -x509 -sha256 -nodes -days 365 -subj '/C=XX/ST=Here/L=There/O=MyOrg/CN=localhost' -newkey rsa:1024 -keyout server.key -out server.crt
openssl s_server -key server.key -cert server.crt -www    # > /dev/null &    # bind to https://localhost:4433

