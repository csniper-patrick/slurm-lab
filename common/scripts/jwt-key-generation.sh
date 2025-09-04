#!/bin/bash -x 

cp -rvL /json-web-key-generator /build
cd /build
mvn package
java -jar /build/target/json-web-key-generator-0.9-SNAPSHOT-jar-with-dependencies.jar --type RSA --size 2048 --algorithm RS256 --idGenerator sha1 --keySet --output /opt/jwks.json --pubKeyOutput /opt/jwks.pub.json
java -jar /build/target/json-web-key-generator-0.9-SNAPSHOT-jar-with-dependencies.jar --type oct --size 2048 --algorithm HS256 --idGenerator sha1 --keySet --output /opt/slurm.jwks