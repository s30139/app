#!/usr/bin/env bash
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 9999 -out rootCA.pem