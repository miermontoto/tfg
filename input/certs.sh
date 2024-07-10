#!/bin/bash
echo "Creando certificado de autoridad";
bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip;
unzip config/certs/ca.zip -d config/certs;

echo "Creando certificados";
echo -ne \
	"instances:\n"\
	"  - name: es01\n"\
	"    dns:\n"\
	"      - es01\n"\
	"      - localhost\n"\
	"    ip:\n"\
	"      - 127.0.0.1\n"\
	"  - name: kibana\n"\
	"    dns:\n"\
	"      - kibana\n"\
	"      - localhost\n"\
	"    ip:\n"\
	"      - 127.0.0.1\n"\
> config/certs/instances.yml;
bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/certs/instances.yml --ca-cert config/certs/ca/ca.crt --ca-key config/certs/ca/ca.key;
unzip config/certs/certs.zip -d config/certs;
